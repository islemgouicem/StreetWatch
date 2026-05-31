# StreetWatch
StreetWatch is a road-damage reporting platform with three main client surfaces and one shared backend:

- A Flutter mobile app for citizens to capture and submit damage reports.
- A FastAPI backend that validates users, stores reports, and serves leaderboard and moderation APIs.
- A React + Vite web map for admins and public reporting views.
- An optional AI model workspace for training and exporting the road-damage detector.

## Repository Architecture

```text
StreetWatch/
├── backend/                # FastAPI API, Supabase integration, SQL scripts, Dockerfile
├── mobile_app/             # Flutter mobile app
├── web_map/                # React + Vite web dashboard / map
├── ai_model/               # Model training / export workspace
├── docs/                   # Architecture, diagrams, API docs, SRS
├── scripts/                # Helper shell scripts
├── docker-compose.yml      # Root Docker stack for backend + web map
├── .env.example            # Root Vite env template for Docker/web builds
└── README.md               # This guide
```

Getting Started — How to use the system

- Install the Android APK on a device (see "Install the APK" below).
- Open the app and create an account to submit reports.
- Use the web map to view, search and moderate reports from a browser.

Quick overview

- Install the APK: build or download `StreetWatch.apk` and install on your Android device.
- Login: open the app, tap "Sign In" and enter your credentials (or sign up).
- Navigate: main screens include Home (feed), Camera (reporting), My Reports, Profile, and Leaderboard.
- Submit a report: use the Camera screen to capture or upload an image, add details, then submit.
- Check the web map: open the `web_map` deployment to view all reports on an interactive map.

Login and basic navigation

- Open the app and follow the onboarding screens.
- Use the Sign In screen to authenticate; if you do not have an account use the Sign Up flow.
- Home shows recent activity; Camera / Report lets you capture a photo and provide details; My Reports lists your submissions.

Submit a report

1. Open the Camera (Report) screen.
2. Capture a photo or pick an existing image.
3. Fill in metadata: description, and location.
4. Review and tap Submit. The app will upload the image and create the report via the backend API.

View reports on the Web Map

- Open the `web_map` app in a browser (locally at `http://localhost:3000` when running with Docker/Vite, or the deployed URL).
- Use the map to browse reports, view details, filter by status, and (if you have permissions) moderate or update reports.

Troubleshooting & tips

- If the mobile app cannot reach the backend, ensure the `API_BASE_URL` is set correctly.
- For the web map, check `web_map/.env` or the environment variable `VITE_API_BASE_URL`.
- Generated Flutter plugin files may show line-ending warnings on Windows; these are safe to stash or ignore.

---

## Components At A Glance

- `backend`: FastAPI app on port `8000`, deployed on render
- `mobile_app`: Flutter app
- `web_map`: React app built by Vite, served in Docker through Nginx on port `3000` depolyed on vercel
- `ai_model`: training/export workspace for the detection model and TFLite artifacts

## Prerequisites

Install these before running anything locally:

- Git
- Docker Desktop
- Python 3.10+ with `pip`
- Node.js 20+ with `npm`
- Flutter stable SDK with Android toolchain
- Android Studio or an Android emulator/device
- A Supabase project with:
  - Project URL
  - anon/public key
  - service role key

## Configuration Files

The project uses these env templates:

- [`.env.example`](.env.example) for root-level web build variables used by `docker-compose.yml`
- [`backend/.env.example`](backend/.env.example) for backend runtime variables
- [`web_map/.env.example`](web_map/.env.example) for local web-map development

Fill them with your own values before running locally.

## Quick Start With Docker

Use Docker if you want the backend and web map up together with minimal manual setup.

1. Copy the root env template to `.env` and fill the public frontend variables.
2. Copy `backend/.env.example` to `backend/.env` and fill the backend secrets.
3. Start the stack:

```powershell
docker compose up --build
```

4. Open the services:
   - Backend: `http://localhost:8000`
   - Backend docs: `http://localhost:8000/docs`
   - Web map: `http://localhost:3000`

The Docker stack is defined in [docker-compose.yml](docker-compose.yml).

## Local Setup Step By Step

### 1) Clone the repository

```powershell
git clone https://github.com/islemgouicem/StreetWatch.git
cd StreetWatch
```

### 2) Configure environment variables

Create the root `.env` file from [`.env.example`](.env.example) and set the web build variables:

```dotenv
VITE_API_BASE_URL=http://localhost:8000/api/v1
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-public-anon-key
```

Create [backend/.env](backend/.env) from [backend/.env.example](backend/.env.example) and fill in at least:

```dotenv
APP_NAME=StreetWatch API
API_V1_PREFIX=/api/v1
ENVIRONMENT=development
DEBUG=false
CORS_ORIGINS=http://localhost:3000,http://localhost:8000
SECRET_KEY=change-this-in-production
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-public-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

## Backend Setup

1. Open the backend folder.

```powershell
cd backend
```

2. Create and activate a Python virtual environment.

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

3. Install dependencies.

```powershell
pip install -r requirements.txt
```

4. Make sure `backend/.env` exists and contains your Supabase and CORS settings.

5. Start the API.

```powershell
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```


Important backend routes:

- `GET /` returns the service name and status
- `GET /health` returns `ok`
- `GET /docs` opens OpenAPI docs

## Flutter Mobile App Setup

1. Open the mobile app folder.

```powershell
cd mobile_app
```

2. Fetch dependencies.

```powershell
flutter pub get
```

3. Run the app on a device or emulator.

```powershell
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1 --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-public-anon-key
```

4. If you are testing on an Android emulator, replace `localhost` with `10.0.2.2` for the backend URL.

5. Build a release APK when you want to share it.

```powershell
flutter build apk --release --target-platform android-arm64
```

The mobile app bootstraps Supabase in [mobile_app/lib/main.dart](mobile_app/lib/main.dart) and expects:

- `API_BASE_URL`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

## Web Map Setup

1. Open the web app folder.

```powershell
cd web_map
```

2. Install dependencies.

```powershell
npm install
```

3. Create a local `.env` file if you want to run it outside Docker and provide:

```dotenv
VITE_API_BASE_URL=http://localhost:8000/api/v1
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-public-anon-key
```

4. Start the dev server.

```powershell
npm run dev
```

5. Build the production web bundle.

```powershell
npm run build
```

6. Preview the production build locally.

```powershell
npm run preview
```

## Optional AI Model Workspace

The `ai_model` workspace contains the road-damage model training, evaluation, and export code. Use it when you need to retrain or re-export the detector for the mobile app.

Typical workflow:

1. Open the AI workspace.

```powershell
cd ai_model
```

2. Create a virtual environment and install the model requirements.

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

3. Prepare the dataset using the RDD2022 conversion script and your image/XML folders.

```powershell
python data\prepare_rdd2022.py --image_dir <path-to-images> --ann_dir <path-to-xmls> --output_dir data\rdd2022
```

4. Train the model.

```powershell
python training\train.py
```

5. Evaluate or export the model from the same workspace if you are using the current detector pipeline, for example:

```powershell
python efficentNet_and_ssdlite\evaluate.py
python efficentNet_and_ssdlite\export\export_pipeline.py
```

## Default Ports

- Backend API: `8000`
- Web map: `3000`
- Flutter mobile app: device/emulator port; it calls the backend via `API_BASE_URL`

## Common Troubleshooting

- If the mobile app cannot log in, confirm `SUPABASE_URL` and `SUPABASE_ANON_KEY` are from the same Supabase project.
- If the web map fails on Vercel, make sure `VITE_API_BASE_URL`, `VITE_SUPABASE_URL`, and `VITE_SUPABASE_ANON_KEY` are set in the production environment.
- If Docker builds fail, confirm that the root `.env` and `backend/.env` files exist.
- If Android build output is missing, use `flutter build apk --release --target-platform android-arm64` after running `flutter pub get`.

## Notes For Reviewers

- The backend source is in `backend/` and is served with FastAPI + Uvicorn.
- The Flutter app is the primary mobile client.
- The web map is a separate React app and is not part of the Flutter build.
- The launcher icon and splash branding use the StreetWatch logo asset.
