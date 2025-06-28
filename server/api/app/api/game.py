from fastapi import APIRouter, HTTPException, status, Depends
import httpx
from typing import Optional

from app.models.auth import UserInfo
from app.api.auth import get_current_user
from app.core.config import settings

router = APIRouter()

# Shard Manager URL - should be configurable
SHARD_MANAGER_URL = "http://shard-api:8081"


@router.get("/hub/connection")
async def get_hub_connection(
    current_user: UserInfo = Depends(get_current_user)
) -> dict:
    """
    Get connection information for the player hub.
    Clients call this after login to get hub server details.
    """
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{SHARD_MANAGER_URL}/api/v0/shards/hub",
                timeout=10.0
            )
            response.raise_for_status()
            hub_info = response.json()
            
            return {
                "hub_connection": hub_info,
                "message": "Connect to this hub server to enter the game world"
            }
            
    except httpx.HTTPError as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Hub server is currently unavailable"
        )


@router.post("/dungeon/create")
async def create_dungeon_shard(
    dungeon_id: str,
    max_players: int = 4,
    current_user: UserInfo = Depends(get_current_user)
) -> dict:
    """
    Create a new dungeon shard for the player's party.
    Returns connection information for the new dungeon instance.
    """
    try:
        async with httpx.AsyncClient() as client:
            shard_request = {
                "shard_type": "dungeon",
                "name": f"dungeon_{dungeon_id}",
                "max_players": max_players,
                "dungeon_id": dungeon_id,
                "game_settings": {
                    "creator_id": current_user.player_id,
                    "creator_name": current_user.username
                }
            }
            
            response = await client.post(
                f"{SHARD_MANAGER_URL}/api/v0/shards/",
                json=shard_request,
                timeout=30.0
            )
            response.raise_for_status()
            shard_info = response.json()
            
            return {
                "shard_info": shard_info,
                "message": "Dungeon instance created successfully"
            }
            
    except httpx.HTTPError as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Failed to create dungeon instance"
        )


@router.get("/shards")
async def list_available_shards(
    current_user: UserInfo = Depends(get_current_user)
) -> dict:
    """
    List all available shards (for admin or debugging).
    """
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{SHARD_MANAGER_URL}/api/v0/shards/",
                timeout=10.0
            )
            response.raise_for_status()
            return response.json()
            
    except httpx.HTTPError as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Shard manager is currently unavailable"
        )
