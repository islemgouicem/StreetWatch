from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class BadgeRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    code: str
    name: str
    description: str | None
    points_reward: int
    created_at: datetime


class UserBadgeRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    badge_id: UUID
    awarded_at: datetime