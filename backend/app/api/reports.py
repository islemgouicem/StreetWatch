from datetime import datetime, timedelta, timezone
from math import asin, cos, radians, sin, sqrt
from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.api.deps import get_current_admin, get_current_user
from app.core.config import get_settings
from app.schemas.enums import DamageType, ReportStatus, Severity
from app.schemas.report import (
    NearbyReportRead,
    ReportBulkCreateRequest,
    ReportBulkCreateResponse,
    ReportBulkItemResult,
    ReportCreate,
    ReportRead,
    ReportStatsCount,
    ReportStatsRead,
    ReportUpdate,
    ReportVoteRequest,
)
from app.services.supabase_client import get_supabase_service_client
from app.services.gamification import evaluate_user_gamification
from app.services.points import award_points


router = APIRouter(prefix="/reports", tags=["reports"])


def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    earth_radius_km = 6371.0
    d_lat = radians(lat2 - lat1)
    d_lon = radians(lon2 - lon1)
    a = sin(d_lat / 2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(d_lon / 2) ** 2
    c = 2 * asin(sqrt(a))
    return earth_radius_km * c


def _build_vote_summary(vote_rows: list[dict[str, Any]]) -> dict[str, dict[str, int]]:
    summary: dict[str, dict[str, int]] = {}
    for vote in vote_rows:
        report_id = str(vote["report_id"])
        report_summary = summary.setdefault(report_id, {"upvotes": 0, "downvotes": 0})
        value = int(vote.get("value") or 0)
        if value > 0:
            report_summary["upvotes"] += 1
        elif value < 0:
            report_summary["downvotes"] += 1
    return summary


def _load_related_maps(rows: list[dict[str, Any]]) -> tuple[dict[str, dict[str, Any]], dict[str, dict[str, int]]]:
    if not rows:
        return {}, {}

    db = get_supabase_service_client()
    user_ids = sorted({str(row["user_id"]) for row in rows if row.get("user_id")})
    report_ids = sorted({str(row["id"]) for row in rows if row.get("id")})

    users_map: dict[str, dict[str, Any]] = {}
    if user_ids:
        user_rows = db.table("users").select("id,username,avatar_url,points").in_("id", user_ids).execute().data or []
        users_map = {str(user["id"]): user for user in user_rows}

    votes_map: dict[str, dict[str, int]] = {}
    if report_ids:
        vote_rows = db.table("votes").select("report_id,value").in_("report_id", report_ids).execute().data or []
        votes_map = _build_vote_summary(vote_rows)

    return users_map, votes_map


def _to_report_read(
    row: dict[str, Any],
    users_map: dict[str, dict[str, Any]] | None = None,
    votes_map: dict[str, dict[str, int]] | None = None,
) -> ReportRead:
    users_map = users_map or {}
    votes_map = votes_map or {}
    user = users_map.get(str(row["user_id"]), {})
    vote_summary = votes_map.get(str(row["id"]), {})
    return ReportRead(
        id=row["id"],
        user_id=row["user_id"],
        client_report_id=row.get("client_report_id"),
        user_name=user.get("username") or "Anonymous",
        user_avatar_url=user.get("avatar_url"),
        user_points=int(user.get("points") or 0),
        image_url=row["image_url"],
        damage_type=row["damage_type"],
        severity=row["severity"],
        severity_confidence=row.get("severity_confidence"),
        description=row.get("description"),
        latitude=float(row["latitude"]),
        longitude=float(row["longitude"]),
        status=row["status"],
        upvotes=int(vote_summary.get("upvotes") or 0),
        downvotes=int(vote_summary.get("downvotes") or 0),
        verification_count=int(row.get("verification_count") or 0),
        created_at=row.get("created_at"),
        updated_at=row.get("updated_at"),
    )


def _is_duplicate(payload: ReportCreate, candidate: dict[str, Any]) -> bool:
    if candidate.get("damage_type") != payload.damage_type.value:
        return False
    distance_km = _haversine_km(
        payload.latitude,
        payload.longitude,
        float(candidate["latitude"]),
        float(candidate["longitude"]),
    )
    return distance_km <= 0.03


def _insert_report_for_user(
    payload: ReportCreate,
    current_user: dict[str, Any],
) -> ReportRead:
    db = get_supabase_service_client()
    settings = get_settings()

    cutoff = (datetime.now(timezone.utc) - timedelta(hours=24)).isoformat()
    recent = (
        db.table("reports")
        .select("id,damage_type,latitude,longitude")
        .gte("created_at", cutoff)
        .in_("status", ["pending", "verified", "under_review"])
        .limit(300)
        .execute()
        .data
        or []
    )
    for candidate in recent:
        if _is_duplicate(payload, candidate):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Potential duplicate report detected nearby",
            )

    insert_payload: dict[str, Any] = {
        "user_id": current_user["id"],
        "client_report_id": payload.client_report_id,
        "image_url": payload.image_url,
        "damage_type": payload.damage_type.value,
        "severity": payload.severity.value,
        "description": payload.description,
        "latitude": payload.latitude,
        "longitude": payload.longitude,
    }
    if settings.auto_verify_new_reports:
        insert_payload["status"] = ReportStatus.verified.value

    created = (
        db.table("reports")
        .insert(insert_payload)
        .execute()
    )
    rows = created.data or []
    if not rows:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to create report")

    users_map, votes_map = _load_related_maps(rows)
    report = _to_report_read(rows[0], users_map, votes_map)
    award_points(
        user_id=str(current_user["id"]),
        delta=25,
        source_type="report_created",
        source_id=str(report.id),
        reason="Submitted a new report",
    )
    if report.status == ReportStatus.verified:
        award_points(
            user_id=str(current_user["id"]),
            delta=50,
            source_type="report_verified",
            source_id=str(report.id),
            reason="Report was verified",
        )
    evaluate_user_gamification(str(current_user["id"]))
    return report


def _parse_pagination(
    limit: int | None,
    offset: int | None,
    page: int | None,
    page_size: int | None,
) -> tuple[int, int]:
    effective_limit = limit
    effective_offset = offset

    if effective_limit is None and page_size is not None:
        effective_limit = page_size
    if effective_offset is None and page is not None:
        current_page = max(page, 1)
        size = effective_limit or page_size or 50
        effective_offset = (current_page - 1) * size

    return effective_limit or 50, effective_offset or 0


def _apply_report_filters(
    query: Any,
    *,
    status_value: ReportStatus | None,
    damage_type: DamageType | None,
    severity: Severity | None,
    user_id: UUID | None,
    date_from: datetime | None,
    date_to: datetime | None,
) -> Any:
    if status_value is None:
        query = query.in_("status", ["verified", "rejected"])
    else:
        query = query.eq("status", status_value.value)

    if damage_type is not None:
        query = query.eq("damage_type", damage_type.value)
    if severity is not None:
        query = query.eq("severity", severity.value)
    if user_id is not None:
        query = query.eq("user_id", str(user_id))
    if date_from is not None:
        query = query.gte("created_at", date_from.isoformat())
    if date_to is not None:
        query = query.lte("created_at", date_to.isoformat())
    return query


def _filter_rows_by_bbox(rows: list[dict[str, Any]], bbox: str | None) -> list[dict[str, Any]]:
    if not bbox:
        return rows

    try:
        min_lon, min_lat, max_lon, max_lat = [float(part.strip()) for part in bbox.split(",")]
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="bbox must be minLon,minLat,maxLon,maxLat",
        ) from exc

    if min_lon > max_lon or min_lat > max_lat:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="bbox coordinates are invalid",
        )

    return [
        row
        for row in rows
        if min_lat <= float(row["latitude"]) <= max_lat and min_lon <= float(row["longitude"]) <= max_lon
    ]


def _rows_to_geojson(
    rows: list[dict[str, Any]],
    users_map: dict[str, dict[str, Any]],
    votes_map: dict[str, dict[str, int]],
) -> dict[str, Any]:
    features: list[dict[str, Any]] = []
    for row in rows:
        report = _to_report_read(row, users_map, votes_map)
        properties = report.model_dump(mode="json")
        properties.pop("latitude", None)
        properties.pop("longitude", None)
        features.append(
            {
                "type": "Feature",
                "geometry": {
                    "type": "Point",
                    "coordinates": [report.longitude, report.latitude],
                },
                "properties": properties,
            }
        )

    return {
        "type": "FeatureCollection",
        "features": features,
    }


def _read_report_row(report_id: UUID) -> dict[str, Any]:
    db = get_supabase_service_client()
    response = db.table("reports").select("*").eq("id", str(report_id)).limit(1).execute()
    rows = response.data or []
    if not rows:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report not found")
    return rows[0]


def _update_report_status(report_id: UUID, status_value: ReportStatus) -> ReportRead:
    db = get_supabase_service_client()
    updated = db.table("reports").update({"status": status_value.value}).eq("id", str(report_id)).execute()
    rows = updated.data or []
    if not rows:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report not found")
    users_map, votes_map = _load_related_maps(rows)
    return _to_report_read(rows[0], users_map, votes_map)


@router.get("", response_model=list[ReportRead])
async def list_reports(
    status: ReportStatus | None = Query(default=None),
    damage_type: DamageType | None = Query(default=None),
    severity: Severity | None = Query(default=None),
    user_id: UUID | None = Query(default=None),
    date_from: datetime | None = Query(default=None),
    date_to: datetime | None = Query(default=None),
    bbox: str | None = Query(default=None),
    limit: int | None = Query(default=None, ge=1, le=200),
    offset: int | None = Query(default=None, ge=0),
    page: int | None = Query(default=None, ge=1),
    page_size: int | None = Query(default=None, ge=1, le=200),
) -> list[ReportRead]:
    db = get_supabase_service_client()
    effective_limit, effective_offset = _parse_pagination(limit, offset, page, page_size)
    query = db.table("reports").select("*").order("created_at", desc=True)
    query = _apply_report_filters(
        query,
        status_value=status,
        damage_type=damage_type,
        severity=severity,
        user_id=user_id,
        date_from=date_from,
        date_to=date_to,
    )

    fetch_limit = effective_limit if not bbox else min(max(effective_offset + effective_limit, 200), 1000)
    rows = query.range(0 if bbox else effective_offset, (fetch_limit - 1) if bbox else (effective_offset + effective_limit - 1)).execute().data or []
    rows = _filter_rows_by_bbox(rows, bbox)
    rows = rows[effective_offset : effective_offset + effective_limit] if bbox else rows
    users_map, votes_map = _load_related_maps(rows)
    return [_to_report_read(row, users_map, votes_map) for row in rows]


@router.get("/nearby", response_model=list[NearbyReportRead])
async def list_nearby_reports(
    latitude: float,
    longitude: float,
    radius_km: float = Query(default=5.0, ge=0.1, le=100.0),
    limit: int = Query(default=50, ge=1, le=200),
) -> list[NearbyReportRead]:
    db = get_supabase_service_client()
    rows = (
        db.rpc(
            "nearby_public_reports",
            {
                "input_latitude": latitude,
                "input_longitude": longitude,
                "input_radius_km": radius_km,
                "input_limit": limit,
            },
        )
        .execute()
        .data
        or []
    )
    users_map, votes_map = _load_related_maps(rows)

    return [
        NearbyReportRead(
            **_to_report_read(row, users_map, votes_map).model_dump(),
            distance_meters=float(row["distance_meters"]),
        )
        for row in rows
    ]


@router.get("/geojson")
async def list_reports_geojson(
    status: ReportStatus | None = Query(default=None),
    damage_type: DamageType | None = Query(default=None),
    severity: Severity | None = Query(default=None),
    user_id: UUID | None = Query(default=None),
    date_from: datetime | None = Query(default=None),
    date_to: datetime | None = Query(default=None),
    bbox: str | None = Query(default=None),
    limit: int | None = Query(default=None, ge=1, le=2000),
    offset: int | None = Query(default=None, ge=0),
    page: int | None = Query(default=None, ge=1),
    page_size: int | None = Query(default=None, ge=1, le=2000),
) -> dict[str, Any]:
    db = get_supabase_service_client()
    effective_limit, effective_offset = _parse_pagination(limit, offset, page, page_size)
    query = db.table("reports").select("*").order("created_at", desc=True)
    query = _apply_report_filters(
        query,
        status_value=status,
        damage_type=damage_type,
        severity=severity,
        user_id=user_id,
        date_from=date_from,
        date_to=date_to,
    )

    fetch_limit = effective_limit if not bbox else min(max(effective_offset + effective_limit, 500), 5000)
    rows = (
        query.range(
            0 if bbox else effective_offset,
            (fetch_limit - 1) if bbox else (effective_offset + effective_limit - 1),
        ).execute().data
        or []
    )
    rows = _filter_rows_by_bbox(rows, bbox)
    rows = rows[effective_offset : effective_offset + effective_limit] if bbox else rows
    users_map, votes_map = _load_related_maps(rows)
    return _rows_to_geojson(rows, users_map, votes_map)


@router.post("", response_model=ReportRead, status_code=status.HTTP_201_CREATED)
async def create_report(
    payload: ReportCreate,
    current_user: dict[str, Any] = Depends(get_current_user),
) -> ReportRead:
    return _insert_report_for_user(payload, current_user)


@router.get("/stats", response_model=ReportStatsRead)
async def get_report_stats(
    status: ReportStatus | None = Query(default=None),
    damage_type: DamageType | None = Query(default=None),
    severity: Severity | None = Query(default=None),
    user_id: UUID | None = Query(default=None),
    date_from: datetime | None = Query(default=None),
    date_to: datetime | None = Query(default=None),
    bbox: str | None = Query(default=None),
) -> ReportStatsRead:
    db = get_supabase_service_client()
    query = db.table("reports").select("*").order("created_at", desc=True).limit(1000)
    query = _apply_report_filters(
        query,
        status_value=status,
        damage_type=damage_type,
        severity=severity,
        user_id=user_id,
        date_from=date_from,
        date_to=date_to,
    )
    rows = query.execute().data or []
    rows = _filter_rows_by_bbox(rows, bbox)

    status_counts = {report_status.value: 0 for report_status in ReportStatus}
    damage_counts = {report_damage.value: 0 for report_damage in DamageType}
    severity_counts = {report_severity.value: 0 for report_severity in Severity}

    for row in rows:
        status_counts[str(row["status"])] = status_counts.get(str(row["status"]), 0) + 1
        damage_counts[str(row["damage_type"])] = damage_counts.get(str(row["damage_type"]), 0) + 1
        severity_counts[str(row["severity"])] = severity_counts.get(str(row["severity"]), 0) + 1

    return ReportStatsRead(
        total_reports=len(rows),
        pending_reports=status_counts.get(ReportStatus.pending.value, 0),
        verified_reports=status_counts.get(ReportStatus.verified.value, 0),
        rejected_reports=status_counts.get(ReportStatus.rejected.value, 0),
        resolved_reports=status_counts.get(ReportStatus.resolved.value, 0),
        under_review_reports=status_counts.get(ReportStatus.under_review.value, 0),
        by_damage_type=[
            ReportStatsCount(key=damage_key, count=count) for damage_key, count in damage_counts.items()
        ],
        by_severity=[
            ReportStatsCount(key=severity_key, count=count) for severity_key, count in severity_counts.items()
        ],
    )


@router.get("/admin/pending", response_model=list[ReportRead])
async def list_pending_reports(
    limit: int | None = Query(default=None, ge=1, le=200),
    offset: int | None = Query(default=None, ge=0),
    page: int | None = Query(default=None, ge=1),
    page_size: int | None = Query(default=None, ge=1, le=200),
    _: dict[str, Any] = Depends(get_current_admin),
) -> list[ReportRead]:
    db = get_supabase_service_client()
    effective_limit, effective_offset = _parse_pagination(limit, offset, page, page_size)
    rows = (
        db.table("reports")
        .select("*")
        .eq("status", ReportStatus.pending.value)
        .order("created_at", desc=True)
        .range(effective_offset, effective_offset + effective_limit - 1)
        .execute()
        .data
        or []
    )
    users_map, votes_map = _load_related_maps(rows)
    return [_to_report_read(row, users_map, votes_map) for row in rows]


@router.get("/admin/under-review", response_model=list[ReportRead])
async def list_under_review_reports(
    limit: int | None = Query(default=None, ge=1, le=200),
    offset: int | None = Query(default=None, ge=0),
    page: int | None = Query(default=None, ge=1),
    page_size: int | None = Query(default=None, ge=1, le=200),
    _: dict[str, Any] = Depends(get_current_admin),
) -> list[ReportRead]:
    db = get_supabase_service_client()
    effective_limit, effective_offset = _parse_pagination(limit, offset, page, page_size)
    rows = (
        db.table("reports")
        .select("*")
        .eq("status", ReportStatus.under_review.value)
        .order("created_at", desc=True)
        .range(effective_offset, effective_offset + effective_limit - 1)
        .execute()
        .data
        or []
    )
    users_map, votes_map = _load_related_maps(rows)
    return [_to_report_read(row, users_map, votes_map) for row in rows]


@router.get("/{report_id}", response_model=ReportRead)
async def read_report(report_id: UUID) -> ReportRead:
    report = _read_report_row(report_id)
    if report.get("status") == ReportStatus.pending.value:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Report is not public yet")
    users_map, votes_map = _load_related_maps([report])
    return _to_report_read(report, users_map, votes_map)


@router.patch("/{report_id}", response_model=ReportRead)
async def update_report(
    report_id: UUID,
    payload: ReportUpdate,
    current_user: dict[str, Any] = Depends(get_current_user),
) -> ReportRead:
    db = get_supabase_service_client()
    response = db.table("reports").select("*").eq("id", str(report_id)).limit(1).execute()
    rows = response.data or []
    if not rows:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report not found")

    report = rows[0]
    previous_status = report.get("status")
    if report["user_id"] != current_user["id"] and not bool(current_user.get("is_admin", False)):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not allowed to edit this report")
    if payload.status is not None and not bool(current_user.get("is_admin", False)):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only admins can change report status")

    update_payload = payload.model_dump(exclude_unset=True)
    if "status" in update_payload and update_payload["status"] is not None:
        update_payload["status"] = update_payload["status"].value
    if "damage_type" in update_payload and update_payload["damage_type"] is not None:
        update_payload["damage_type"] = update_payload["damage_type"].value
    if "severity" in update_payload and update_payload["severity"] is not None:
        update_payload["severity"] = update_payload["severity"].value

    updated = db.table("reports").update(update_payload).eq("id", str(report_id)).execute()
    updated_rows = updated.data or []
    if not updated_rows:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to update report")
    if (
        previous_status != ReportStatus.verified.value
        and updated_rows[0].get("status") == ReportStatus.verified.value
    ):
        award_points(
            user_id=str(updated_rows[0]["user_id"]),
            delta=50,
            source_type="report_verified",
            source_id=str(report_id),
            reason="Report was verified",
        )
        evaluate_user_gamification(str(updated_rows[0]["user_id"]))
    users_map, votes_map = _load_related_maps(updated_rows)
    return _to_report_read(updated_rows[0], users_map, votes_map)


@router.delete("/{report_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_report(
    report_id: UUID,
    current_user: dict[str, Any] = Depends(get_current_user),
) -> None:
    db = get_supabase_service_client()
    report = _read_report_row(report_id)
    is_admin = bool(current_user.get("is_admin", False))
    is_owner = report["user_id"] == current_user["id"]

    if not is_owner and not is_admin:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not allowed to delete this report")
    if not is_admin and report.get("status") != ReportStatus.pending.value:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only pending reports can be deleted by their owner",
        )

    db.table("reports").delete().eq("id", str(report_id)).execute()


@router.post("/bulk", response_model=ReportBulkCreateResponse)
async def bulk_create_reports(
    payload: ReportBulkCreateRequest,
    current_user: dict[str, Any] = Depends(get_current_user),
) -> ReportBulkCreateResponse:
    db = get_supabase_service_client()
    results: list[ReportBulkItemResult] = []

    for report_payload in payload.reports:
        client_report_id = report_payload.client_report_id
        if client_report_id:
            existing = (
                db.table("reports")
                .select("*")
                .eq("user_id", str(current_user["id"]))
                .eq("client_report_id", client_report_id)
                .limit(1)
                .execute()
            )
            existing_rows = existing.data or []
            if existing_rows:
                users_map, votes_map = _load_related_maps(existing_rows)
                results.append(
                    ReportBulkItemResult(
                        client_report_id=client_report_id,
                        status="duplicate",
                        detail="Report already synced previously",
                        report=_to_report_read(existing_rows[0], users_map, votes_map),
                    )
                )
                continue

        try:
            report = _insert_report_for_user(report_payload, current_user)
            results.append(
                ReportBulkItemResult(
                    client_report_id=client_report_id,
                    status="created",
                    report=report,
                )
            )
        except HTTPException as exc:
            if exc.status_code == status.HTTP_409_CONFLICT:
                results.append(
                    ReportBulkItemResult(
                        client_report_id=client_report_id,
                        status="conflict",
                        detail=str(exc.detail),
                    )
                )
                continue
            raise

    return ReportBulkCreateResponse(results=results)


@router.post("/{report_id}/verify", response_model=ReportRead)
async def verify_report(
    report_id: UUID,
    _: dict[str, Any] = Depends(get_current_admin),
) -> ReportRead:
    report = _read_report_row(report_id)
    updated = _update_report_status(report_id, ReportStatus.verified)
    if report.get("status") != ReportStatus.verified.value:
        award_points(
            user_id=str(updated.user_id),
            delta=50,
            source_type="report_verified",
            source_id=str(report_id),
            reason="Report was verified",
        )
        evaluate_user_gamification(str(updated.user_id))
    return updated


@router.post("/{report_id}/reject", response_model=ReportRead)
async def reject_report(
    report_id: UUID,
    _: dict[str, Any] = Depends(get_current_admin),
) -> ReportRead:
    return _update_report_status(report_id, ReportStatus.rejected)


@router.post("/{report_id}/resolve", response_model=ReportRead)
async def resolve_report(
    report_id: UUID,
    _: dict[str, Any] = Depends(get_current_admin),
) -> ReportRead:
    return _update_report_status(report_id, ReportStatus.resolved)


@router.post("/{report_id}/reopen", response_model=ReportRead)
async def reopen_report(
    report_id: UUID,
    _: dict[str, Any] = Depends(get_current_admin),
) -> ReportRead:
    report = _read_report_row(report_id)
    next_status = ReportStatus.under_review if report.get("verification_count", 0) else ReportStatus.pending
    return _update_report_status(report_id, next_status)


@router.post("/{report_id}/vote", response_model=ReportRead)
async def vote_report(
    report_id: UUID,
    payload: ReportVoteRequest,
    current_user: dict[str, Any] = Depends(get_current_user),
) -> ReportRead:
    db = get_supabase_service_client()
    report_response = db.table("reports").select("*").eq("id", str(report_id)).limit(1).execute()
    report_rows = report_response.data or []
    if not report_rows:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report not found")

    report = report_rows[0]
    vote_response = (
        db.table("votes")
        .select("*")
        .eq("report_id", str(report_id))
        .eq("user_id", str(current_user["id"]))
        .limit(1)
        .execute()
    )
    vote_rows = vote_response.data or []

    previous_value = int(vote_rows[0]["value"]) if vote_rows else 0
    if vote_rows:
        db.table("votes").update({"value": payload.value}).eq("id", vote_rows[0]["id"]).execute()
    else:
        db.table("votes").insert(
            {
                "report_id": str(report_id),
                "user_id": str(current_user["id"]),
                "value": payload.value,
            }
        ).execute()

    delta = payload.value - previous_value
    verification_count = max(0, int(report.get("verification_count") or 0) + delta)
    status_value = report.get("status")
    if verification_count >= 3 and status_value == ReportStatus.pending.value:
        status_value = ReportStatus.verified.value

    updated = (
        db.table("reports")
        .update({"verification_count": verification_count, "status": status_value})
        .eq("id", str(report_id))
        .execute()
    )
    updated_rows = updated.data or []
    if not updated_rows:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to update vote state")

    if previous_value == 0:
        award_points(
            user_id=str(current_user["id"]),
            delta=5,
            source_type="vote_cast",
            source_id=str(report_id),
            reason="Verified a community report",
        )
        evaluate_user_gamification(str(current_user["id"]))

    users_map, votes_map = _load_related_maps(updated_rows)
    return _to_report_read(updated_rows[0], users_map, votes_map)


@router.patch("/{report_id}/status", response_model=ReportRead)
async def moderate_report_status(
    report_id: UUID,
    status_value: ReportStatus,
    _: dict[str, Any] = Depends(get_current_admin),
) -> ReportRead:
    if status_value not in (ReportStatus.verified, ReportStatus.rejected, ReportStatus.under_review):
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Invalid moderation status")

    report = _read_report_row(report_id)
    updated = _update_report_status(report_id, status_value)
    if (
        report.get("status") != ReportStatus.verified.value
        and status_value == ReportStatus.verified
    ):
        award_points(
            user_id=str(updated.user_id),
            delta=50,
            source_type="report_verified",
            source_id=str(report_id),
            reason="Report was verified",
        )
        evaluate_user_gamification(str(updated.user_id))
    return updated
