from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from datetime import datetime
from enum import Enum


class ShardType(str, Enum):
    HUB = "hub"
    DUNGEON = "dungeon"
    CUSTOM = "custom"


class ShardStatus(str, Enum):
    STARTING = "starting"
    RUNNING = "running"
    STOPPING = "stopping"
    STOPPED = "stopped"
    ERROR = "error"


class ShardCreateRequest(BaseModel):
    """Request to create a new shard."""
    shard_type: ShardType
    name: Optional[str] = None
    max_players: int = Field(default=4, ge=1, le=100)
    # Dungeon-specific settings
    dungeon_id: Optional[str] = None
    # Custom game settings
    game_settings: Optional[Dict[str, Any]] = None


class ShardInfo(BaseModel):
    """Information about a running shard."""
    shard_id: str
    shard_type: ShardType
    name: str
    status: ShardStatus
    host: str
    port: int
    max_players: int
    current_players: int = 0
    created_at: datetime
    last_heartbeat: Optional[datetime] = None
    # Additional shard-specific data
    dungeon_id: Optional[str] = None
    game_settings: Optional[Dict[str, Any]] = None


class ShardConnectionInfo(BaseModel):
    """Connection information for clients."""
    shard_id: str
    host: str
    port: int
    shard_type: ShardType
    name: str
    current_players: int
    max_players: int


class ShardListResponse(BaseModel):
    """Response for listing shards."""
    shards: List[ShardInfo]
    total: int


class ShardStatsRequest(BaseModel):
    """Update shard statistics from the game server."""
    shard_id: str
    current_players: int
    game_data: Optional[Dict[str, Any]] = None


class ShardHeartbeat(BaseModel):
    """Heartbeat from a shard to confirm it's alive."""
    shard_id: str
    status: ShardStatus
    current_players: int
    uptime_seconds: int