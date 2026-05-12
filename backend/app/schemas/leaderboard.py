from uuid import UUID

from pydantic import BaseModel


class LeaderboardEntry(BaseModel):
    rank: int
    user_id: UUID
    username: str
    avatar_url: str | None = None
    points: int
    reports_count: int
    verified_reports: int
    votes_cast: int
