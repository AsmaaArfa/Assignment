# ADS (Appointment & Dental Surgery) DB migrations and tests

This folder contains SQL migrations, triggers, and tests for a simple Appointment/Dental Surgery system.

Contents
- `migrations/flyway/sql/V1__create_ads_schema.sql` - Flyway UP migration creating tables, types, functions and triggers.
- `migrations/flyway/sql/U1__drop_ads_schema.sql` - Flyway undo migration (destructive).
- `migrations/001_create_ads_schema.sql` - Single-file migration (UP + commented DOWN) used during development.
- `tests/run_tests.sql` - SQL script that runs test sequences (inserts, checks, expected failures) against the DB.
- `tests/run_tests.sh` - Small shell driver to run the tests using `psql`.

Prerequisites
- PostgreSQL 12+ with `uuid-ossp` extension available (or change to `gen_random_uuid()` if using pgcrypto).
- `psql` command-line client installed.

Quick start (local development)

1) Create a test database and user (example):

```sh
createdb ads_test_db
# or use your own DB connection settings
```

2) Apply migration (Flyway) or run SQL directly with psql:

```sh
psql -d ads_test_db -f migrations/flyway/sql/V1__create_ads_schema.sql
```

3) Run tests (psql script):

```sh
# Make the test script executable
chmod +x tests/run_tests.sh
# Run it (it will connect using $PGDATABASE, or you can edit the script to supply connection params)
./tests/run_tests.sh ads_test_db
```

Notes
- The tests intentionally truncate tables and insert deterministic UUIDs for readability. Do NOT run on production data.
- The undo migration `U1__drop_ads_schema.sql` is destructive. Use only in development.

Support
If you want me to adapt these migrations for a particular migration framework (e.g. Alembic, Rails, Django, Flyway config), tell me which tool and I will prepare it.