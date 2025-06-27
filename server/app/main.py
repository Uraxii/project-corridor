from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn

from app.api import auth
from app.core.config import settings
from app.db.database import init_db


@asynccontextmanager
async def lifespan(app: FastAPI):
    print("Starting Project Corridor Backend...")
    await init_db()
    print("Database initialized")
    yield
    print("Shutting down...")


app = FastAPI(
    title="Project Corridor Backend",
    description="Game Backend API",
    version="0.0.1",
    lifespan=lifespan
)


# CORS middleware for Godot client connections
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/api/v0/auth", tags=["authentication"])


@app.get("/")
async def root():
    return {"app": app.title, "description": app.description, "version": app.version}


@app.get("/version")
async def version():
    return {"version": app.version}


@app.get("/health")
async def health_check():
    return {"status": "healthy"}


if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
        log_level="info"
    )
