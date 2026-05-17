from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class BadgeRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    code: str
    name: str
    description: str | None
    points_reward: int
    created_at: datetime


class BadgeCreate(BaseModel):
    code: str = Field(min_length=2, max_length=100)
    name: str = Field(min_length=2, max_length=100)
    description: str | None = None
    points_reward: int = Field(default=0, ge=0)


class BadgeUpdate(BaseModel):
    code: str | None = Field(default=None, min_length=2, max_length=100)
    name: str | None = Field(default=None, min_length=2, max_length=100)
    description: str | None = None
    points_reward: int | None = Field(default=None, ge=0)


class UserBadgeRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    badge_id: UUID
    awarded_at: datetime


class UserBadgeDetailRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    badge_id: UUID
    awarded_at: datetime
    badge: BadgeRead
