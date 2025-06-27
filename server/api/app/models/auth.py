from pydantic import BaseModel, Field
from typing import Optional


class CredentialRequest(BaseModel):
    """
    Equivalent to CredentialMessage from your Go protobuf.
    Represents login credentials sent by the client.
    """
    user: str = Field(..., min_length=1, description="Username")
    secret: str = Field(..., min_length=1, description="Password")


class LoginResponse(BaseModel):
    """Response sent back after successful authentication."""
    access_token: str
    token_type: str = "bearer"
    player_id: int
    username: str


class TokenData(BaseModel):
    """Data contained within JWT tokens."""
    username: Optional[str] = None
    player_id: Optional[int] = None


class UserInfo(BaseModel):
    """Basic user information."""
    player_id: int
    username: str
    is_active: bool = True
