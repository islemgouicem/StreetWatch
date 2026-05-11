from pathlib import Path
import sys

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

if __package__ in {None, ""}:
	sys.path.append(str(Path(__file__).resolve().parents[1]))

from app.api.router import api_router
from app.core.config import get_settings


settings = get_settings()

app = FastAPI(
	title=settings.app_name,
	version="0.1.0",
	debug=settings.debug,
	openapi_url=f"{settings.api_v1_prefix}/openapi.json",
	docs_url="/docs",
	redoc_url="/redoc",
)

app.add_middleware(
	CORSMiddleware,
	allow_origins=settings.cors_origins_list,
	allow_credentials=True,
	allow_methods=["*"],
	allow_headers=["*"],
	allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
)

app.include_router(api_router, prefix=settings.api_v1_prefix)


@app.get("/")
async def root() -> dict[str, str]:
	return {"service": settings.app_name, "version": "0.1.0", "status": "running"}


@app.get("/health")
async def health() -> dict[str, str]:
	return {"status": "ok"}


if __name__ == "__main__":
	import uvicorn
	uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
