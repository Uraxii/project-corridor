from fastapi import APIRouter, HTTPException, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Optional

from app.models.auth import CredentialRequest, LoginResponse, UserInfo, TokenData
from app.core.security import authenticate_user, create_access_token, verify_token, get_user_id

router = APIRouter()
security = HTTPBearer()


async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> UserInfo:
    """
    Dependency to get the current authenticated user from JWT token.
    Similar to how your Go code tracks client state.
    """
    token = credentials.credentials
    payload = verify_token(token)
    
    username: str = payload.get("sub")
    player_id: int = payload.get("player_id")
    
    if username is None or player_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    return UserInfo(player_id=player_id, username=username)


@router.post("/login", response_model=LoginResponse)
async def login(credentials: CredentialRequest):
    """
    Login endpoint - equivalent to handling CredentialMessage in your Go code.
    
    This replaces the WebSocket credential handling from your original code.
    Client sends POST request with username/password and gets back a JWT token.
    """
    # Authenticate user (matches your Go code's credential validation)
    if not authenticate_user(credentials.user, credentials.secret):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Get user ID (equivalent to your Go code's client ID assignment)
    player_id = get_user_id(credentials.user)
    if player_id is None:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get user ID"
        )
    
    # Create access token
    access_token = create_access_token(
        data={"sub": credentials.user, "player_id": player_id}
    )
    
    return LoginResponse(
        access_token=access_token,
        player_id=player_id,
        username=credentials.user
    )


@router.get("/me", response_model=UserInfo)
async def get_current_user_info(current_user: UserInfo = Depends(get_current_user)):
    """
    Get current user information.
    Equivalent to your Go code's IdMessage functionality.
    """
    return current_user


@router.post("/logout")
async def logout(current_user: UserInfo = Depends(get_current_user)):
    """
    Logout endpoint. 
    Since we're using stateless JWT tokens, this just confirms the token is valid.
    In a full implementation, you might want to blacklist the token.
    """
    return {"message": f"User {current_user.username} logged out successfully"}


@router.post("/refresh")
async def refresh_token(current_user: UserInfo = Depends(get_current_user)):
    """
    Refresh the access token.
    Creates a new token with extended expiration.
    """
    access_token = create_access_token(
        data={"sub": current_user.username, "player_id": current_user.player_id}
    )
    
    return LoginResponse(
        access_token=access_token,
        player_id=current_user.player_id,
        username=current_user.username
    )
