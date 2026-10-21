# AI plan generator — Flutter frontend spec

Backend spec: `mobileappbackend1/docs/ai-plan-generator.md`. Do a frontend phase only after the matching backend phase is done and the endpoints work in Swagger.

## Existing state (checked)
- `features/register/athlete_survey_page.dart` already collects weight, goal, sport history, injuries, gym frequency, equipment — but `_finish()` only writes JSON to **local secure storage**; it never reaches the backend. It also shares the class name `AthleteSurveyPage` with `features/onboarding/presentation/athlete_survey_page.dart` (trainer's custom questionnaire) → confusing.
- `ExerciseModel` has only `muscleGroup` + free-text `equipment`.
- `workout_builder_page.dart` is ~1400 lines; contains `_ExercisePicker` which the plan editor needs too.
- `test/` only has the default `widget_test.dart`.
- `api_constants.dart` still has stale "not yet in backend" comments.
- `flutter_application_2` is an empty template — ignore it.

## F0 — Prerequisites / cleanup (after backend Phase 0)
1. Add dev deps: `bloc_test`, `mocktail`. Replace the default widget test with a real smoke test.
2. Extract `_ExercisePicker` (+ tile) from `workout_builder_page.dart` into `features/exercise/presentation/widgets/exercise_picker.dart` as a public widget with filters (muscle group, equipment, movement pattern). Builder page must behave the same.
3. Extend `ExerciseModel` with backend Phase 0 fields (secondaryMuscleGroups, movementPattern, isCompound, minLevel, equipment list, stressTags) — keep backward compat for `equipment` string. Show pattern/compound chips in the catalogue + picker.
4. New feature `features/athlete_profile/` (model, repository, cubit) for `GET/PUT /api/athleteprofile/me` and `/{athleteId}`.
5. Rename the register survey to `AthleteProfileSurveyPage`, map its answers to `AthleteProfile` (Hungarian labels → enums: Izomépítés→Hypertrophy, Erőnlét→Strength, Fogyás→FatLoss, others→GeneralFitness; injuries Térd→knee, Váll→shoulder, Derék/Hát→lower_back, Boka→ankle, Csukló→wrist…) and **PUT it to the backend** after register/login. Add missing fields: experience level, session minutes. Keep the local copy only as offline fallback.
6. Trainer: profile card on `athlete_detail_page.dart` with an edit sheet (muscle group priority sliders 0.5–1.5).
7. Clean stale comments in `api_constants.dart`.

## F1 — Plan data layer (after backend Phase 6)
`features/training_plan/`:
- models: `TrainingPlanModel`, `PlanDayModel`, `PlannedExerciseModel`, `ViolationModel`, `GenerateResultModel` (plan, violations, predictedScore, candidates) — enums as strings, round-trip tests.
- `TrainingPlanRepository`: generate, refine, update, validate, accept, materialize, explanation, forAthlete, mine. Typed exceptions: forbidden (403), rate-limited (429), LLM unavailable (503), validation (400).
- `ApiConstants` entries for all of them.
- Generation can take 10–30 s → per-request `receiveTimeout: 60s` for generate/refine.

## F2 — Generate wizard (trainer)
Route `/plan/generate?athleteId=` from `athlete_detail_page` ("AI edzésterv" button).
- Step 1: shows athlete profile summary (link to edit), mode (Hibrid / Csak szabályalapú / Csak LLM — the last two labelled "összehasonlításhoz"), weeks, optional training block.
- Step 2: loading state with progress text ("Jelöltek generálása… ML pontozás… ellenőrzés…").
- Step 3: candidates list (if >1) with predicted progress score → pick one → editor.
- `PlanGenerateCubit`.

## F3 — Plan editor (trainer)
Route `/plan/:id/edit`. `PlanEditorBloc` (events: load, editExercise, swapExercise, reorder, addExercise, removeExercise, refine, validate, accept).
- Days as tabs; exercise rows: sets, rep range, target RPE, rest; swap via shared `ExercisePicker` pre-filtered to same movement pattern.
- Debounced `/validate` (500 ms) after each edit → violation badges: red (Error) blocks Accept, orange (Warning) informational; tap → message.
- Weekly volume per muscle group bar chart (`fl_chart`) vs MEV/MRV lines.
- Refine bar at the bottom: text field → `/refine`; changed rows highlighted for 3 s; undo last refine.
- Accept → bottom sheet with start date → `/accept` then `/materialize` → navigate to trainer calendar.

## F4 — Explanation + athlete view
- Explanation panel (markdown text) in editor and athlete view.
- Athlete: "Edzéstervem" section on home/session page → read-only plan view (`/plan/mine`).

## F5 — Autoregulation in workout builder (after backend Phase 7)
- In `workout_builder_page` when athlete + exercise chosen: fetch `/api/autoregulation/{athleteId}/next-week`, show suggestion chip "+2.5 kg — minden szett RPE 7" → tap applies target weight. Deload suggestion banner.

## F6 — Tests + polish
- Bloc tests for generate cubit and editor bloc (fake repo), widget test for violation badges, golden-free.
- Empty/error states for every new page, Hungarian copy.
