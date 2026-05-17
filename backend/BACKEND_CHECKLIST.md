# StreetWatch Backend Checklist

Implementation-ready backend plan based on the current FastAPI code, Supabase/PostGIS schema, and the mobile/web clients in this repository.

## Goals

- Freeze the API contract before building more screens against it.
- Prioritize MVP backend work that unblocks the mobile app and web map.
- Separate already-implemented endpoints from missing ones.
- Keep nice-to-have work visible without mixing it into the critical path.

## Current Backend Snapshot

Source reviewed:

- `backend/app/api`
- `backend/app/schemas`
- `backend/sql`
- `mobile_app/lib/services/api_service.dart`
- `web_map/src`

### Already Implemented

#### Health and app

- `GET /`
- `GET /health`

#### Auth

- `GET /api/v1/auth/me`

Notes:

- Authentication relies on Supabase JWT validation in FastAPI.
- App users are auto-provisioned into `public.users` on first authenticated request.

#### Users

- `GET /api/v1/users/me`
- `PATCH /api/v1/users/me`
- `GET /api/v1/users/{user_id}`
- `GET /api/v1/users/{user_id}/stats`

#### Reports

- `GET /api/v1/reports`
- `GET /api/v1/reports/nearby`
- `POST /api/v1/reports`
- `GET /api/v1/reports/{report_id}`
- `PATCH /api/v1/reports/{report_id}`
- `POST /api/v1/reports/{report_id}/vote`
- `PATCH /api/v1/reports/{report_id}/status`

#### Leaderboard

- `GET /api/v1/leaderboard`

## Contract Gaps To Fix First

These are the highest-risk mismatches because the clients already assume different contracts.

### Reports contract mismatch

- Mobile sends `page` and `page_size`, backend uses `limit` and `offset`.
- Mobile optionally sends `username`, backend does not support it.
- Mobile report model expects `user_name`, `user_points`, `upvotes`, `downvotes`, backend does not return them.
- Backend exposes `verification_count`, while the mobile app is modeled around vote totals.

Decision for MVP:

- Standardize on `limit` and `offset` in the backend.
- Optionally support `page` and `page_size` temporarily as compatibility aliases.
- Enrich report responses with reporter and vote summary fields.

### Leaderboard contract mismatch

- Backend returns `user_id`.
- Mobile leaderboard model currently reads `id`.

Decision for MVP:

- Backend should return both `user_id` and `id` temporarily, or the mobile app should be updated immediately after contract freeze.

### Preferences endpoints missing

The mobile app already calls these endpoints, but they do not exist:

- `PATCH /api/v1/users/me/preferences/email`
- `PATCH /api/v1/users/me/preferences/security`
- `PATCH /api/v1/users/me/preferences/appearance`
- `PATCH /api/v1/users/me/preferences/language`

## MVP Backlog

These are the backend tasks that should be implemented before badges, missions, or advanced admin tooling.

### 1. Report listing and map filtering

Status: Not complete

Why it matters:

- Unblocks the public web map.
- Unblocks mobile browsing/history screens.
- Defines the stable contract used by both clients.

#### Endpoints

- `GET /api/v1/reports`
  - Add filters:
    - `status`
    - `damage_type`
    - `severity`
    - `date_from`
    - `date_to`
    - `user_id`
    - `bbox`
  - Add stable pagination:
    - `limit`
    - `offset`
  - Optional compatibility:
    - `page`
    - `page_size`

- `GET /api/v1/reports/nearby`
  - Keep current endpoint.
  - Re-implement using PostGIS instead of Python-side distance filtering.
  - Return `distance_meters`.

- `GET /api/v1/reports/geojson`
  - Return public reports as a GeoJSON `FeatureCollection`.
  - Support same core filters as `GET /reports`.

- `GET /api/v1/reports/stats`
  - Return counts for:
    - total reports
    - pending
    - verified
    - rejected
    - resolved
    - by damage type
    - by severity

#### Response additions for report objects

Add these fields to the shared report response used by list/read/nearby/create/update:

- `user_name`
- `user_avatar_url`
- `user_points`
- `upvotes`
- `downvotes`
- `verification_count`

### 2. My reports and report history

Status: Missing

Why it matters:

- The mobile app needs a clean source for the user’s own submissions.
- Users need to see pending, verified, rejected, and resolved reports separately.

#### Endpoints

- `GET /api/v1/users/me/reports`
  - Filters:
    - `status`
    - `limit`
    - `offset`

- `GET /api/v1/users/{user_id}/reports`
  - Public-facing or authenticated-only depending on product decision.
  - Default to public reports only unless viewing self/admin.

- `DELETE /api/v1/reports/{report_id}`
  - Allow deleting own pending report.
  - Admin may delete any report if needed.

- `GET /api/v1/reports/{report_id}/activity`
  - Optional for MVP, but useful.
  - Can include:
    - votes summary
    - moderation status changes
    - created/updated timestamps

### 3. Preferences/settings backend

Status: Missing

Why it matters:

- The mobile settings screens already call these endpoints.
- This is a clean, bounded backend task.

#### Data model

Add a `user_preferences` table keyed by `user_id`.

Suggested groups:

- email preferences
- security preferences
- appearance preferences
- language preference

#### Endpoints

- `GET /api/v1/users/me/preferences`
- `PATCH /api/v1/users/me/preferences/email`
- `PATCH /api/v1/users/me/preferences/security`
- `PATCH /api/v1/users/me/preferences/appearance`
- `PATCH /api/v1/users/me/preferences/language`

Suggested fields:

- Email:
  - `incident_digest`
  - `milestone_alerts`
  - `product_updates`

- Security:
  - `two_factor_enabled`
  - `biometric_lock`
  - `location_masking`

- Appearance:
  - `theme`
  - `dark_mode`

- Language:
  - `language`

### 4. Public web map backend contract

Status: Missing as a finalized contract

Why it matters:

- The web map still uses mock data.
- A stable map contract avoids frontend rework.

#### Endpoint options

Preferred:

- Reuse:
  - `GET /api/v1/reports`
  - `GET /api/v1/reports/geojson`
  - `GET /api/v1/reports/stats`

Alternative:

- Add public namespace:
  - `GET /api/v1/public/reports`
  - `GET /api/v1/public/reports/geojson`
  - `GET /api/v1/public/stats`

Recommendation:

- Reuse `/reports` for MVP.
- Add a `public` namespace only if access rules diverge later.

### 5. Report lifecycle completion

Status: Partial

Why it matters:

- Schema already includes `resolved`.
- The system should support a full lifecycle from submission to closure.

#### Endpoints

- `POST /api/v1/admin/reports/{report_id}/verify`
- `POST /api/v1/admin/reports/{report_id}/reject`
- `POST /api/v1/admin/reports/{report_id}/resolve`
- `POST /api/v1/admin/reports/{report_id}/reopen`

Recommendation:

- For MVP, you can keep the generic `PATCH /reports/{id}/status`.
- Add these semantic admin endpoints only if they help frontend clarity.

### 6. Offline sync support

Status: Missing

Why it matters:

- Offline capability is one of the project deliverables.
- Sync needs idempotency to avoid duplicate reports.

#### Requirements

- Each offline-created report should carry a client-generated sync key.
- Backend should accept retries safely.

#### Endpoints

- `POST /api/v1/reports/bulk`
  - Accept array of pending reports from local storage.
  - Return per-item success/error results.

- `POST /api/v1/reports/sync`
  - Alternative single sync endpoint if you prefer one entry point.

- `GET /api/v1/reports/sync/status/{client_report_id}`
  - Optional.
  - Useful only if background sync becomes more complex.

Recommendation:

- `POST /api/v1/reports/bulk` is enough for MVP.

## Nice-To-Have Backlog

These features are valuable, but they should come after the MVP contract is stable and the map/report flow works end to end.

### 7. Badges

Status: Data model exists, API missing

Existing schema:

- `badges`
- `user_badges`

#### Endpoints

- `GET /api/v1/badges`
- `GET /api/v1/badges/{badge_id}`
- `GET /api/v1/users/me/badges`
- `GET /api/v1/users/{user_id}/badges`
- `POST /api/v1/admin/badges`
- `PATCH /api/v1/admin/badges/{badge_id}`
- `POST /api/v1/admin/users/{user_id}/badges/{badge_id}`

### 8. Points history and reward accounting

Status: Partial data only

Current state:

- `users.points` exists.
- There is no transaction log explaining how points change.

Recommended schema addition:

- `point_transactions`

Suggested columns:

- `id`
- `user_id`
- `source_type`
- `source_id`
- `delta`
- `reason`
- `created_at`

#### Endpoints

- `GET /api/v1/users/me/points-history`
- `GET /api/v1/users/{user_id}/points-history`
- `POST /api/v1/admin/points/award`
- `POST /api/v1/admin/points/recalculate`

### 9. Advanced moderation

Status: Basic only

Current state:

- Admin can patch a report status.

#### Endpoints

- `GET /api/v1/admin/reports/pending`
- `GET /api/v1/admin/reports/under-review`
- `POST /api/v1/admin/reports/bulk-status`
- `GET /api/v1/admin/users`
- `PATCH /api/v1/admin/users/{user_id}`

### 10. Notifications backend

Status: Missing

Why it matters:

- The app has a notifications screen, but no backend support.

#### Endpoints

- `GET /api/v1/notifications`
- `PATCH /api/v1/notifications/{notification_id}/read`
- `PATCH /api/v1/notifications/read-all`

Recommendation:

- Do not build this until real notification delivery rules exist.

## Recommended Implementation Order

### Phase A: Contract freeze and low-risk fixes

- [ ] Decide and document the canonical pagination contract.
- [ ] Decide whether to enrich report responses or simplify the mobile models.
- [ ] Decide whether leaderboard returns `user_id` only or `id` plus `user_id`.
- [ ] Add/adjust schemas for shared response models.

### Phase B: MVP report and map APIs

- [ ] Upgrade `GET /reports` filtering.
- [ ] Upgrade `GET /reports/nearby` to use PostGIS.
- [ ] Add `GET /reports/geojson`.
- [ ] Add `GET /reports/stats`.
- [ ] Add `GET /users/me/reports`.
- [ ] Add `DELETE /reports/{report_id}`.

### Phase C: Settings and preferences

- [ ] Add `user_preferences` schema/table.
- [ ] Add `GET /users/me/preferences`.
- [ ] Add the four `PATCH /users/me/preferences/...` endpoints.

### Phase D: Sync support

- [ ] Add bulk report sync endpoint.
- [ ] Add idempotency key strategy.
- [ ] Add conflict/duplicate response rules.

### Phase E: Gamification

- [ ] Add badges APIs.
- [ ] Add points transaction tracking.
- [ ] Connect leaderboard data to richer reward logic.

### Phase F: Admin and polish

- [ ] Add moderation queue endpoints.
- [ ] Add optional notifications backend.
- [ ] Add integration tests for the core flows.

## Suggested API Shapes To Freeze

These are the minimum shared response shapes worth standardizing now.

### Report response

```json
{
  "id": "uuid",
  "user_id": "uuid",
  "user_name": "string",
  "user_avatar_url": "string | null",
  "user_points": 0,
  "image_url": "string",
  "damage_type": "pothole",
  "severity": "medium",
  "severity_confidence": 0.82,
  "description": "string | null",
  "latitude": 36.75,
  "longitude": 3.05,
  "status": "verified",
  "upvotes": 10,
  "downvotes": 2,
  "verification_count": 8,
  "distance_meters": 134.2,
  "created_at": "2026-04-15T12:00:00Z",
  "updated_at": "2026-04-15T12:15:00Z"
}
```

### Leaderboard entry response

```json
{
  "rank": 1,
  "id": "uuid",
  "user_id": "uuid",
  "username": "string",
  "avatar_url": "string | null",
  "points": 120,
  "reports_count": 18,
  "verified_reports": 11,
  "votes_cast": 32
}
```

### User preferences response

```json
{
  "user_id": "uuid",
  "email": {
    "incident_digest": true,
    "milestone_alerts": true,
    "product_updates": false
  },
  "security": {
    "two_factor_enabled": false,
    "biometric_lock": true,
    "location_masking": false
  },
  "appearance": {
    "theme": "streetwatch",
    "dark_mode": false
  },
  "language": {
    "language": "en"
  }
}
```

## Definition Of MVP Done

Backend MVP is done when all of the following are true:

- Mobile app can authenticate and fetch current user.
- Mobile app can create reports, list nearby reports, and list the user’s own reports.
- Public/web clients can filter reports by type, severity, date, and area.
- Web map can render real backend data and summary statistics.
- Preferences endpoints used by the mobile app exist and persist data.
- Offline-created reports can be synced safely without accidental duplicates.
- The API contract is documented and consistent across backend, mobile, and web.

## Recommended Next Implementation Task

Start with report/map contract completion:

1. Enrich the shared report response model.
2. Upgrade `GET /api/v1/reports` filters and pagination compatibility.
3. Add `GET /api/v1/reports/stats`.
4. Add `GET /api/v1/users/me/reports`.

This gives the biggest unblock for both the mobile app and web map with the least schema churn.
