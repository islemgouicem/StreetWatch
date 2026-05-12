from uuid import UUID
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status

from app.api.deps import get_current_user
from app.services.supabase_client import get_supabase_service_client
from app.schemas.user import UserRead, UserStats, UserUpdate


router = APIRouter(prefix="/users", tags=["users"])


def _build_user_read(user_row: dict[str, Any], stats: UserStats | None = None) -> UserRead:
    return UserRead(
        id=user_row["id"],
        email=user_row.get("email") or "",
        username=user_row.get("username") or "",
        full_name=user_row.get("full_name"),
        avatar_url=user_row.get("avatar_url"),
        image_profile=user_row.get("image_profile"),
        points=int(user_row.get("points") or 0),
        is_active=bool(user_row.get("is_active", True)),
        is_admin=bool(user_row.get("is_admin", False)),
        created_at=user_row.get("created_at"),
        updated_at=user_row.get("updated_at"),
        total_reports=(stats.reports_count if stats else 0),
        verified_reports=(stats.verified_reports if stats else 0),
    )


def _count_rows(table_name: str, *filters: tuple[str, str, Any]) -> int:
    query = get_supabase_service_client().table(table_name).select("id", count="exact", head=True)
    for field, operator, value in filters:
        if operator == "eq":
            query = query.eq(field, value)
        elif operator == "in":
            query = query.in_(field, value)
    result = query.execute()
    return int(result.count or 0)


@router.get("/me", response_model=UserRead)
async def read_current_user(current_user: dict[str, Any] = Depends(get_current_user)) -> UserRead:
    user_id = str(current_user["id"])
    stats = UserStats(
        reports_count=_count_rows("reports", ("user_id", "eq", user_id)),
        verified_reports=_count_rows(
            "reports",
            ("user_id", "eq", user_id),
            ("status", "eq", "verified"),
        ),
        votes_cast=_count_rows("votes", ("user_id", "eq", user_id)),
        badges_count=_count_rows("user_badges", ("user_id", "eq", user_id)),
        points=int(current_user.get("points") or 0),
    )
    return _build_user_read(current_user, stats)


@router.patch("/me", response_model=UserRead)
async def update_current_user(
    payload: UserUpdate,
    current_user: dict[str, Any] = Depends(get_current_user),
) -> UserRead:
    db = get_supabase_service_client()
    user_id = str(current_user["id"])

    update_payload = payload.model_dump(exclude_unset=True)
    if not update_payload:
        return _build_user_read(current_user)

    if payload.username and payload.username != current_user.get("username"):
        conflict = (
            db.table("users")
            .select("id")
            .eq("username", payload.username)
            .neq("id", user_id)
            .limit(1)
            .execute()
        )
        if conflict.data:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Username already exists")

    updated = db.table("users").update(update_payload).eq("id", user_id).execute()
    rows = updated.data or []
    if not rows:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return _build_user_read(rows[0])


@router.get("/{user_id}", response_model=UserRead)
async def read_user(user_id: UUID) -> UserRead:
    db = get_supabase_service_client()
    response = db.table("users").select("*").eq("id", str(user_id)).limit(1).execute()
    rows = response.data or []
    if not rows:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    user_row = rows[0]
    stats = UserStats(
        reports_count=_count_rows("reports", ("user_id", "eq", str(user_id))),
        verified_reports=_count_rows(
            "reports",
            ("user_id", "eq", str(user_id)),
            ("status", "eq", "verified"),
        ),
        votes_cast=_count_rows("votes", ("user_id", "eq", str(user_id))),
        badges_count=_count_rows("user_badges", ("user_id", "eq", str(user_id))),
        points=int(user_row.get("points") or 0),
    )
    return _build_user_read(user_row, stats)


@router.get("/{user_id}/stats", response_model=UserStats)
async def read_user_stats(user_id: UUID) -> UserStats:
    db = get_supabase_service_client()
    response = db.table("users").select("id,points").eq("id", str(user_id)).limit(1).execute()
    rows = response.data or []
    if not rows:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    return UserStats(
        reports_count=_count_rows("reports", ("user_id", "eq", str(user_id))),
        verified_reports=_count_rows(
            "reports",
            ("user_id", "eq", str(user_id)),
            ("status", "eq", "verified"),
        ),
        votes_cast=_count_rows("votes", ("user_id", "eq", str(user_id))),
        badges_count=_count_rows("user_badges", ("user_id", "eq", str(user_id))),
        points=int(rows[0].get("points") or 0),
    )
