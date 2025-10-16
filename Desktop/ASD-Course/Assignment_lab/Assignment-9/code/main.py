from .database import engine, Base, get_session
from . import models, crud
from . import seed
from datetime import datetime, timedelta


def create_schema():
    Base.metadata.create_all(bind=engine)


def demo():
    db = get_session()
    try:
        # Create address
        addr = crud.create_address(db, street='123 Main St', city='Anytown', state='CA', postal_code='12345', country='USA')

        # Create patient and dentist
        p = crud.create_patient(db, first_name='John', last_name='Doe', email='john@example.com', phone='555-1234', address_id=addr.id)
        d = crud.create_dentist(db, first_name='Dr', last_name='Smile', specialty='Orthodontics', email='drsmile@example.com', phone='555-5678', address_id=addr.id)

        # Create a surgery
        s = crud.create_surgery(db, title='Tooth Extraction', description='Simple extraction')

        # Create appointment
        appt = crud.create_appointment(db, patient_id=p.id, dentist_id=d.id, surgery_id=s.id, scheduled_at=(datetime.utcnow() + timedelta(days=3)), notes='First visit')

        # Create roles and user
        admin_role = crud.create_role(db, name='admin', description='Administrator')
        user = crud.create_user(db, username='asmith', email='asmith@example.com', full_name='A S Smith', hashed_password='notreallyhashed', roles=[admin_role])

        print('Created:', addr, p, d, s, appt, admin_role, user)

        # List patients
        patients = crud.list_patients(db)
        print('Patients:', patients)

        # Update patient
        updated = crud.update_patient(db, p.id, phone='555-0000')
        print('Updated patient:', updated)

        # Delete appointment
        ok = crud.delete_appointment(db, appt.id)
        print('Deleted appointment?', ok)

    finally:
        db.close()


if __name__ == '__main__':
    create_schema()
    # seed roles/admin if configured in .env
    try:
        seed.seed_initial_data()
    except Exception:
        pass
    demo()
