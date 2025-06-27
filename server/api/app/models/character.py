from pydantic import BaseModel, Field, validator
from typing import Optional, Dict, Any
from datetime import datetime


class CharacterStats(BaseModel):
    """Character statistics model."""
    vigor: int = Field(default=10, ge=1)


class CharacterBase(BaseModel):
    """Base character model for creation/update."""
    name: str = Field(..., min_length=1, max_length=50)


class CharacterCreate(CharacterBase):
    """Model for creating a new character."""
    stats: Optional[CharacterStats] = None


class CharacterUpdate(BaseModel):
    """Model for updating character data."""
    name: Optional[str] = Field(None, min_length=1, max_length=50)
    stats: Optional[Dict[str, int]] = None
    equipment: Optional[Dict[str, Any]] = None
    inventory: Optional[Dict[str, Any]] = None


class CharacterResponse(CharacterBase):
    """Model for character response data."""
    id: int
    user_id: int
    stats: Dict[str, int]
    equipment: Dict[str, Any]
    inventory: Dict[str, Any]
    created_at: datetime
    last_played: datetime
    
    class Config:
        from_attributes = True


class CharacterListResponse(BaseModel):
    """Model for listing multiple characters."""
    characters: list[CharacterResponse]
    total: int
