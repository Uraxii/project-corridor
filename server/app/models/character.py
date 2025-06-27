from pydantic import BaseModel, Field, validator
from typing import Optional, Dict, Any
from datetime import datetime


class CharacterStats(BaseModel):
    """Character statistics model."""
    health: int = Field(default=100, ge=0)
    mana: int = Field(default=50, ge=0)
    strength: int = Field(default=10, ge=1)
    defense: int = Field(default=10, ge=1)
    intelligence: int = Field(default=10, ge=1)
    agility: int = Field(default=10, ge=1)


class CharacterBase(BaseModel):
    """Base character model for creation/update."""
    name: str = Field(..., min_length=1, max_length=50)
    character_class: str = Field(..., min_length=1, max_length=50)
    
    @validator('character_class')
    def validate_class(cls, v: str) -> str:
        """Validate character class is one of allowed values."""
        allowed_classes = ["warrior", "mage", "ranger", "rogue", "priest"]
        if v.lower() not in allowed_classes:
            raise ValueError(f"Character class must be one of: "
                           f"{', '.join(allowed_classes)}")
        return v.lower()


class CharacterCreate(CharacterBase):
    """Model for creating a new character."""
    stats: Optional[CharacterStats] = None


class CharacterUpdate(BaseModel):
    """Model for updating character data."""
    name: Optional[str] = Field(None, min_length=1, max_length=50)
    level: Optional[int] = Field(None, ge=1, le=100)
    experience: Optional[int] = Field(None, ge=0)
    stats: Optional[Dict[str, int]] = None
    equipment: Optional[Dict[str, Any]] = None
    inventory: Optional[Dict[str, Any]] = None


class CharacterResponse(CharacterBase):
    """Model for character response data."""
    id: int
    user_id: int
    level: int
    experience: int
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
