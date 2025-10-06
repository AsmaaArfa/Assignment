-- Drop if exists (for re-run safety)
DROP TABLE IF EXISTS core.bill, core.appointment, core.surgery, core.patient, core.dentist, core.app_user CASCADE;

-- 1. App User Table
CREATE TABLE core.app_user (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role VARCHAR(20) CHECK (role IN ('ADMIN', 'DENTIST', 'PATIENT', 'MANAGER')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Dentist Table
CREATE TABLE core.dentist (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100) UNIQUE NOT NULL,
    specialization VARCHAR(100),
    user_id UUID REFERENCES core.app_user(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Patient Table
CREATE TABLE core.patient (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100) UNIQUE NOT NULL,
    mailing_address TEXT,
    date_of_birth DATE,
    user_id UUID REFERENCES core.app_user(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Surgery Table
CREATE TABLE core.surgery (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    phone VARCHAR(20)
);

-- 5. Appointment Table
CREATE TABLE core.appointment (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dentist_id UUID NOT NULL REFERENCES core.dentist(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES core.patient(id) ON DELETE CASCADE,
    surgery_id UUID REFERENCES core.surgery(id) ON DELETE SET NULL,
    start_at TIMESTAMP NOT NULL,
    duration_minutes INT CHECK (duration_minutes > 0),
    status VARCHAR(20) CHECK (status IN ('SCHEDULED', 'COMPLETED', 'CANCELLED')),
    confirmed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    week_start DATE GENERATED ALWAYS AS (date_trunc('week', start_at)::DATE) STORED
);

-- 6. Bill Table
CREATE TABLE core.bill (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES core.patient(id) ON DELETE CASCADE,
    appointment_id UUID REFERENCES core.appointment(id) ON DELETE SET NULL,
    amount NUMERIC(10,2) CHECK (amount >= 0),
    paid BOOLEAN DEFAULT FALSE,
    issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    paid_at TIMESTAMP
);

-- Data Insertion
-- App Users
INSERT INTO core.app_user (id, email, password_hash, role) VALUES
    ('11111111-1111-1111-1111-111111111111', 'dr.john@example.com', 'hash1', 'DENTIST'),
    ('22222222-2222-2222-2222-222222222222', 'dr.sara@example.com', 'hash2', 'DENTIST'),
    ('33333333-3333-3333-3333-333333333333', 'patient.ali@example.com', 'hash3', 'PATIENT'),
    ('44444444-4444-4444-4444-444444444444', 'patient.mary@example.com', 'hash4', 'PATIENT');

-- Dentists
INSERT INTO core.dentist (id, first_name, last_name, phone, email, specialization, user_id) VALUES
    ('aaaa1111-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'John', 'Doe', '555-1234', 'dr.john@example.com', 'Orthodontist', '11111111-1111-1111-1111-111111111111'),
    ('bbbb2222-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Sara', 'Smith', '555-5678', 'dr.sara@example.com', 'Pediatric Dentist', '22222222-2222-2222-2222-222222222222');

-- Patients
INSERT INTO core.patient (id, first_name, last_name, phone, email, mailing_address, date_of_birth, user_id) VALUES
    ('cccc3333-cccc-cccc-cccc-cccccccccccc', 'Ali', 'Hassan', '555-7777', 'patient.ali@example.com', '123 Main St', '1995-03-21', '33333333-3333-3333-3333-333333333333'),
    ('dddd4444-dddd-dddd-dddd-dddddddddddd', 'Mary', 'Jones', '555-8888', 'patient.mary@example.com', '456 Elm Ave', '1988-09-10', '44444444-4444-4444-4444-444444444444');

-- Surgeries
INSERT INTO core.surgery (id, name, address, phone) VALUES
    ('eeee5555-eeee-eeee-eeee-eeeeeeeeeeee', 'Downtown Clinic', '12 King St', '555-9999'),
    ('ffff6666-ffff-ffff-ffff-ffffffffffff', 'Uptown Dental', '34 Queen St', '555-1010');

-- Appointments
INSERT INTO core.appointment (id, dentist_id, patient_id, surgery_id, start_at, duration_minutes, status, confirmed)
VALUES
    ('aaaa9999-aaaa-9999-aaaa-aaaaaaaa9999', 'aaaa1111-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'cccc3333-cccc-cccc-cccc-cccccccccccc', 'eeee5555-eeee-eeee-eeee-eeeeeeeeeeee', '2025-10-06 10:00', 30, 'SCHEDULED', TRUE),
    ('bbbb8888-bbbb-8888-bbbb-bbbbbbbb8888', 'bbbb2222-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'dddd4444-dddd-dddd-dddd-dddddddddddd', 'ffff6666-ffff-ffff-ffff-ffffffffffff', '2025-10-06 11:00', 45, 'SCHEDULED', TRUE);

-- Bills
INSERT INTO core.bill (patient_id, appointment_id, amount, paid, issued_at) VALUES
    ('cccc3333-cccc-cccc-cccc-cccccccccccc', 'aaaa9999-aaaa-9999-aaaa-aaaaaaaa9999', 150.00, TRUE, NOW()),
    ('dddd4444-dddd-dddd-dddd-dddddddddddd', 'bbbb8888-bbbb-8888-bbbb-bbbbbbbb8888', 200.00, FALSE, NOW());
