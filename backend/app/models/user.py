"""
User model for authentication.

For prototype: Single-user mode with hardcoded token.
Future: JWT authentication, multiple users.
"""
from sqlalchemy import Column, String, Integer
from .base import Base, TimestampMixin


class User(Base, TimestampMixin):
    """User model for authentication (single-user prototype)."""

    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(100), unique=True, nullable=False, index=True)
    auth_token = Column(String(255), nullable=False)  # Simple token auth for prototype

    def __repr__(self):
        return f"<User(id={self.id}, username='{self.username}')>"
