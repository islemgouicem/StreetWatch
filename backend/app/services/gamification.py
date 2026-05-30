from typing import Any

from app.services.points import award_points
from app.services.supabase_client import get_supabase_service_client


DEFAULT_BADGES: list[dict[str, Any]] = [
    {
        "code": "first_report",
        "name": "First Report",
        "description": "Submit your first infrastructure report",
        "points_reward": 50,
    },
    {
        "code": "verified_reporter",
        "name": "Verified Reporter",
        "description": "Get your first report verified",
        "points_reward": 75,
    },
    {
        "code": "sharp_eye",
        "name": "Sharp Eye",
        "description": "Submit 10 reports",
        "points_reward": 100,
    },
    {
        "code": "street_guardian",
        "name": "Street Guardian",
        "description": "Submit 25 reports",
        "points_reward": 150,
    },
    {
        "code": "century_club",
        "name": "Century Club",
        "description": "Submit 100 reports",
        "points_reward": 400,
    },
    {
        "code": "community_hero",
        "name": "Community Hero",
        "description": "Reach 1000 points",
        "points_reward": 0,
    },
    {
        "code": "fast_responder",
        "name": "Fast Responder",
        "description": "Reach 10 verified reports",
        "points_reward": 150,
    },
    {
        "code": "top_reporter",
        "name": "Top Reporter",
        "description": "Reach 2500 points",
        "points_reward": 0,
    },
    {
        "code": "first_vote",
        "name": "Civic Validator",
        "description": "Cast your first report vote",
        "points_reward": 20,
    },
]


def _count_rows(table_name: str, **filters: str) -> int:
    query = get_supabase_service_client().table(table_name).select("id", count="exact", head=True)
    for field, value in filters.items():
        query = query.eq(field, value)
    result = query.execute()
    return int(result.count or 0)


def ensure_default_badges() -> None:
    db = get_supabase_service_client()
    existing = db.table("badges").select("code").execute().data or []
    existing_codes = {str(row["code"]) for row in existing}
    missing = [badge for badge in DEFAULT_BADGES if badge["code"] not in existing_codes]
    if missing:
        db.table("badges").insert(missing).execute()


def _award_badge_by_code(user_id: str, badge_code: str) -> None:
    db = get_supabase_service_client()
    badge_rows = db.table("badges").select("*").eq("code", badge_code).limit(1).execute().data or []
    if not badge_rows:
        return

    badge = badge_rows[0]
    existing = (
        db.table("user_badges")
        .select("id")
        .eq("user_id", user_id)
        .eq("badge_id", str(badge["id"]))
        .limit(1)
        .execute()
        .data
        or []
    )
    if existing:
        return

    created = db.table("user_badges").insert({"user_id": user_id, "badge_id": str(badge["id"])}).execute()
    if not (created.data or []):
        return

    reward_points = int(badge.get("points_reward") or 0)
    if reward_points:
        award_points(
            user_id=user_id,
            delta=reward_points,
            source_type="badge_award",
            source_id=str(badge["id"]),
            reason=f"Awarded badge: {badge.get('name') or badge_code}",
        )


def evaluate_user_gamification(user_id: str) -> None:
    ensure_default_badges()
    db = get_supabase_service_client()
    user_rows = db.table("users").select("id,points").eq("id", user_id).limit(1).execute().data or []
    if not user_rows:
        return

    points = int(user_rows[0].get("points") or 0)
    reports_count = _count_rows("reports", user_id=user_id)
    verified_reports = _count_rows("reports", user_id=user_id, status="verified")
    votes_cast = _count_rows("votes", user_id=user_id)

    if reports_count >= 1:
        _award_badge_by_code(user_id, "first_report")
    if reports_count >= 10:
        _award_badge_by_code(user_id, "sharp_eye")
    if reports_count >= 25:
        _award_badge_by_code(user_id, "street_guardian")
    if reports_count >= 100:
        _award_badge_by_code(user_id, "century_club")
    if verified_reports >= 1:
        _award_badge_by_code(user_id, "verified_reporter")
    if verified_reports >= 10:
        _award_badge_by_code(user_id, "fast_responder")
    if votes_cast >= 1:
        _award_badge_by_code(user_id, "first_vote")
    if points >= 1000:
        _award_badge_by_code(user_id, "community_hero")
    if points >= 2500:
        _award_badge_by_code(user_id, "top_reporter")