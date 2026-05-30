from typing import Any

from fastapi import APIRouter, Depends

from app.api.deps import get_current_user
from app.schemas.user import UserRead, UserStats
from app.services.supabase_client import get_supabase_service_client


router = APIRouter(prefix="/auth", tags=["auth"])


def _count_user_rows(table_name: str, user_id: str, extra_filters: list[tuple[str, str]] | None = None) -> int:
    query = get_supabase_service_client().table(table_name).select("id", count="exact", head=True).eq("user_id", user_id)
    for field, value in (extra_filters or []):
        query = query.eq(field, value)
    return int(query.execute().count or 0)


@router.get("/me", response_model=UserRead)
async def read_me(current_user: dict[str, Any] = Depends(get_current_user)) -> UserRead:
    user_id = str(current_user["id"])
    total_reports = _count_user_rows("reports", user_id)
    verified_reports = _count_user_rows("reports", user_id, [("status", "verified")])
    badges_count = _count_user_rows("user_badges", user_id)

    return UserRead(
        id=current_user["id"],
        email=current_user.get("email") or "",
        username=current_user.get("username") or "",
        full_name=current_user.get("full_name"),
        avatar_url=current_user.get("avatar_url"),
        image_profile=current_user.get("image_profile"),
        points=int(current_user.get("points") or 0),
        is_active=bool(current_user.get("is_active", True)),
        is_admin=bool(current_user.get("is_admin", False)),
        created_at=current_user.get("created_at"),
        updated_at=current_user.get("updated_at"),
        total_reports=total_reports,
        verified_reports=verified_reports,
    )

