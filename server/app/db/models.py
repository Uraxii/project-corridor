from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, JSON
from sqlalchemy.orm import relationship
from datetime import datetime

from app.db.database import Base


class User(Base):
    __tablename__ = "users"
    
    id: int = Column(Integer, primary_key=True, index=True)
    username: str = Column(String, unique=True, index=True, nullable=False)
    hashed_password: str = Column(String, nullable=False)
    created_at: datetime = Column(DateTime, default=datetime.utcnow)
    
    # Relationship to characters
    characters = relationship("Character", back_populates="owner", 
                            cascade="all, delete-orphan")


class Character(Base):
    __tablename__ = "characters"
    
    id: int = Column(Integer, primary_key=True, index=True)
    user_id: int = Column(Integer, ForeignKey("users.id"), nullable=False)
    name: str = Column(String, nullable=False, index=True)
    # Store character stats as JSON for flexibility
    stats: dict = Column(JSON, default={
        "vigor": 1,
    })
    
    # Store equipment and inventory as JSON
    equipment: dict = Column(JSON, default={})
    inventory: dict = Column(JSON, default={})
    
    created_at: datetime = Column(DateTime, default=datetime.utcnow)
    last_played: datetime = Column(DateTime, default=datetime.utcnow, 
                                   onupdate=datetime.utcnow)
    
    # Relationship to user
    owner = relationship("User", back_populates="characters")
