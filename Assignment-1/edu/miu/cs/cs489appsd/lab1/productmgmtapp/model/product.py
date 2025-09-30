"""
Product model for the product management app.

Fields:
- id: optional str
- name: str (non-empty)
- price: float (>= 0)
- quantity: int (>= 0)

Provides basic validation and JSON (de)serialization.
"""
from __future__ import annotations

from dataclasses import dataclass, field, asdict
from typing import Optional, Dict, Any


@dataclass
class Product:
    id: Optional[str] = field(default=None)
    name: str = field(default="")
    price: float = field(default=0.0)
    quantity: int = field(default=0)

    def __post_init__(self) -> None:
        if not isinstance(self.name, str) or not self.name.strip():
            raise ValueError("name must be a non-empty string")
        if not isinstance(self.price, (int, float)) or self.price < 0:
            raise ValueError("price must be a non-negative number")
        if not isinstance(self.quantity, int) or self.quantity < 0:
            raise ValueError("quantity must be a non-negative integer")

    def to_dict(self) -> Dict[str, Any]:
        """Return a dictionary representation suitable for JSON serialization."""
        return asdict(self)

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "Product":
        """Create Product from a dict.

        This will perform the same validation as the constructor.
        """
        return cls(
            id=data.get("id"),
            name=data.get("name", ""),
            price=float(data.get("price", 0.0)),
            quantity=int(data.get("quantity", 0)),
        )
