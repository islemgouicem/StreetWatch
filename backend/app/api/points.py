from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, Query

from app.api.deps import get_current_admin, get_current_user
from app.schemas.points import PointAwardRequest, PointTransactionRead
from app.services.gamification import evaluate_user_gamification
from app.services.points import award_points
from app.services.supabase_client import get_supabase_service_client


router = APIRouter(prefix="/points", tags=["points"])


def _read_transactions_for_user(user_id: str, limit: int, offset: int) -> list[PointTransactionRead]:
    rows = (
        get_supabase_service_client()
        .table("point_transactions")
        .select("*")
        .eq("user_id", user_id)
        .order("created_at", desc=True)
        .range(offset, offset + limit - 1)
        .execute()
        .data
        or []
    )
    return [PointTransactionRead(**row) for row in rows]


@router.get("/me/history", response_model=list[PointTransactionRead])
async def read_my_points_history(
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    current_user: dict[str, Any] = Depends(get_current_user),
) -> list[PointTransactionRead]:
    return _read_transactions_for_user(str(current_user["id"]), limit, offset)


@router.get("/users/{user_id}/history", response_model=list[PointTransactionRead])
async def read_user_points_history(
    user_id: UUID,
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    _: dict[str, Any] = Depends(get_current_user),
) -> list[PointTransactionRead]:
    return _read_transactions_for_user(str(user_id), limit, offset)


@router.post("/award", response_model=PointTransactionRead)
async def award_points_to_user(
    payload: PointAwardRequest,
    _: dict[str, Any] = Depends(get_current_admin),
) -> PointTransactionRead:
    row = award_points(
        user_id=str(payload.user_id),
        delta=payload.delta,
        source_type=payload.source_type,
        source_id=payload.source_id,
        reason=payload.reason,
    )
    evaluate_user_gamification(str(payload.user_id))
    return PointTransactionRead(**row)
