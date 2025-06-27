from sqlalchemy.orm import Session
from typing import Optional, List
from datetime import datetime

from app.db.models import Character, User
from app.models.character import CharacterCreate, CharacterUpdate


def create_character(db: Session, user_id: int, character: CharacterCreate) -> Character:
    """Create a new character for a user."""
    db_character = Character(
        user_id=user_id,
        name=character.name)

    db.add(db_character)
    db.commit()
    db.refresh(db_character)
    return db_character


def get_character_by_id(db: Session, character_id: int, 
                       user_id: int) -> Optional[Character]:
    """Get a specific character by ID for a user."""
    return db.query(Character).filter(
        Character.id == character_id,
        Character.user_id == user_id
    ).first()


def get_user_characters(db: Session, user_id: int, 
                       skip: int = 0, limit: int = 100) -> List[Character]:
    """Get all characters for a user."""
    return db.query(Character).filter(
        Character.user_id == user_id
    ).offset(skip).limit(limit).all()


def count_user_characters(db: Session, user_id: int) -> int:
    """Count total characters for a user."""
    return db.query(Character).filter(
        Character.user_id == user_id
    ).count()


def update_character(db: Session, character_id: int, user_id: int,
                    character_update: CharacterUpdate) -> Optional[Character]:
    """Update a character's data."""
    db_character = get_character_by_id(db, character_id, user_id)
    if not db_character:
        return None
    
    update_data = character_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_character, field, value)
    
    db_character.last_played = datetime.utcnow()
    db.commit()
    db.refresh(db_character)
    return db_character


def delete_character(db: Session, character_id: int, 
                    user_id: int) -> bool:
    """Delete a character."""
    db_character = get_character_by_id(db, character_id, user_id)
    if not db_character:
        return False
    
    db.delete(db_character)
    db.commit()
    return True


def get_or_create_user(db: Session, username: str, 
                      hashed_password: str) -> User:
    """Get or create a user account."""
    user = db.query(User).filter(User.username == username).first()
    if not user:
        user = User(username=username, hashed_password=hashed_password)
        db.add(user)
        db.commit()
        db.refresh(user)
    return user
