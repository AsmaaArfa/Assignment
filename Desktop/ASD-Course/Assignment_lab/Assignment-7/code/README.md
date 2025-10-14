# SQLAlchemy PostgreSQL CRUD Example

This project provides SQLAlchemy models and CRUD helpers for Patients, Dentists, Surgeries, Addresses, Appointments, Users and Roles, with a PostgreSQL backend.

Setup

1. Create a Python 3.10+ virtual environment and activate it.
2. Copy `.env.example` to `.env` and set `DATABASE_URL` (e.g. `postgresql+psycopg2://user:pass@localhost:5432/dbname`).
3. Install dependencies:

```bash
pip install -r requirements.txt
```

Run example:

```bash
python main.py
```

Files

- `database.py` - SQLAlchemy engine, session and Base
- `models.py` - ORM models and relationships
- `crud.py` - CRUD helper functions
- `main.py` - Example usage that creates tables and demonstrates CRUD
