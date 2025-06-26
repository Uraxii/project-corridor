from fastapi import APIRouter, HTTPException, status, Depends
from typing import List

from app.models.player import PlayerData, PlayerDataUpdate, InstanceRequest, InstanceInfo
from app.models.auth import UserInfo
from app.api.auth import get_current_user

router = APIRouter()


# In-memory storage for demo purposes
# In production, you'd use a proper database
player_data_store: dict[int, PlayerData] = {}
instances_store: dict[str, InstanceInfo] = {}


@router.get("/data", response_model=PlayerData)
async def get_player_data(current_user: UserInfo = Depends(get_current_user)):
    """
    Get player's persistent data.
    This would typically load from a database.
    """
    player_id = current_user.player_id
    
    # Create default player data if it doesn't exist
    if player_id not in player_data_store:
        player_data_store[player_id] = PlayerData(
            player_id=player_id,
            username=current_user.username
        )
    
    return player_data_store[player_id]


@router.post("/data", response_model=PlayerData)
async def update_player_data(
    update_data: PlayerDataUpdate,
    current_user: UserInfo = Depends(get_current_user)
):
    """
    Update player's persistent data.
    This would typically save to a database.
    """
    player_id = current_user.player_id
    
    # Get existing data or create new
    if player_id not in player_data_store:
        player_data_store[player_id] = PlayerData(
            player_id=player_id,
            username=current_user.username
        )
    
    existing_data = player_data_store[player_id]
    
    # Update fields that were provided
    update_dict = update_data.dict(exclude_unset=True)
    for field, value in update_dict.items():
        if hasattr(existing_data, field):
            setattr(existing_data, field, value)
    
    player_data_store[player_id] = existing_data
    return existing_data


@router.post("/instance", response_model=InstanceInfo)
async def request_instance(
    instance_request: InstanceRequest,
    current_user: UserInfo = Depends(get_current_user)
):
    """
    Request a game instance.
    In a real implementation, this would:
    1. Find an available Godot instance or spawn a new one
    2. Return connection details for the client
    """
    # Generate a unique instance ID
    instance_id = f"instance_{len(instances_store) + 1}_{current_user.player_id}"
    
    # Create instance info
    instance_info = InstanceInfo(
        instance_id=instance_id,
        instance_type=instance_request.instance_type,
        current_players=1,
        max_players=instance_request.max_players,
        status="active",
        connection_info={
            "host": "localhost",  # This would be the Godot instance IP
            "port": 7000 + len(instances_store),  # Dynamic port assignment
            "protocol": "ws"  # or "tcp" depending on how Godot instances communicate
        }
    )
    
    instances_store[instance_id] = instance_info
    
    return instance_info


@router.get("/instances", response_model=List[InstanceInfo])
async def list_instances(current_user: UserInfo = Depends(get_current_user)):
    """
    List available game instances.
    """
    return list(instances_store.values())


@router.get("/instance/{instance_id}", response_model=InstanceInfo)
async def get_instance_info(
    instance_id: str,
    current_user: UserInfo = Depends(get_current_user)
):
    """
    Get information about a specific instance.
    """
    if instance_id not in instances_store:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Instance not found"
        )
    
    return instances_store[instance_id]


@router.delete("/instance/{instance_id}")
async def leave_instance(
    instance_id: str,
    current_user: UserInfo = Depends(get_current_user)
):
    """
    Leave a game instance.
    In a real implementation, this would notify the Godot instance
    and potentially shut it down if no players remain.
    """
    if instance_id not in instances_store:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Instance not found"
        )
    
    instance = instances_store[instance_id]
    instance.current_players = max(0, instance.current_players - 1)
    
    # Remove instance if no players left
    if instance.current_players == 0:
        del instances_store[instance_id]
        return {"message": "Instance closed"}
    
    return {"message": "Left instance successfully"}
