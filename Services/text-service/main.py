from contextlib import asynccontextmanager

from fastapi import FastAPI
from mangum import Mangum
from pydantic import Field
from pydantic_settings import BaseSettings

from controllers.text_controller import router as textRouter
from models.TextService import TextService


# Settings for the FastAPI application
class Settings(BaseSettings):
    app_name: str = "Typing Practice Text Service API"
    debug: bool = True
    PORT: int = Field(default=8000, alias="PORT")
    AWS_REGION: str = Field(default="ap-southeast-2", alias="AWS_REGION")
    DYNAMODB_TABLE_NAME: str = Field(default="wordsntexts", alias="DYNAMODB_TABLE_NAME")
    BEDROCK_AGENT_ID: str | None = Field(default=None, alias="BEDROCK_AGENT_ID")
    BEDROCK_AGENT_ALIAS: str | None = Field(default=None, alias="BEDROCK_AGENT_ALIAS")

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()

# Global TextService instance
text_service = None


# lifespan events
@asynccontextmanager
async def lifespan(_: FastAPI):
    global text_service
    print(f"Server started in port {settings.PORT}")
    # Initialize TextService on startup
    text_service = TextService(
        aws_region=settings.AWS_REGION,
        dynamodb_table_name=settings.DYNAMODB_TABLE_NAME,
        bedrock_agent_id=settings.BEDROCK_AGENT_ID,
        bedrock_agent_alias=settings.BEDROCK_AGENT_ALIAS,
    )
    yield


# main application setup
app = FastAPI(
    title="Typing Practice Text Service",
    description="API for generating random text content for typing practice applications",
    version="1.0.0",
    lifespan=lifespan,
)
app.include_router(textRouter, prefix="/api", tags=["Text Generation"])


# Root endpoint
@app.get("/", tags=["Health"])
async def root():
    return {
        "message": "Typing Practice Text Service API is running!",
        "app": settings.app_name,
        "endpoints": {
            "generate_text": "/api/generate-text",
            "docs": "/docs",
        },
    }


# AWS Lambda handler via Mangum
handler = Mangum(app, lifespan="auto")
