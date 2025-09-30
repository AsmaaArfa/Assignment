import pytest
from edu.miu.cs.cs489appsd.lab1.productmgmtapp.model.product import Product


def test_product_happy_path():
    p = Product(id="1", name="Widget", price=9.99, quantity=5)
    assert p.id == "1"
    assert p.name == "Widget"
    assert p.price == 9.99
    assert p.quantity == 5
    d = p.to_dict()
    assert d["name"] == "Widget"


def test_product_empty_name_raises():
    with pytest.raises(ValueError):
        Product(id="2", name="   ", price=1.0, quantity=1)


def test_product_negative_price_raises():
    with pytest.raises(ValueError):
        Product(id="3", name="Gadget", price=-1.0, quantity=1)
