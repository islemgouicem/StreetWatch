from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field


class UserBase(BaseModel):
    email: EmailStr
    username: str = Field(min_length=3, max_length=50)
    full_name: str | None = None
    avatar_url: str | None = None


class UserCreate(UserBase):
    password: str = Field(min_length=8, max_length=128)


class UserUpdate(BaseModel):
    username: str | None = Field(default=None, min_length=3, max_length=50)
    full_name: str | None = None
    avatar_url: str | None = None


class UserRead(UserBase):
    id: UUID
    points: int
    is_active: bool
    is_admin: bool
    created_at: datetime
    updated_at: datetime
    total_reports: int = 0
    verified_reports: int = 0


class UserStats(BaseModel):
    reports_count: int
    verified_reports: int
    votes_cast: int
    badges_count: int
    points: int