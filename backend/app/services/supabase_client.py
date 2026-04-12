from functools import lru_cache

from supabase import Client, create_client

from app.core.config import get_settings


def _require(value: str, name: str) -> str:
    if not value:
        raise RuntimeError(f"Missing required setting: {name}")
    return value


@lru_cache(maxsize=1)
def get_supabase_anon_client() -> Client:
    settings = get_settings()
    return create_client(
        _require(settings.supabase_url, "SUPABASE_URL"),
        _require(settings.supabase_anon_key, "SUPABASE_ANON_KEY"),
    )


@lru_cache(maxsize=1)
def get_supabase_service_client() -> Client:
    settings = get_settings()
    return create_client(
        _require(settings.supabase_url, "SUPABASE_URL"),
        _require(settings.supabase_service_role_key, "SUPABASE_SERVICE_ROLE_KEY"),
    )