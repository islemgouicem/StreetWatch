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
    user_name: str
    user_avatar_url: str | None = None
    user_points: int = 0
    image_url: str
    damage_type: DamageType
    severity: Severity
    severity_confidence: float | None
    description: str | None
    latitude: float
    longitude: float
    status: ReportStatus
    upvotes: int = 0
    downvotes: int = 0
    verification_count: int
    created_at: datetime
    updated_at: datetime


class NearbyReportRead(ReportRead):
    distance_meters: float


class ReportVoteRequest(BaseModel):
    value: int = Field(default=1, ge=-1, le=1)


class ReportStatsCount(BaseModel):
    key: str
    count: int


class ReportStatsRead(BaseModel):
    total_reports: int
    pending_reports: int
    verified_reports: int
    rejected_reports: int
    resolved_reports: int
    under_review_reports: int
    by_damage_type: list[ReportStatsCount]
    by_severity: list[ReportStatsCount]
