# StreetWatch

Road damage and infrastructure reporting platform for Flutter, FastAPI, PostGIS, TensorFlow Lite, and a public web map.

## Docker

The root compose stack runs the active services:

- `backend`: FastAPI API on `http://localhost:8000`
- `web_map`: production React build served by Nginx on `http://localhost:3000`

Before building, keep backend secrets in `backend/.env` and copy `.env.example` to `.env` at the repo root for the public `VITE_*` web build variables.

```bash
docker compose up --build
```
