from sqlalchemy import Column, Integer, String, Date
from .database import Base

class Item(Base):
    __tablename__ = 'items'
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    quantity = Column(Integer, default=1)
    expiry_date = Column(String) # keep simple string for scaffold