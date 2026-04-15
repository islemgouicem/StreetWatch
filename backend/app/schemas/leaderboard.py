from uuid import UUID

from pydantic import BaseModel


class LeaderboardEntry(BaseModel):
    rank: int
    id: UUID
    user_id: UUID
    username: str
    avatar_url: str | None = None
    points: int
    total_reports: int
    reports_count: int
    verified_reports: int
    votes_cast: int
