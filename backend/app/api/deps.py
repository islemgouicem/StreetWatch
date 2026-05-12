import secrets
from typing import Any

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

from app.services.supabase_client import get_supabase_anon_client, get_supabase_service_client


oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


def _username_from_subject(subject: str) -> str:
    return f"user_{subject.replace('-', '')[:8]}"


def _username_from_identity(subject: str, email: str | None, full_name: str | None) -> str:
    if full_name:
        cleaned = "".join(ch.lower() if ch.isalnum() else "_" for ch in full_name).strip("_")
        cleaned = "_".join(part for part in cleaned.split("_") if part)
        if cleaned:
            return cleaned[:30]
    if email and "@" in email:
        local = email.split("@", 1)[0]
        cleaned = "".join(ch.lower() if ch.isalnum() else "_" for ch in local).strip("_")
        cleaned = "_".join(part for part in cleaned.split("_") if part)
        if cleaned:
            return cleaned[:30]
    return _username_from_subject(subject)


def _row_to_current_user(user_row: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": user_row.get("id"),
        "email": user_row.get("email"),
        "username": user_row.get("username"),
        "full_name": user_row.get("full_name"),
        "avatar_url": user_row.get("avatar_url"),
        "image_profile": user_row.get("image_profile"),
        "points": int(user_row.get("points") or 0),
        "is_active": bool(user_row.get("is_active", True)),
        "is_admin": bool(user_row.get("is_admin", False)),
        "created_at": user_row.get("created_at"),
        "updated_at": user_row.get("updated_at"),
    }


async def get_current_user(
    token: str = Depends(oauth2_scheme),
) -> dict[str, Any]:
    subject: str | None = None
    user_email: str | None = None
    user_full_name: str | None = None

    try:
        supabase_user_response = get_supabase_anon_client().auth.get_user(token)
        supabase_user = supabase_user_response.user
        if supabase_user is not None:
            subject = str(getattr(supabase_user, "id", "") or "")
            user_email = getattr(supabase_user, "email", None)
            user_metadata = (
                getattr(supabase_user, "user_metadata", None)
                or getattr(supabase_user, "raw_user_meta_data", None)
                or {}
            )
            user_full_name = user_metadata.get("full_name") if isinstance(user_metadata, dict) else None
    except Exception as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid authentication token") from exc

    if not subject:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid authentication token")

    db = get_supabase_service_client()
    existing_user_response = db.table("users").select("*").eq("id", subject).limit(1).execute()
    existing_user_rows = existing_user_response.data or []

    if not existing_user_rows:
        username_candidate = _username_from_identity(subject, user_email, user_full_name)
        username_exists_response = (
            db.table("users").select("id").eq("username", username_candidate).limit(1).execute()
        )
        if username_exists_response.data:
            username_candidate = f"{username_candidate}_{secrets.token_hex(2)}"

        new_user_payload = {
            "id": subject,
            "email": user_email or f"{username_candidate}@streetwatch.local",
            "username": username_candidate,
            "full_name": user_full_name,
            "is_active": True,
        }
        inserted = db.table("users").insert(new_user_payload).execute()
        created_rows = inserted.data or []
        if not created_rows:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to provision user")
        user_row = created_rows[0]
    else:
        user_row = existing_user_rows[0]

        # Keep app users row synchronized with Supabase auth identity data.
        update_payload: dict[str, Any] = {}

        if user_email:
            current_email = str(user_row.get("email") or "")
            if not current_email or current_email.endswith("@streetwatch.local") or current_email != user_email:
                update_payload["email"] = user_email

        if user_full_name and not user_row.get("full_name"):
            update_payload["full_name"] = user_full_name

        if not user_row.get("username"):
            username_candidate = _username_from_identity(subject, user_email, user_full_name)
            username_exists_response = (
                db.table("users").select("id").eq("username", username_candidate).neq("id", subject).limit(1).execute()
            )
            if username_exists_response.data:
                username_candidate = f"{username_candidate}_{secrets.token_hex(2)}"
            update_payload["username"] = username_candidate

        if update_payload:
            updated = db.table("users").update(update_payload).eq("id", subject).execute()
            updated_rows = updated.data or []
            if updated_rows:
                user_row = updated_rows[0]

    if not bool(user_row.get("is_active", True)):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found or inactive")

    return _row_to_current_user(user_row)


async def get_current_admin(current_user: dict[str, Any] = Depends(get_current_user)) -> dict[str, Any]:
    if not bool(current_user.get("is_admin", False)):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin privileges required")
    return current_user
