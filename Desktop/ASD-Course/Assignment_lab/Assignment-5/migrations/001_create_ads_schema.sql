-- Migration: 001_create_ads_schema.sql
-- Purpose: Create ADS schema for dentists, patients, appointments, surgeries, bills,
-- triggers to enforce business rules, and concurrency-safe weekly limit (advisory locks).
-- UP and DOWN sections are provided. Run up section to apply, down to rollback.

-- ===================== UP (apply) =====================

-- Enable uuid extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Types
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE user_role AS ENUM ('office_manager','dentist','patient');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'appointment_status') THEN
        CREATE TYPE appointment_status AS ENUM ('booked','confirmed','cancelled','completed','no_show');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'request_source') THEN
        CREATE TYPE request_source AS ENUM ('phone','online');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'request_status') THEN
        CREATE TYPE request_status AS ENUM ('pending','converted','rejected');
    END IF;
END $$;

-- Users
CREATE TABLE IF NOT EXISTS app_user (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role user_role NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Dentists
CREATE TABLE IF NOT EXISTS dentist (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    phone TEXT,
    email TEXT UNIQUE,
    specialization TEXT,
    user_id UUID REFERENCES app_user(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Patients
CREATE TABLE IF NOT EXISTS patient (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    mailing_address TEXT,
    date_of_birth DATE,
    user_id UUID REFERENCES app_user(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Surgeries
CREATE TABLE IF NOT EXISTS surgery (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    phone TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Appointments
CREATE TABLE IF NOT EXISTS appointment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dentist_id UUID NOT NULL REFERENCES dentist(id) ON DELETE RESTRICT,
    patient_id UUID NOT NULL REFERENCES patient(id) ON DELETE RESTRICT,
    surgery_id UUID NOT NULL REFERENCES surgery(id) ON DELETE RESTRICT,
    start_at TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_minutes INTEGER NOT NULL DEFAULT 30,
    status appointment_status NOT NULL DEFAULT 'booked',
    confirmed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    CHECK (duration_minutes > 0)
);

-- Appointment requests
CREATE TABLE IF NOT EXISTS appointment_request (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patient(id) ON DELETE CASCADE,
    dentist_id UUID REFERENCES dentist(id) ON DELETE SET NULL,
    source request_source NOT NULL,
    preferred_time_windows TEXT,
    notes TEXT,
    status request_status NOT NULL DEFAULT 'pending',
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Bills
CREATE TABLE IF NOT EXISTS bill (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patient(id) ON DELETE CASCADE,
    appointment_id UUID REFERENCES appointment(id) ON DELETE SET NULL,
    amount NUMERIC(10,2) NOT NULL CHECK (amount >= 0),
    paid BOOLEAN NOT NULL DEFAULT FALSE,
    issued_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    paid_at TIMESTAMP WITH TIME ZONE
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_appointment_dentist_start ON appointment (dentist_id, start_at);
CREATE INDEX IF NOT EXISTS idx_appointment_patient_start ON appointment (patient_id, start_at);
CREATE INDEX IF NOT EXISTS idx_appointment_surgery_start ON appointment (surgery_id, start_at);
CREATE INDEX IF NOT EXISTS idx_bill_patient_paid ON bill (patient_id, paid);
CREATE INDEX IF NOT EXISTS idx_patient_email ON patient (lower(email));
CREATE INDEX IF NOT EXISTS idx_dentist_email ON dentist (lower(email));

-- generated week_start column
ALTER TABLE appointment
    ADD COLUMN IF NOT EXISTS week_start date GENERATED ALWAYS AS (date_trunc('week', start_at)::date) STORED;

CREATE INDEX IF NOT EXISTS idx_appointment_dentist_week ON appointment (dentist_id, week_start);

-- prevent exact duplicate start time for same dentist
ALTER TABLE appointment
    ADD CONSTRAINT IF NOT EXISTS uniq_dentist_start UNIQUE (dentist_id, start_at);

-- Comments
COMMENT ON TABLE app_user IS 'Authentication users (office managers, dentists, patients)';
COMMENT ON TABLE dentist IS 'Dentist profiles';
COMMENT ON TABLE patient IS 'Patient profiles';
COMMENT ON TABLE surgery IS 'Surgery locations';
COMMENT ON TABLE appointment IS 'Scheduled appointments linking dentist, patient and surgery';
COMMENT ON TABLE appointment_request IS 'Incoming appointment requests (phone or online)';
COMMENT ON TABLE bill IS 'Billing records for services rendered';

-- ======= Triggers and functions =======

-- Helper: key for advisory lock
CREATE OR REPLACE FUNCTION dentist_week_lock_key(_dentist_id UUID, _week_start DATE)
RETURNS BIGINT
LANGUAGE SQL
AS $$
    SELECT ( ('x' || substr(md5(_dentist_id::text || '|' || _week_start::text),1,16))::bit(64)::bigint );
$$;

-- enforce unpaid bills prevention
CREATE OR REPLACE FUNCTION prevent_request_if_unpaid_bills()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    unpaid_count int;
BEGIN
    SELECT COUNT(*) INTO unpaid_count
    FROM bill
    WHERE patient_id = NEW.patient_id
      AND paid = FALSE;

    IF unpaid_count > 0 THEN
        RAISE EXCEPTION 'Patient % has % unpaid bill(s); cannot create new appointment request or appointment',
            NEW.patient_id, unpaid_count;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_request_if_unpaid_bills ON appointment_request;
CREATE TRIGGER trg_prevent_request_if_unpaid_bills
BEFORE INSERT ON appointment_request
FOR EACH ROW
EXECUTE FUNCTION prevent_request_if_unpaid_bills();

-- optional: also prevent direct appointment insertion if unpaid bills
DROP TRIGGER IF EXISTS trg_prevent_appointment_if_unpaid_bills ON appointment;
CREATE TRIGGER trg_prevent_appointment_if_unpaid_bills
BEFORE INSERT ON appointment
FOR EACH ROW
EXECUTE FUNCTION prevent_request_if_unpaid_bills();

-- concurrency-safe weekly limit using advisory lock
CREATE OR REPLACE FUNCTION enforce_dentist_weekly_limit_safe()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    target_week date;
    existing_count int;
    lock_key bigint;
BEGIN
    target_week := date_trunc('week', NEW.start_at)::date;
    lock_key := dentist_week_lock_key(NEW.dentist_id, target_week);

    -- Acquire transaction-level advisory lock
    PERFORM pg_advisory_xact_lock(lock_key);

    SELECT COUNT(*) INTO existing_count
    FROM appointment
    WHERE dentist_id = NEW.dentist_id
      AND date_trunc('week', start_at)::date = target_week
      AND status IN ('booked', 'confirmed');

    IF TG_OP = 'UPDATE' AND OLD.dentist_id = NEW.dentist_id AND date_trunc('week', OLD.start_at)::date = target_week THEN
        existing_count := existing_count - 1;
    END IF;

    IF existing_count >= 5 THEN
        RAISE EXCEPTION 'Dentist % already has % appointments in week starting %; cannot exceed 5',
            NEW.dentist_id, existing_count, target_week;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_dentist_weekly_limit ON appointment;
CREATE TRIGGER trg_dentist_weekly_limit
BEFORE INSERT OR UPDATE OF start_at, dentist_id, status ON appointment
FOR EACH ROW
EXECUTE FUNCTION enforce_dentist_weekly_limit_safe();

-- ======= Optional view for convenience =======
CREATE OR REPLACE VIEW dentist_schedule AS
SELECT
    a.id as appointment_id,
    a.dentist_id,
    d.first_name as dentist_first,
    d.last_name as dentist_last,
    a.patient_id,
    p.first_name as patient_first,
    p.last_name as patient_last,
    a.surgery_id,
    s.name as surgery_name,
    a.start_at,
    a.duration_minutes,
    a.status,
    a.confirmed
FROM appointment a
JOIN dentist d ON d.id = a.dentist_id
JOIN patient p ON p.id = a.patient_id
JOIN surgery s ON s.id = a.surgery_id;

-- ===================== DOWN (rollback) =====================
-- Note: Running the DOWN will DROP tables and functions. Use with care.

-- To rollback, run the statements below (they are provided as comments here).

-- DROP VIEW IF EXISTS dentist_schedule;
-- DROP TRIGGER IF EXISTS trg_dentist_weekly_limit ON appointment;
-- DROP FUNCTION IF EXISTS enforce_dentist_weekly_limit_safe();
-- DROP TRIGGER IF EXISTS trg_prevent_appointment_if_unpaid_bills ON appointment;
-- DROP TRIGGER IF EXISTS trg_prevent_request_if_unpaid_bills ON appointment_request;
-- DROP FUNCTION IF EXISTS prevent_request_if_unpaid_bills();
-- DROP FUNCTION IF EXISTS dentist_week_lock_key(UUID, DATE);
-- DROP INDEX IF EXISTS idx_appointment_dentist_week;
-- ALTER TABLE appointment DROP COLUMN IF EXISTS week_start;
-- DROP INDEX IF EXISTS idx_appointment_dentist_start;
-- DROP INDEX IF EXISTS idx_appointment_patient_start;
-- DROP INDEX IF EXISTS idx_appointment_surgery_start;
-- DROP INDEX IF EXISTS idx_bill_patient_paid;
-- DROP INDEX IF EXISTS idx_patient_email;
-- DROP INDEX IF EXISTS idx_dentist_email;
-- DROP TABLE IF EXISTS bill;
-- DROP TABLE IF EXISTS appointment_request;
-- DROP TABLE IF EXISTS appointment;
-- DROP TABLE IF EXISTS surgery;
-- DROP TABLE IF EXISTS patient;
-- DROP TABLE IF EXISTS dentist;
-- DROP TABLE IF EXISTS app_user;
-- DROP TYPE IF EXISTS request_status;
-- DROP TYPE IF EXISTS request_source;
-- DROP TYPE IF EXISTS appointment_status;
-- DROP TYPE IF EXISTS user_role;

-- End of migration
