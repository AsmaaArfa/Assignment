-- Flyway undo migration U1: drop_ads_schema (DOWN)
-- WARNING: This will DROP tables, types, functions and views. Use only in safe/dev environments.

-- Drop view
DROP VIEW IF EXISTS dentist_schedule;

-- Drop triggers and functions
DROP TRIGGER IF EXISTS trg_dentist_weekly_limit ON appointment;
DROP FUNCTION IF EXISTS enforce_dentist_weekly_limit_safe();

DROP TRIGGER IF EXISTS trg_prevent_appointment_if_unpaid_bills ON appointment;
DROP TRIGGER IF EXISTS trg_prevent_request_if_unpaid_bills ON appointment_request;
DROP FUNCTION IF EXISTS prevent_request_if_unpaid_bills();
DROP FUNCTION IF EXISTS dentist_week_lock_key(UUID, DATE);

-- Drop indexes and generated column
DROP INDEX IF EXISTS idx_appointment_dentist_week;
ALTER TABLE appointment DROP COLUMN IF EXISTS week_start;

DROP INDEX IF EXISTS idx_appointment_dentist_start;
DROP INDEX IF EXISTS idx_appointment_patient_start;
DROP INDEX IF EXISTS idx_appointment_surgery_start;
DROP INDEX IF EXISTS idx_bill_patient_paid;
DROP INDEX IF EXISTS idx_patient_email;
DROP INDEX IF EXISTS idx_dentist_email;

-- Drop tables (order matters for FK constraints)
DROP TABLE IF EXISTS bill;
DROP TABLE IF EXISTS appointment_request;
DROP TABLE IF EXISTS appointment;
DROP TABLE IF EXISTS surgery;
DROP TABLE IF EXISTS patient;
DROP TABLE IF EXISTS dentist;
DROP TABLE IF EXISTS app_user;

-- Drop types
DROP TYPE IF EXISTS request_status;
DROP TYPE IF EXISTS request_source;
DROP TYPE IF EXISTS appointment_status;
DROP TYPE IF EXISTS user_role;

-- Note: uuid-ossp extension left in place (shared system extension). Remove with caution.
