from pydantic import BaseModel
from typing import Optional

class ItemBase(BaseModel):
    name: str
    quantity: Optional[int] = 1
    expiry_date: Optional[str]

class ItemCreate(ItemBase):
    pass

class Item(ItemBase):
    id: int
    class Config:
        orm_mode = True