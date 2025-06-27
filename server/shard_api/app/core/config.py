from pydantic_settings import BaseSettings
from typing import Optional
import os


class Settings(BaseSettings):
    # Server settings
    HOST: str = "0.0.0.0"
    PORT: int = 8081
    DEBUG: bool = True
    
    # Godot server settings
    GODOT_SERVER_EXECUTABLE: str = "/usr/local/bin/godot_server"
    GODOT_PROJECT_PATH: str = "/app/godot_server"
    
    # Shard settings
    SHARD_PORT_RANGE_START: int = 9000
    SHARD_PORT_RANGE_END: int = 9100
    MAX_SHARDS: int = 50
    
    # Hub shard settings
    HUB_SHARD_NAME: str = "player_hub"
    HUB_MAX_PLAYERS: int = 100
    
    # Docker settings (if running shards in containers)
    USE_DOCKER: bool = False
    DOCKER_IMAGE: str = "project-corridor/godot-server:latest"
    DOCKER_NETWORK: str = "project-corridor_default"
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()