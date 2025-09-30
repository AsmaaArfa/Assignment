from pydantic import BaseModel, Field, field_validator
import pandas as pd

class PensionPlan(BaseModel):
    P_Ref_Num: str 
    enrollmentDate: str |None = Field(None)
    monthlyContribution: int = Field(...)