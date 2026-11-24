# Design polish — keep the existing style

**The style stays:** soft lavender bg (light) / deep slate (dark), white rounded cards (`rCard` 20 / `rCardSmall` 12), blue primary accent, teal/orange/red/yellow brand accents, dark floating pill bottom nav, Hungarian copy, w600/w700 headings. Nothing gets redesigned — this is consistency, dark-mode correctness, hierarchy and states.

## Audit findings (measured in lib/)

| # | Problem | Numbers |
|---|---|---|
| 1 | Static light-only colors in build methods → **dark mode shows wrong accents** | `DT.metricBlue` ×166, `DT.cardRed` ×54, `DT.cardTeal` ×12, `DT.cardOrange` ×10, `DT.difficulty*` ×16, `Colors.white` ×41, `Colors.green*` ×29, raw `Color(0x…)` in athlete_detail, messaging, session |
| 2 | No type scale — spacing tokens used as font sizes | `fontSize: DT.s3` ×124, `DT.s4` ×88, plus raw 9/10/11/13/15/24/56/72; `textTheme` never used; screen titles and section titles both 16 px |
| 3 | Duplicated private widgets | `_ErrorView` ×3, `_StatCard`, `_StatsRow`, `_SectionLabel`, `_MetaChip`, `_InfoChip`, `_LegendDot`, `_Placeholder`, `_AthleteCard`, `_WorkoutRow` ×2 each — slightly different paddings/fonts each time |
| 4 | Ad-hoc shadows and radii | blurRadius 4/8/10/12/16 mixed; `circular(2/4/8/10/18/20/22)` and spacing tokens as radii |
| 5 | States | bare `CircularProgressIndicator` in 30 files, raw `'Hiba: $e'` shown to users, empty states are plain text lines |
| 6 | Accessibility | 40 texts at 9–11 px, only 3 tooltips/Semantics, icon-only buttons without labels, 34 px nav targets |
| 7 | Small UX bugs | Home app-bar search icon does nothing; avatar is a generic person icon everywhere; deprecated `withOpacity` |
| 8 | Huge files | workout_detail_page 1214 lines, workout_builder 987, messaging 785, athlete_detail 782 |

## P1 — Tokens (app/design)

Add to `dt_colors.dart` (both palettes, theme-tuned like the existing accents):
- `accentYellow`, `accentOrange`, `accentBlueSoft` (= cardBlue), `accentPurple` (for avatars)
- `successSoft`, `warningSoft`, `dangerSoft`, `primarySoft` — 12–15 % tinted backgrounds for chips/pills (light: tint on white; dark: tint on cardSurface)
- `difficultyEasy/Medium/Hard/Intense` mapped to success/warning/orange/danger
- `avatarPalette` list (6 colors) — replaces the hardcoded list in messaging_page

New `app/design/dt_text.dart` — `DTText.of(context)` returning styles with theme color baked in:
| token | size / weight | use |
|---|---|---|
| `display` | 28 / w800 | big numbers (1RM, streak) |
| `h1` | 22 / w700 | page title |
| `h2` | 18 / w700 | section title |
| `title` | 16 / w600 | card title |
| `body` | 14 / w400 | body |
| `bodyStrong` | 14 / w600 | |
| `label` | 13 / w500, textSecondary | form labels, meta |
| `caption` | 12 / w500, textSecondary | timestamps, chip text — **minimum size in the app** |
| `overline` | 12 / w700, letterSpacing 0.6, uppercase | section labels |
Also wire them into `ThemeData.textTheme` so default Text widgets match.

New in `design_tokens.dart`:
- `DT.shadowCard(context)` (blur 12, y 4, shadowLight), `DT.shadowFloating(context)` (blur 20, y 6, shadowMedium)
- radii: `rXs = 6`, `rPill = 999` — and no other literal radii
- `DT.minTap = 44`
- durations: `DT.fast = 150ms`, `DT.normal = 250ms`

Deprecate the static color constants in `DT` with `@Deprecated('use DT.of(context).x')` so the analyzer lists every remaining usage.

## P2 — Shared components (app/shared/widgets/)

Build from the best existing private versions, same look:
- `DTCard` (surface, rCard, shadowCard, optional onTap with InkWell ripple clipped to radius, `padding` default s4)
- `SectionHeader(title, {action})` — h2 + optional "Összes" text button
- `StatTile(icon, value, label, color)` — replaces both `_StatCard`s
- `StatusChip(label, tone: success|warning|danger|info|neutral)` — soft bg + strong text; replaces `_MetaChip/_InfoChip/_TypeChip` and difficulty chips
- `EmptyState(icon, title, message, {actionLabel, onAction})` — icon in a 64 px primarySoft circle, h2 + body, optional button
- `ErrorState(error, onRetry)` — maps exceptions to Hungarian messages (network → „Nincs internetkapcsolat”, 403 → „Nincs jogosultságod…”, 5xx → „A szerver most nem elérhető”), never shows `$e`
- `SkeletonBox` / `SkeletonList(itemCount)` — pulsing placeholder (AnimationController, no package) shaped like the cards it replaces
- `UserAvatar(name, size)` — initials on `avatarPalette[hash(name) % n]`; used in home header, roster, chat, athlete detail
- `PrimaryButton` / `SecondaryButton` — full-width 52 px, rCardSmall, loading state with small spinner, haptic on tap
- `AppBottomSheet` with the existing `_SheetHandle`

## P3 — Migrate screens (one feature folder per step)

Per screen: static colors → `DT.of(context)`, fontSize → `DTText`, private dupes → shared widgets, spinner → skeleton, plain empty text → `EmptyState`, errors → `ErrorState`, literal radii/shadows → tokens, split files over ~500 lines into `presentation/widgets/`.
Order (most visible first): home (athlete) → coach_home → athlete_detail → session + workout_detail → workout_builder → prediction + exercise_stats → messaging + chat → roster/requests/notifications → profile/edit/onboarding/register.

## P4 — Small UX upgrades (still same style)

- Home: remove the dead search icon (or make it open exercise search); `UserAvatar` instead of person icon; greeting by time of day („Jó reggelt / Szép napot / Jó estét”).
- Today’s workout card: progress ring (completed exercises / total) + difficulty `StatusChip`; completed state uses accentSuccess, not `Color(0xFF4CAF50)`.
- Weekly strip: dot under days with workouts, filled dot for completed, today outlined.
- Pull-to-refresh on every list page (7 have it now).
- `AnimatedSwitcher` (DT.normal) between loading → content → empty so screens don't jump.
- Haptics: `HapticFeedback.selectionClick` on chips/tabs, `mediumImpact` on completing a set/workout.
- Workout logging: bigger steppers (±2.5 kg, ±1 rep) at 44 px, numeric keyboard, auto-advance to next set.
- Charts (`fl_chart`): use accentPrimary line + 15 % gradient fill, caption-size axis labels, tooltip in cardSurfaceElevated — same on prediction and exercise_stats.
- Bottom nav: label 11 px min, nav item tap area ≥ 44 px, radius from tokens.

## P5 — Accessibility + dark-mode QA

- `tooltip:` / `Semantics(label:)` on every icon-only button.
- Check contrast of textSecondary on lavender and textGrey (only for placeholders/disabled).
- Test with system font scale 1.3 — no overflow (use `Flexible`, `maxLines` + ellipsis).
- Walk every screen in dark mode; no white boxes, no light-blue accents.
- Golden-free widget tests for EmptyState / ErrorState / StatusChip in both themes.
