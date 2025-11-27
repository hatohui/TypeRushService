from contextlib import asynccontextmanager
from fastapi import FastAPI
from pydantic import Field
from pydantic_settings import BaseSettings
from controllers.todo_controller import router as todoRouter
from controllers.health_controller import router as healthRouter

# Settings for the FastAPI application
class Settings(BaseSettings):
    app_name: str = "Text-Service-API"
    debug: bool = True
    PORT: int = Field(default=8000, alias="PORT")

    class Config:
      env_file = ".env"
      env_file_encoding = "utf-8"

settings = Settings()

#lifespan events
@asynccontextmanager
async def lifespan(_: FastAPI):
  print(f"Server started in port {settings.PORT}")
  yield


#main application setup
app = FastAPI(lifespan=lifespan, title="TypeRush Text Service")
app.include_router(todoRouter, prefix="/api")
app.include_router(healthRouter)
