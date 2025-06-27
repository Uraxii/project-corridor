from sqlalchemy import create_engine, MetaData
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from app.core.config import settings

# Database setup
engine = create_engine(
    settings.DATABASE_URL, 
    connect_args={"check_same_thread": False}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


async def init_db():
    """Initialize database tables."""
    # Import models here to ensure they're registered
    from app.db.models import User, Character
    
    # Create tables
    Base.metadata.create_all(bind=engine)
    print("Database tables created successfully")
    
    # Create admin user if it doesn't exist
    from sqlalchemy.orm import Session
    from app.core.security import get_password_hash
    from app.db.crud_character import get_or_create_user
    
    db = SessionLocal()
    try:
        admin_hash = get_password_hash(settings.ADMIN_PASSWORD)
        get_or_create_user(db, settings.ADMIN_USERNAME, admin_hash)
        print("Admin user initialized")
    finally:
        db.close()


def get_db():
    """Database session dependency."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
