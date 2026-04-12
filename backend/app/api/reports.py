from datetime import datetime, timedelta, timezone
from math import asin, cos, radians, sin, sqrt
from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.api.deps import get_current_admin, get_current_user
from app.schemas.enums import ReportStatus
from app.schemas.report import NearbyReportRead, ReportCreate, ReportRead, ReportUpdate, ReportVoteRequest
from app.services.supabase_client import get_supabase_service_client


router = APIRouter(prefix="/reports", tags=["reports"])


def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    earth_radius_km = 6371.0
    d_lat = radians(lat2 - lat1)
    d_lon = radians(lon2 - lon1)
    a = sin(d_lat / 2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(d_lon / 2) ** 2
    c = 2 * asin(sqrt(a))
    return earth_radius_km * c


def _to_report_read(row: dict[str, Any]) -> ReportRead:
    return ReportRead(
        id=row["id"],
        user_id=row["user_id"],
        image_url=row["image_url"],
        damage_type=row["damage_type"],
        severity=row["severity"],
        severity_confidence=row.get("severity_confidence"),
        description=row.get("description"),
        latitude=float(row["latitude"]),
        longitude=float(row["longitude"]),
        status=row["status"],
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


@router.get("", response_model=list[ReportRead])
async def list_reports(
    status: ReportStatus | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
) -> list[ReportRead]:
    db = get_supabase_service_client()
    query = db.table("reports").select("*").order("created_at", desc=True)
    if status is None:
        query = query.in_("status", ["verified", "rejected"])
    else:
        query = query.eq("status", status.value)

    rows = query.range(offset, offset + limit - 1).execute().data or []
    return [_to_report_read(row) for row in rows]


@router.get("/nearby", response_model=list[NearbyReportRead])
async def list_nearby_reports(
    latitude: float,
    longitude: float,
    radius_km: float = Query(default=5.0, ge=0.1, le=100.0),
    limit: int = Query(default=50, ge=1, le=200),
) -> list[NearbyReportRead]:
    db = get_supabase_service_client()
    rows = (
        db.table("reports")
        .select("*")
        .in_("status", ["verified", "rejected"])
        .order("created_at", desc=True)
        .limit(1000)
        .execute()
        .data
        or []
    )

    nearby: list[tuple[dict[str, Any], float]] = []
    for row in rows:
        distance_km = _haversine_km(
            latitude,
            longitude,
            float(row["latitude"]),
            float(row["longitude"]),
        )
        if distance_km <= radius_km:
            nearby.append((row, distance_km * 1000.0))

    nearby.sort(key=lambda item: item[1])
    return [
        NearbyReportRead(**_to_report_read(row).model_dump(), distance_meters=distance_meters)
        for row, distance_meters in nearby[:limit]
    ]


@router.post("", response_model=ReportRead, status_code=status.HTTP_201_CREATED)
async def create_report(
    payload: ReportCreate,
    current_user: dict[str, Any] = Depends(get_current_user),
) -> ReportRead:
    db = get_supabase_service_client()

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

    created = (
        db.table("reports")
        .insert(
            {
                "user_id": current_user["id"],
                "image_url": payload.image_url,
                "damage_type": payload.damage_type.value,
                "severity": payload.severity.value,
                "description": payload.description,
                "latitude": payload.latitude,
                "longitude": payload.longitude,
            }
        )
        .execute()
    )
    rows = created.data or []
    if not rows:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to create report")

    return _to_report_read(rows[0])


@router.get("/{report_id}", response_model=ReportRead)
async def read_report(report_id: UUID) -> ReportRead:
    db = get_supabase_service_client()
    response = db.table("reports").select("*").eq("id", str(report_id)).limit(1).execute()
    rows = response.data or []
    if not rows:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report not found")

    report = rows[0]
    if report.get("status") == ReportStatus.pending.value:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Report is not public yet")
    return _to_report_read(report)


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
    return _to_report_read(updated_rows[0])


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

    return _to_report_read(updated_rows[0])


@router.patch("/{report_id}/status", response_model=ReportRead)
async def moderate_report_status(
    report_id: UUID,
    status_value: ReportStatus,
    _: dict[str, Any] = Depends(get_current_admin),
) -> ReportRead:
    if status_value not in (ReportStatus.verified, ReportStatus.rejected, ReportStatus.under_review):
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Invalid moderation status")

    db = get_supabase_service_client()
    updated = db.table("reports").update({"status": status_value.value}).eq("id", str(report_id)).execute()
    rows = updated.data or []
    if not rows:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report not found")
    return _to_report_read(rows[0])
