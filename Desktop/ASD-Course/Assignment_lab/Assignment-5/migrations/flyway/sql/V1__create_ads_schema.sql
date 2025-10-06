-- Flyway migration V1: create_ads_schema (UP)
-- Applies: create types, tables, indexes, triggers and functions for ADS system

-- Note: This file is intended for Flyway (place in sql/ folder) and will be run as-is.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Types
CREATE TYPE IF NOT EXISTS user_role AS ENUM ('office_manager','dentist','patient');
CREATE TYPE IF NOT EXISTS appointment_status AS ENUM ('booked','confirmed','cancelled','completed','no_show');
CREATE TYPE IF NOT EXISTS request_source AS ENUM ('phone','online');
CREATE TYPE IF NOT EXISTS request_status AS ENUM ('pending','converted','rejected');

-- Tables
CREATE TABLE IF NOT EXISTS app_user (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role user_role NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

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

CREATE TABLE IF NOT EXISTS surgery (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    phone TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

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

CREATE TABLE IF NOT EXISTS bill (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patient(id) ON DELETE CASCADE,
    appointment_id UUID REFERENCES appointment(id) ON DELETE SET NULL,
    amount NUMERIC(10,2) NOT NULL CHECK (amount >= 0),
    paid BOOLEAN NOT NULL DEFAULT FALSE,
    issued_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    paid_at TIMESTAMP WITH TIME ZONE
);

-- Indexes and helpers
CREATE INDEX IF NOT EXISTS idx_appointment_dentist_start ON appointment (dentist_id, start_at);
CREATE INDEX IF NOT EXISTS idx_appointment_patient_start ON appointment (patient_id, start_at);
CREATE INDEX IF NOT EXISTS idx_appointment_surgery_start ON appointment (surgery_id, start_at);
CREATE INDEX IF NOT EXISTS idx_bill_patient_paid ON bill (patient_id, paid);
CREATE INDEX IF NOT EXISTS idx_patient_email ON patient (lower(email));
CREATE INDEX IF NOT EXISTS idx_dentist_email ON dentist (lower(email));

ALTER TABLE appointment
    ADD COLUMN IF NOT EXISTS week_start date GENERATED ALWAYS AS (date_trunc('week', start_at)::date) STORED;

CREATE INDEX IF NOT EXISTS idx_appointment_dentist_week ON appointment (dentist_id, week_start);

ALTER TABLE appointment
    ADD CONSTRAINT IF NOT EXISTS uniq_dentist_start UNIQUE (dentist_id, start_at);

-- Functions and triggers
CREATE OR REPLACE FUNCTION dentist_week_lock_key(_dentist_id UUID, _week_start DATE)
RETURNS BIGINT
LANGUAGE SQL
AS $$
    SELECT ( ('x' || substr(md5(_dentist_id::text || '|' || _week_start::text),1,16))::bit(64)::bigint );
$$;

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

CREATE TRIGGER trg_prevent_request_if_unpaid_bills
BEFORE INSERT ON appointment_request
FOR EACH ROW
EXECUTE FUNCTION prevent_request_if_unpaid_bills();

CREATE TRIGGER trg_prevent_appointment_if_unpaid_bills
BEFORE INSERT ON appointment
FOR EACH ROW
EXECUTE FUNCTION prevent_request_if_unpaid_bills();

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

CREATE TRIGGER trg_dentist_weekly_limit
BEFORE INSERT OR UPDATE OF start_at, dentist_id, status ON appointment
FOR EACH ROW
EXECUTE FUNCTION enforce_dentist_weekly_limit_safe();

-- Optional view
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
