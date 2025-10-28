"""
Authentication and security utilities.

For prototype: Simple token-based authentication.
Future: JWT tokens, OAuth, etc.
"""
from fastapi import HTTPException, Security, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from typing import Optional

from .config import settings
from .database import get_db
from app.models.user import User

security = HTTPBearer()


def verify_token(
    credentials: HTTPAuthorizationCredentials = Security(security),
    db: Session = Depends(get_db),
) -> User:
    """
    Verify authentication token and return the user.

    For prototype: Validates against SINGLE_USER_TOKEN.
    Future: JWT validation, token expiry, refresh tokens, etc.

    Args:
        credentials: HTTP Bearer token credentials
        db: Database session

    Returns:
        User: Authenticated user object

    Raises:
        HTTPException: If token is invalid or user not found
    """
    token = credentials.credentials

    if token != settings.SINGLE_USER_TOKEN:
        raise HTTPException(
            status_code=401,
            detail="Invalid authentication token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # For prototype: Get or create single user
    user = db.query(User).filter(User.auth_token == token).first()

    if not user:
        # Create default user if doesn't exist
        user = User(
            username="default_user",
            auth_token=token,
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    return user


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Security(security),
    db: Session = Depends(get_db),
) -> User:
    """
    Dependency to get current authenticated user.

    Usage in endpoints:
        @app.get("/protected")
        def protected_route(user: User = Depends(get_current_user)):
            ...
    """
    return verify_token(credentials, db)


def get_current_user_optional(
    credentials: Optional[HTTPAuthorizationCredentials] = Security(security),
    db: Session = Depends(get_db),
) -> Optional[User]:
    """
    Optional authentication - returns user if token provided, None otherwise.

    Useful for endpoints that work differently when authenticated.
    """
    if credentials is None:
        return None

    try:
        return verify_token(credentials, db)
    except HTTPException:
        return None
