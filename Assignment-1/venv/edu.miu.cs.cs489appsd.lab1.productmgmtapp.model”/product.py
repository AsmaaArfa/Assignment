import pandas as pd
from typing import Optional, Dict, List, Any
from pydantic import BaseModel, Field, field_validator
from datetime import date, datetime

class product(BaseModel):
    productID : int = Field(...)
    name: str | None = Field(None)
    DateSupplied: date | None = Field(None)
    QuantityInStock: int | None = Field(default=0)
    UnitPrice: float = Field(...)

    @property
    def price(self) -> float:
        return self.price

    @property
    def productId (self) -> int:
        return self.productID
    
    @property
    def name(self) -> str:
        return self.name
    
    @property
    def DateSupplied(self) -> date:
        return self.DateSupplied
    
    @property
    def QuantityInStock(self) -> int:
        return self.QuantityInStock
    
    @price.setter
    def price(self, value:float):
        self._price = value
    
    @name.setter
    def name(self, value: str):
        self._name = value

    @DateSupplied.setter
    def DateSupplied (self, value: date):
        self._DateSupplied = value
    
    @QuantityInStock.setter
    def QuantityInStock(self , value: int):
        self._QuantityInStock = value



