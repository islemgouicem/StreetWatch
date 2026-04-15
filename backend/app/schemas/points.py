from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class PointTransactionRead(BaseModel):
    id: UUID
    user_id: UUID
    source_type: str
    source_id: str | None = None
    delta: int
    reason: str | None = None
    created_at: datetime


class PointAwardRequest(BaseModel):
    user_id: UUID
    delta: int
    reason: str = Field(min_length=2, max_length=255)
    source_type: str = Field(default="admin_award", min_length=2, max_length=100)
    source_id: str | None = Field(default=None, min_length=1, max_length=255)
