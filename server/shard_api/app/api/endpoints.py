from fastapi import APIRouter, HTTPException, status
from typing import Optional

from app.models.shard import (
    ShardCreateRequest, ShardInfo, ShardListResponse,
    ShardConnectionInfo, ShardStatsRequest, ShardHeartbeat
)
from app.core.shard_manager import shard_manager

router = APIRouter()


@router.post("/", response_model=ShardInfo)
async def create_shard(request: ShardCreateRequest) -> ShardInfo:
    """
    Create a new shard.
    Used by the main API to request dungeon instances.
    """
    shard = await shard_manager.create_shard(request)
    if not shard:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Failed to create shard - no available resources"
        )
    return shard


@router.get("/", response_model=ShardListResponse)
async def list_shards() -> ShardListResponse:
    """List all running shards."""
    shards = shard_manager.list_shards()
    return ShardListResponse(shards=shards, total=len(shards))


@router.get("/hub", response_model=ShardConnectionInfo)
async def get_hub_connection() -> ShardConnectionInfo:
    """
    Get connection information for the player hub.
    This is called by the main API when clients want to connect to the hub.
    """
    hub_info = shard_manager.get_hub_shard()
    if not hub_info:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Hub shard is not available"
        )
    return hub_info


@router.get("/{shard_id}", response_model=ShardInfo)
async def get_shard(shard_id: str) -> ShardInfo:
    """Get information about a specific shard."""
    shard = shard_manager.get_shard(shard_id)
    if not shard:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Shard not found"
        )
    return shard


@router.get("/{shard_id}/connection", response_model=ShardConnectionInfo)
async def get_shard_connection(shard_id: str) -> ShardConnectionInfo:
    """
    Get connection information for a specific shard.
    Used by clients to get connection details for dungeons.
    """
    shard = shard_manager.get_shard(shard_id)
    if not shard:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Shard not found"
        )
    
    return ShardConnectionInfo(
        shard_id=shard.shard_id,
        host=shard.host,
        port=shard.port,
        shard_type=shard.shard_type,
        name=shard.name,
        current_players=shard.current_players,
        max_players=shard.max_players
    )


@router.delete("/{shard_id}")
async def stop_shard(shard_id: str) -> dict:
    """Stop and remove a shard."""
    success = await shard_manager.stop_shard(shard_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Shard not found or failed to stop"
        )
    return {"message": f"Shard {shard_id} stopped successfully"}


@router.post("/{shard_id}/stats")
async def update_shard_stats(
    shard_id: str, 
    stats: ShardStatsRequest
) -> dict:
    """
    Update shard statistics.
    Called by the Godot server to report player count and game state.
    """
    success = shard_manager.update_shard_stats(
        shard_id, stats.current_players
    )
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Shard not found"
        )
    return {"message": "Stats updated successfully"}


@router.post("/{shard_id}/heartbeat")
async def shard_heartbeat(
    shard_id: str,
    heartbeat: ShardHeartbeat
) -> dict:
    """
    Receive heartbeat from a shard.
    Godot servers send this periodically to confirm they're alive.
    """
    success = shard_manager.update_shard_stats(
        shard_id, heartbeat.current_players
    )
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Shard not found"
        )
    return {"message": "Heartbeat received"}


@router.get("/stats/summary")
async def get_shard_stats() -> dict:
    """Get summary statistics for all shards."""
    shards = shard_manager.list_shards()
    
    total_shards = len(shards)
    total_players = sum(shard.current_players for shard in shards)
    
    by_type = {}
    for shard in shards:
        shard_type = shard.shard_type
        if shard_type not in by_type:
            by_type[shard_type] = {"count": 0, "players": 0}
        by_type[shard_type]["count"] += 1
        by_type[shard_type]["players"] += shard.current_players
    
    return {
        "total_shards": total_shards,
        "total_players": total_players,
        "by_type": by_type,
        "available_ports": len(range(
            shard_manager.settings.SHARD_PORT_RANGE_START,
            shard_manager.settings.SHARD_PORT_RANGE_END + 1
        )) - len(shard_manager.used_ports)
    }