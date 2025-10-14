from fastapi import FastAPI, HTTPException, Depends, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Optional, List
from .database import get_session
from . import models, crud
from sqlalchemy.orm import Session

app = FastAPI(title='ADSWeb API', openapi_prefix='/adsweb/api/v1')

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class AddressOut(BaseModel):
    id: int
    street: str
    city: str
    state: Optional[str]
    postal_code: Optional[str]
    country: Optional[str]

    class Config:
        orm_mode = True


class PatientIn(BaseModel):
    first_name: str = Field(...)
    last_name: str = Field(...)
    email: Optional[str]
    phone: Optional[str]
    address_id: Optional[int]


class PatientOut(BaseModel):
    id: int
    first_name: str
    last_name: str
    email: Optional[str]
    phone: Optional[str]
    address: Optional[AddressOut]

    class Config:
        orm_mode = True


def get_db():
    db = get_session()
    try:
        yield db
    finally:
        db.close()


@app.get('/patients', response_model=List[PatientOut])
def list_patients(db: Session = Depends(get_db)):
    patients = db.query(models.Patient).join(models.Address, isouter=True).order_by(models.Patient.last_name.asc()).all()
    return patients


@app.get('/patients/{patient_id}', response_model=PatientOut)
def get_patient(patient_id: int, db: Session = Depends(get_db)):
    p = crud.get_patient(db, patient_id)
    if not p:
        raise HTTPException(status_code=404, detail='Patient not found')
    return p


@app.post('/patients', response_model=PatientOut, status_code=201)
def create_patient(patient: PatientIn, db: Session = Depends(get_db)):
    p = crud.create_patient(db, **patient.dict())
    return p


@app.put('/patient/{patient_id}', response_model=PatientOut)
def update_patient(patient_id: int, patient: PatientIn, db: Session = Depends(get_db)):
    existing = crud.get_patient(db, patient_id)
    if not existing:
        raise HTTPException(status_code=404, detail='Patient not found')
    updated = crud.update_patient(db, patient_id, **patient.dict())
    return updated


@app.delete('/patient/{patient_id}', status_code=204)
def delete_patient(patient_id: int, db: Session = Depends(get_db)):
    ok = crud.delete_patient(db, patient_id)
    if not ok:
        raise HTTPException(status_code=404, detail='Patient not found')
    return None


@app.get('/patient/search/{search_string}', response_model=List[PatientOut])
def search_patients(search_string: str, db: Session = Depends(get_db)):
    s = f"%{search_string}%"
    results = db.query(models.Patient).filter(
        (models.Patient.first_name.ilike(s)) |
        (models.Patient.last_name.ilike(s)) |
        (models.Patient.email.ilike(s)) |
        (models.Patient.phone.ilike(s))
    ).order_by(models.Patient.last_name.asc()).all()
    return results


@app.get('/addresses', response_model=List[AddressOut])
def list_addresses(db: Session = Depends(get_db)):
    addrs = db.query(models.Address).order_by(models.Address.city.asc()).all()
    return addrs
