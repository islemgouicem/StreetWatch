# StreetWatch Development Order

Use this checklist to build the project in the correct order and avoid rework.

## Phase 1: Project Foundation

- [ ] Confirm scope, roles, and MVP features with the team.
- [ ] Finalize the folder structure and repository conventions.
- [ ] Define API contracts, data entities, and naming standards.
- [ ] Choose the backend stack details and deployment approach.
- [ ] Agree on the report lifecycle: capture -> classify -> save offline -> sync -> map display.
- [ ] Create sample data, mock APIs, and UI wireframes for shared reference.

## Phase 2: Backend First

- [ ] Design the PostGIS schema for users, reports, badges, and leaderboard scores.
- [ ] Build the FastAPI project skeleton.
- [ ] Implement authentication and user profile endpoints.
- [ ] Implement report creation, report listing, and report filtering endpoints.
- [ ] Implement leaderboard and gamification endpoints.
- [ ] Add validation, error handling, and API documentation.
- [ ] Dockerize the backend and database.

Why this comes first:

- The mobile app and web map both depend on stable API contracts.
- The database model must be fixed before AI and sync logic are wired in.

## Phase 3: Data and AI Pipeline

- [ ] Prepare the RDD2022 dataset structure and labeling strategy.
- [ ] Build the preprocessing and augmentation pipeline.
- [ ] Implement the training model architecture.
- [ ] Train a baseline model and record metrics.
- [ ] Evaluate the model and choose the final checkpoint.
- [ ] Convert the final model to TensorFlow Lite.
- [ ] Test inference speed and accuracy on mobile-sized inputs.

Why this comes before mobile integration:

- The app should integrate a stable model, not a moving target.
- The severity and damage labels must match the backend data model.

## Phase 4: Mobile App Core

- [ ] Build app navigation and state structure.
- [ ] Implement authentication screens and session handling.
- [ ] Implement camera capture, gallery selection, and location access.
- [ ] Integrate on-device damage classification with TFLite.
- [ ] Implement severity scoring logic.
- [ ] Add offline storage for pending reports.
- [ ] Add background/manual sync to backend.
- [ ] Build report history and profile screens.

Dependency rule:

- Do not design final UI flows before API response shapes and model labels are agreed.
- Do not implement sync before backend endpoints are stable.

## Phase 5: Gamification

- [ ] Define points rules for valid reports, classification confidence, and consistency.
- [ ] Define badge milestones.
- [ ] Implement leaderboard ranking logic.
- [ ] Connect mobile UI to gamification endpoints.
- [ ] Add profile progress and achievement views.

Dependency rule:

- Gamification depends on report validation and user identity being stable first.

## Phase 6: Web Map

- [ ] Create the web map project structure and build tooling.
- [ ] Render reported issues on a map using backend data.
- [ ] Add filters by damage type, severity, and date.
- [ ] Add summary statistics and counts.
- [ ] Add clustering or density handling if the map becomes crowded.
- [ ] Verify the map works on desktop and mobile browsers.

Dependency rule:

- The web map should consume the same backend contracts as the mobile app.
- Build this after backend report endpoints are stable.

## Phase 7: Integration and Quality

- [ ] Test end-to-end flow from photo capture to public map visibility.
- [ ] Test offline behavior and resync behavior.
- [ ] Test invalid input, API failures, and network loss.
- [ ] Add unit tests for core logic.
- [ ] Add integration tests for backend endpoints.
- [ ] Add widget tests for key mobile screens.
- [ ] Review accessibility, responsiveness, and UI consistency.

## Phase 8: Delivery and Polish

- [ ] Prepare deployment instructions.
- [ ] Write the documentation set: SRS, architecture, API docs, and gamification rules.
- [ ] Prepare demo script and presentation slides.
- [ ] Record screenshots and sample outputs.
- [ ] Freeze changes before submission.

## Recommended Team Flow

- Backend team starts first and defines the data contracts.
- AI team works in parallel after labels and preprocessing rules are approved.
- Mobile team starts with navigation and mock data, then plugs into real APIs.
- Web map team starts after report schema and filters are defined.
- Everyone integrates only after contracts are stable.

## Non-Negotiable Rule

- [ ] Never build a feature UI against a changing API contract.
- [ ] Never finalize database fields before agreeing on report and leaderboard logic.
- [ ] Never start polishing screens before the data flow works end to end.
