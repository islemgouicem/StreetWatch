from app.schemas.auth import LoginRequest, RegisterRequest, TokenResponse
from app.schemas.badge import BadgeRead, UserBadgeRead
from app.schemas.leaderboard import LeaderboardEntry
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
from app.schemas.report import (
    NearbyReportRead,
    ReportCreate,
    ReportRead,
    ReportStatsCount,
    ReportStatsRead,
    ReportUpdate,
    ReportVoteRequest,
)
from app.schemas.user import UserCreate, UserRead, UserStats, UserUpdate

__all__ = [
    "LoginRequest",
    "RegisterRequest",
    "TokenResponse",
    "BadgeRead",
    "UserBadgeRead",
    "LeaderboardEntry",
    "AppearancePreferences",
    "AppearancePreferencesUpdate",
    "EmailPreferences",
    "EmailPreferencesUpdate",
    "LanguagePreferences",
    "LanguagePreferencesUpdate",
    "NearbyReportRead",
    "ReportCreate",
    "ReportRead",
    "ReportStatsCount",
    "ReportStatsRead",
    "ReportUpdate",
    "ReportVoteRequest",
    "SecurityPreferences",
    "SecurityPreferencesUpdate",
    "UserPreferencesRead",
    "UserCreate",
    "UserRead",
    "UserStats",
    "UserUpdate",
]
