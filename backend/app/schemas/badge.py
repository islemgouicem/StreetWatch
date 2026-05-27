from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class BadgeRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    code: str
    name: str
    description: str | None = None
    points_reward: int = 0
    created_at: datetime


class BadgeCreate(BaseModel):
    code: str
    name: str
    description: str | None = None
    points_reward: int = 0


class BadgeUpdate(BaseModel):
    code: str | None = None
    name: str | None = None
    description: str | None = None
    points_reward: int | None = None


class UserBadgeRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    badge_id: UUID
    awarded_at: datetime


class UserBadgeDetailRead(BaseModel):
    """UserBadge record with the full Badge embedded."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    badge_id: UUID
    awarded_at: datetime
    badge: BadgeRead