from fastapi import APIRouter

from app.api.auth import router as auth_router
from app.api.badges import router as badges_router
from app.api.leaderboard import router as leaderboard_router
from app.api.points import router as points_router
from app.api.reports import router as reports_router
from app.api.users import router as users_router


api_router = APIRouter()
api_router.include_router(auth_router)
api_router.include_router(badges_router)
api_router.include_router(points_router)
api_router.include_router(users_router)
api_router.include_router(reports_router)
api_router.include_router(leaderboard_router)
