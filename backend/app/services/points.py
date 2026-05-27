from typing import Any

from fastapi import HTTPException, status

from app.services.supabase_client import get_supabase_service_client


def award_points(
    *,
    user_id: str,
    delta: int,
    source_type: str,
    source_id: str | None = None,
    reason: str | None = None,
) -> dict[str, Any]:
    db = get_supabase_service_client()

    user_response = db.table("users").select("id,points").eq("id", user_id).limit(1).execute()
    user_rows = user_response.data or []
    if not user_rows:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    current_points = int(user_rows[0].get("points") or 0)
    updated_points = current_points + delta

    updated_user = db.table("users").update({"points": updated_points}).eq("id", user_id).execute()
    updated_rows = updated_user.data or []
    if not updated_rows:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to update user points")

    created_transaction = (
        db.table("point_transactions")
        .insert(
            {
                "user_id": user_id,
                "source_type": source_type,
                "source_id": source_id,
                "delta": delta,
                "reason": reason,
            }
        )
        .execute()
    )
    transaction_rows = created_transaction.data or []
    if not transaction_rows:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to record point transaction",
        )

    return transaction_rows[0]