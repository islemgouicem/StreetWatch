from typing import Any

from fastapi import APIRouter, Depends

from app.api.deps import get_current_user
from app.schemas.user import UserRead


router = APIRouter(prefix="/auth", tags=["auth"])


@router.get("/me", response_model=UserRead)
async def read_me(current_user: dict[str, Any] = Depends(get_current_user)) -> UserRead:
	return UserRead(**current_user)
