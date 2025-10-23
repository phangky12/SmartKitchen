from fastapi import FastAPI
from .database import engine, Base
from .routers import inventory

Base.metadata.create_all(bind=engine)
app = FastAPI(title='Smart Kitchen Assistant API')

app.include_router(inventory.router, prefix='/inventory', tags=['inventory'])

@app.get('/')
def root():
    return {'message': 'Smart Kitchen Assistant API'}