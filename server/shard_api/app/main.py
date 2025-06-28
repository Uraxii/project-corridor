from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn
import asyncio

from app.api import endpoints
from app.core.config import settings
from app.core.core import shard_manager


@asynccontextmanager
async def lifespan(app: FastAPI):
    print("Starting Project Corridor Shard Manager...")
    
    # Initialize shard manager and create hub shard
    await shard_manager.initialize()
    
    # Start the hub shard
    hub_shard = await shard_manager.create_hub_shard()
    if hub_shard:
        print(f"Hub shard created: {hub_shard.shard_id} on port {hub_shard.port}")
    else:
        print("Failed to create hub shard")
    
    print("Shard Manager initialized")
    yield
    
    print("Shutting down shard manager...")
    await shard_manager.shutdown()
    print("Shutdown complete")


app = FastAPI(
    title="Project Corridor Shard Manager",
    description="Manages Godot game server instances",
    version="0.0.1",
    lifespan=lifespan
)


# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(
    endpoints.router, 
    prefix="/api/v0/shards", 
    tags=["shards"]
)


@app.get("/")
async def root():
    return {
        "app": app.title, 
        "description": app.description, 
        "version": app.version
    }


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
