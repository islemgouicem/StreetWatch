from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status

from app.api.deps import get_current_admin, get_current_user
from app.schemas.badge import BadgeCreate, BadgeRead, BadgeUpdate, UserBadgeDetailRead
from app.services.points import award_points
from app.services.supabase_client import get_supabase_service_client


router = APIRouter(prefix="/badges", tags=["badges"])


def _read_badge_row(badge_id: UUID) -> dict[str, Any]:
    db = get_supabase_service_client()
    response = db.table("badges").select("*").eq("id", str(badge_id)).limit(1).execute()
    rows = response.data or []
    if not rows:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Badge not found")
    return rows[0]


def _build_user_badge_details(rows: list[dict[str, Any]]) -> list[UserBadgeDetailRead]:
    if not rows:
        return []

    db = get_supabase_service_client()
    badge_ids = sorted({str(row["badge_id"]) for row in rows})
    badge_rows = db.table("badges").select("*").in_("id", badge_ids).execute().data or []
    badge_map = {str(badge["id"]): badge for badge in badge_rows}

    results: list[UserBadgeDetailRead] = []
    for row in rows:
        badge = badge_map.get(str(row["badge_id"]))
        if not badge:
            continue
        results.append(
            UserBadgeDetailRead(
                id=row["id"],
                user_id=row["user_id"],
                badge_id=row["badge_id"],
                awarded_at=row["awarded_at"],
                badge=BadgeRead(**badge),
            )
        )
    return results


@router.get("", response_model=list[BadgeRead])
async def list_badges() -> list[BadgeRead]:
    rows = (
        get_supabase_service_client()
        .table("badges")
        .select("*")
        .order("points_reward", desc=True)
        .order("name")
        .execute()
        .data
        or []
    )
    return [BadgeRead(**row) for row in rows]


@router.get("/{badge_id}", response_model=BadgeRead)
async def read_badge(badge_id: UUID) -> BadgeRead:
    return BadgeRead(**_read_badge_row(badge_id))


@router.get("/me/awards", response_model=list[UserBadgeDetailRead])
async def read_my_badges(
    current_user: dict[str, Any] = Depends(get_current_user),
) -> list[UserBadgeDetailRead]:
    rows = (
        get_supabase_service_client()
        .table("user_badges")
        .select("*")
        .eq("user_id", str(current_user["id"]))
        .order("awarded_at", desc=True)
        .execute()
        .data
        or []
    )
    return _build_user_badge_details(rows)


@router.get("/users/{user_id}", response_model=list[UserBadgeDetailRead])
async def read_user_badges(user_id: UUID) -> list[UserBadgeDetailRead]:
    rows = (
        get_supabase_service_client()
        .table("user_badges")
        .select("*")
        .eq("user_id", str(user_id))
        .order("awarded_at", desc=True)
        .execute()
        .data
        or []
    )
    return _build_user_badge_details(rows)


@router.post("", response_model=BadgeRead, status_code=status.HTTP_201_CREATED)
async def create_badge(
    payload: BadgeCreate,
    _: dict[str, Any] = Depends(get_current_admin),
) -> BadgeRead:
    db = get_supabase_service_client()
    existing = db.table("badges").select("id").eq("code", payload.code).limit(1).execute()
    if existing.data:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Badge code already exists")

    created = db.table("badges").insert(payload.model_dump()).execute()
    rows = created.data or []
    if not rows:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to create badge")
    return BadgeRead(**rows[0])


@router.patch("/{badge_id}", response_model=BadgeRead)
async def update_badge(
    badge_id: UUID,
    payload: BadgeUpdate,
    _: dict[str, Any] = Depends(get_current_admin),
) -> BadgeRead:
    db = get_supabase_service_client()
    update_payload = payload.model_dump(exclude_unset=True)
    if not update_payload:
        return BadgeRead(**_read_badge_row(badge_id))

    if payload.code:
        conflict = db.table("badges").select("id").eq("code", payload.code).neq("id", str(badge_id)).limit(1).execute()
        if conflict.data:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Badge code already exists")

    updated = db.table("badges").update(update_payload).eq("id", str(badge_id)).execute()
    rows = updated.data or []
    if not rows:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Badge not found")
    return BadgeRead(**rows[0])


@router.post("/users/{user_id}/{badge_id}", response_model=UserBadgeDetailRead, status_code=status.HTTP_201_CREATED)
async def award_badge_to_user(
    user_id: UUID,
    badge_id: UUID,
    _: dict[str, Any] = Depends(get_current_admin),
) -> UserBadgeDetailRead:
    db = get_supabase_service_client()
    badge = _read_badge_row(badge_id)

    user_exists = db.table("users").select("id,points").eq("id", str(user_id)).limit(1).execute()
    user_rows = user_exists.data or []
    if not user_rows:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    existing = (
        db.table("user_badges")
        .select("*")
        .eq("user_id", str(user_id))
        .eq("badge_id", str(badge_id))
        .limit(1)
        .execute()
    )
    existing_rows = existing.data or []
    if existing_rows:
        details = _build_user_badge_details(existing_rows)
        if details:
            return details[0]
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Badge already awarded")

    created = (
        db.table("user_badges")
        .insert({"user_id": str(user_id), "badge_id": str(badge_id)})
        .execute()
    )
    created_rows = created.data or []
    if not created_rows:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to award badge")

    reward_points = int(badge.get("points_reward") or 0)
    if reward_points:
        award_points(
            user_id=str(user_id),
            delta=reward_points,
            source_type="badge_award",
            source_id=str(badge_id),
            reason=f"Awarded badge: {badge.get('name') or badge.get('code') or 'badge'}",
        )

    details = _build_user_badge_details(created_rows)
    if not details:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to load awarded badge")
    return details[0]
