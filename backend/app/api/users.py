from uuid import UUID
from typing import Any

from fastapi import APIRouter, Depends, Query, HTTPException, status

from app.api.deps import get_current_user
from app.api.reports import _load_related_maps, _parse_pagination, _to_report_read
from app.schemas.enums import ReportStatus
from app.schemas.preferences import (
    AppearancePreferences,
    AppearancePreferencesUpdate,
    EmailPreferences,
    EmailPreferencesUpdate,
    LanguagePreferences,
    LanguagePreferencesUpdate,
    SecurityPreferences,
    SecurityPreferencesUpdate,
    UserPreferencesRead,
)
from app.schemas.report import ReportRead
from app.services.supabase_client import get_supabase_service_client
from app.schemas.user import UserRead, UserStats, UserUpdate


router = APIRouter(prefix="/users", tags=["users"])


def _default_preferences(user_id: str) -> dict[str, Any]:
    return {
        "user_id": user_id,
        "incident_digest": True,
        "milestone_alerts": True,
        "product_updates": False,
        "two_factor_enabled": False,
        "biometric_lock": False,
        "location_masking": False,
        "theme": "streetwatch",
        "dark_mode": False,
        "language": "en",
    }


def _ensure_preferences_row(user_id: str) -> dict[str, Any]:
    db = get_supabase_service_client()
    existing = db.table("user_preferences").select("*").eq("user_id", user_id).limit(1).execute()
    rows = existing.data or []
    if rows:
        return rows[0]

    created = db.table("user_preferences").insert(_default_preferences(user_id)).execute()
    created_rows = created.data or []
    if not created_rows:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to initialize user preferences",
        )
    return created_rows[0]


def _build_preferences_read(row: dict[str, Any]) -> UserPreferencesRead:
    return UserPreferencesRead(
        user_id=str(row["user_id"]),
        email=EmailPreferences(
            incident_digest=bool(row.get("incident_digest", True)),
            milestone_alerts=bool(row.get("milestone_alerts", True)),
            product_updates=bool(row.get("product_updates", False)),
        ),
        security=SecurityPreferences(
            two_factor_enabled=bool(row.get("two_factor_enabled", False)),
            biometric_lock=bool(row.get("biometric_lock", False)),
            location_masking=bool(row.get("location_masking", False)),
        ),
        appearance=AppearancePreferences(
            theme=str(row.get("theme") or "streetwatch"),
            dark_mode=bool(row.get("dark_mode", False)),
        ),
        language=LanguagePreferences(
            language=str(row.get("language") or "en"),
        ),
    )


def _build_user_read(user_row: dict[str, Any], stats: UserStats | None = None) -> UserRead:
    return UserRead(
        id=user_row["id"],
        email=user_row.get("email") or "",
        username=user_row.get("username") or "",
        full_name=user_row.get("full_name"),
        avatar_url=user_row.get("avatar_url"),
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


@router.get("/me/preferences", response_model=UserPreferencesRead)
async def read_current_user_preferences(
    current_user: dict[str, Any] = Depends(get_current_user),
) -> UserPreferencesRead:
    row = _ensure_preferences_row(str(current_user["id"]))
    return _build_preferences_read(row)


@router.get("/me/reports", response_model=list[ReportRead])
async def read_current_user_reports(
    status: ReportStatus | None = Query(default=None),
    limit: int | None = Query(default=None, ge=1, le=200),
    offset: int | None = Query(default=None, ge=0),
    page: int | None = Query(default=None, ge=1),
    page_size: int | None = Query(default=None, ge=1, le=200),
    current_user: dict[str, Any] = Depends(get_current_user),
) -> list[ReportRead]:
    db = get_supabase_service_client()
    effective_limit, effective_offset = _parse_pagination(limit, offset, page, page_size)

    query = (
        db.table("reports")
        .select("*")
        .eq("user_id", str(current_user["id"]))
        .order("created_at", desc=True)
    )
    if status is not None:
        query = query.eq("status", status.value)

    rows = query.range(effective_offset, effective_offset + effective_limit - 1).execute().data or []
    users_map, votes_map = _load_related_maps(rows)
    return [_to_report_read(row, users_map, votes_map) for row in rows]


@router.patch("/me/preferences/email", response_model=UserPreferencesRead)
async def update_email_preferences(
    payload: EmailPreferencesUpdate,
    current_user: dict[str, Any] = Depends(get_current_user),
) -> UserPreferencesRead:
    user_id = str(current_user["id"])
    _ensure_preferences_row(user_id)
    updated = (
        get_supabase_service_client()
        .table("user_preferences")
        .update(payload.model_dump())
        .eq("user_id", user_id)
        .execute()
    )
    rows = updated.data or []
    if not rows:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to update preferences")
    return _build_preferences_read(rows[0])


@router.patch("/me/preferences/security", response_model=UserPreferencesRead)
async def update_security_preferences(
    payload: SecurityPreferencesUpdate,
    current_user: dict[str, Any] = Depends(get_current_user),
) -> UserPreferencesRead:
    user_id = str(current_user["id"])
    _ensure_preferences_row(user_id)
    updated = (
        get_supabase_service_client()
        .table("user_preferences")
        .update(payload.model_dump())
        .eq("user_id", user_id)
        .execute()
    )
    rows = updated.data or []
    if not rows:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to update preferences")
    return _build_preferences_read(rows[0])


@router.patch("/me/preferences/appearance", response_model=UserPreferencesRead)
async def update_appearance_preferences(
    payload: AppearancePreferencesUpdate,
    current_user: dict[str, Any] = Depends(get_current_user),
) -> UserPreferencesRead:
    user_id = str(current_user["id"])
    _ensure_preferences_row(user_id)
    updated = (
        get_supabase_service_client()
        .table("user_preferences")
        .update(payload.model_dump())
        .eq("user_id", user_id)
        .execute()
    )
    rows = updated.data or []
    if not rows:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to update preferences")
    return _build_preferences_read(rows[0])


@router.patch("/me/preferences/language", response_model=UserPreferencesRead)
async def update_language_preferences(
    payload: LanguagePreferencesUpdate,
    current_user: dict[str, Any] = Depends(get_current_user),
) -> UserPreferencesRead:
    user_id = str(current_user["id"])
    _ensure_preferences_row(user_id)
    updated = (
        get_supabase_service_client()
        .table("user_preferences")
        .update(payload.model_dump())
        .eq("user_id", user_id)
        .execute()
    )
    rows = updated.data or []
    if not rows:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to update preferences")
    return _build_preferences_read(rows[0])


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
