from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.enums import DamageType, ReportStatus, Severity


class ReportCreate(BaseModel):
    damage_type: DamageType
    severity: Severity
    description: str | None = None
    image_url: str = Field(min_length=1)
    latitude: float
    longitude: float


class ReportUpdate(BaseModel):
    damage_type: DamageType | None = None
    severity: Severity | None = None
    description: str | None = None
    image_url: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    status: ReportStatus | None = None


class ReportRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    image_url: str
    damage_type: DamageType
    severity: Severity
    severity_confidence: float | None
    description: str | None
    latitude: float
    longitude: float
    status: ReportStatus
    verification_count: int
    created_at: datetime
    updated_at: datetime


class NearbyReportRead(ReportRead):
    distance_meters: float


class ReportVoteRequest(BaseModel):
    value: int = Field(default=1, ge=-1, le=1)