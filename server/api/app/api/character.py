from fastapi import APIRouter, HTTPException, status, Depends, Query
from sqlalchemy.orm import Session
from typing import Optional

from app.models.character import (
    CharacterCreate, CharacterResponse, 
    CharacterListResponse, CharacterUpdate
)
from app.models.auth import UserInfo
from app.api.auth import get_current_user
from app.db.database import get_db
from app.db import crud_character

router = APIRouter()


@router.post("/", response_model=CharacterResponse)
async def create_character(
    character: CharacterCreate,
    current_user: UserInfo = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> CharacterResponse:
    """
    Create a new character for the current user.
    
    Maximum of 10 characters per user for MVP.
    """
    # Check character limit
    character_count = crud_character.count_user_characters(
        db, current_user.player_id)

    if character_count >= 10:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Maximum character limit (10) reached"
        )
    
    db_character = crud_character.create_character(
        db, current_user.player_id, character
    )
    return CharacterResponse.from_orm(db_character)


@router.get("/", response_model=CharacterListResponse)
async def list_characters(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    current_user: UserInfo = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> CharacterListResponse:
    """Get all characters for the current user."""
    characters = crud_character.get_user_characters(
        db, current_user.player_id, skip, limit
    )
    total = crud_character.count_user_characters(
        db, current_user.player_id
    )
    
    return CharacterListResponse(
        characters=[CharacterResponse.from_orm(char) 
                   for char in characters],
        total=total
    )


@router.get("/{character_id}", response_model=CharacterResponse)
async def get_character(
    character_id: int,
    current_user: UserInfo = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> CharacterResponse:
    """Get a specific character by ID."""
    db_character = crud_character.get_character_by_id(
        db, character_id, current_user.player_id
    )
    
    if not db_character:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Character not found"
        )
    
    return CharacterResponse.from_orm(db_character)


@router.patch("/{character_id}", response_model=CharacterResponse)
async def update_character(
    character_id: int,
    character_update: CharacterUpdate,
    current_user: UserInfo = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> CharacterResponse:
    """Update a character's data."""
    db_character = crud_character.update_character(
        db, character_id, current_user.player_id, character_update
    )
    
    if not db_character:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Character not found"
        )
    
    return CharacterResponse.from_orm(db_character)


@router.delete("/{character_id}")
async def delete_character(
    character_id: int,
    current_user: UserInfo = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> dict:
    """Delete a character."""
    success = crud_character.delete_character(
        db, character_id, current_user.player_id
    )
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Character not found"
        )
    
    return {"message": "Character deleted successfully"}
