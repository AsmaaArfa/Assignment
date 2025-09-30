from pydantic import Field, field_validator, BaseModel
import pandas as pd

class employee(BaseModel):
    employeeId: int = Field(...)
    firstName: str = Field(...)
    lastName: str |None = Field(None)
    employmentDate: str | None = Field(None)
    yearlySalary: float |None =  Field(None)

