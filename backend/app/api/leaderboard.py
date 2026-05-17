from fastapi import APIRouter, Query

from app.schemas.leaderboard import LeaderboardEntry
from app.services.supabase_client import get_supabase_service_client


router = APIRouter(prefix="/leaderboard", tags=["leaderboard"])


def _count_rows(table_name: str, **filters: str) -> int:
    query = get_supabase_service_client().table(table_name).select("id", count="exact", head=True)
    for field, value in filters.items():
        query = query.eq(field, value)
    result = query.execute()
    return int(result.count or 0)


@router.get("", response_model=list[LeaderboardEntry])
async def get_leaderboard(
    limit: int = Query(default=50, ge=1, le=200),
) -> list[LeaderboardEntry]:
    db = get_supabase_service_client()
    users = (
        db.table("users")
        .select("id,username,avatar_url,points")
        .order("points", desc=True)
        .limit(limit)
        .execute()
        .data
        or []
    )

    leaderboard: list[LeaderboardEntry] = []
    for index, user in enumerate(users, start=1):
        user_id = user["id"]
        reports_count = _count_rows("reports", user_id=user_id)
        verified_reports = _count_rows("reports", user_id=user_id, status="verified")
        votes_cast = _count_rows("votes", user_id=user_id)

        leaderboard.append(
            LeaderboardEntry(
                rank=index,
                id=user_id,
                user_id=user_id,
                username=user.get("username") or "Anonymous",
                avatar_url=user.get("avatar_url"),
                points=int(user.get("points") or 0),
                total_reports=reports_count,
                reports_count=reports_count,
                verified_reports=verified_reports,
                votes_cast=votes_cast,
            )
        )

    return leaderboard
