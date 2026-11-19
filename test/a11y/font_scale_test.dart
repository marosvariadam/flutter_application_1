// Every screen at 1.3× system font size on a small phone (360 × 740), in
// light and dark: a RenderFlex overflow or any other build/layout error
// fails the test. Data comes from page_fixtures.dart (long Hungarian names).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:flutter_application_1/app/shared/widgets/widgets_nav/bottom_nav.dart';
import 'package:flutter_application_1/features/coach/presentation/athlete_detail_page.dart';
import 'package:flutter_application_1/features/coach/presentation/athletes_page.dart';
import 'package:flutter_application_1/features/coach/presentation/workout_builder_page.dart';
import 'package:flutter_application_1/features/exercise/presentation/exercise_catalogue_page.dart';
import 'package:flutter_application_1/features/exercise/presentation/exercise_form_page.dart';
import 'package:flutter_application_1/features/exercise_stats/presentation/exercise_stats_page.dart';
import 'package:flutter_application_1/features/home/presentation/home_page.dart';
import 'package:flutter_application_1/features/login/login_page.dart';
import 'package:flutter_application_1/features/messaging/presentation/chat_page.dart';
import 'package:flutter_application_1/features/messaging/presentation/messaging_page.dart';
import 'package:flutter_application_1/features/notifications/presentation/notifications_page.dart';
import 'package:flutter_application_1/features/onboarding/presentation/athlete_survey_page.dart';
import 'package:flutter_application_1/features/onboarding/presentation/trainer_form_builder_page.dart';
import 'package:flutter_application_1/features/onboarding/presentation/trainer_responses_page.dart';
import 'package:flutter_application_1/features/prediction/presentation/prediction_page.dart';
import 'package:flutter_application_1/features/profiles/presentation/profiles_page.dart';
import 'package:flutter_application_1/features/register/athlete_profile_survey_page.dart';
import 'package:flutter_application_1/features/register/register_page.dart';
import 'package:flutter_application_1/features/session/presentation/session_page.dart';
import 'package:flutter_application_1/features/trainer/presentation/athlete_requests_page.dart';
import 'package:flutter_application_1/features/trainer/presentation/athlete_waiting_page.dart';
import 'package:flutter_application_1/features/trainer/presentation/create_edit_athlete_page.dart';
import 'package:flutter_application_1/features/trainer/presentation/roster_page.dart';
import 'package:flutter_application_1/features/trainer/presentation/trainer_requests_page.dart';
import 'package:flutter_application_1/features/training_plan/presentation/my_plan_page.dart';
import 'package:flutter_application_1/features/training_plan/presentation/plan_editor_page.dart';
import 'package:flutter_application_1/features/training_plan/presentation/plan_generate_page.dart';
import 'package:flutter_application_1/features/user/presentation/change_password_page.dart';
import 'package:flutter_application_1/features/user/presentation/edit_profile_page.dart';
import 'package:flutter_application_1/features/workout/presentation/workout_calendar_page.dart';
import 'package:flutter_application_1/features/workout/presentation/workout_detail_page.dart';
import 'package:flutter_application_1/features/workout/presentation/workout_form_page.dart';
import 'package:flutter_application_1/features/workout/presentation/workout_review_page.dart';

import 'page_fixtures.dart';
import 'page_harness.dart';

typedef _Page = (String, Role, Widget Function());

final List<_Page> _pages = [
  // Public
  ('Bejelentkezés', Role.guest, () => const LoginPage()),
  ('Regisztráció', Role.guest, () => const RegisterPage()),
  ('Profil kérdőív', Role.guest, () => const AthleteProfileSurveyPage()),

  // Athlete
  ('Kezdőlap (sportoló)', Role.athlete, () => const HomePage()),
  ('Edzéseim', Role.athlete, () => const SessionsPage()),
  ('Edzésnaptár', Role.athlete, () => const WorkoutCalendarPage()),
  ('Edzés – folyamatban', Role.athlete,
      () => const WorkoutDetailPage(workoutId: 'w-today')),
  ('Edzés – tervezett', Role.athlete,
      () => const WorkoutDetailPage(workoutId: 'w-next')),
  ('Edzés – teljesített', Role.athlete,
      () => const WorkoutDetailPage(workoutId: 'w-done')),
  ('Üzenetek (sportoló)', Role.athlete, () => const MessagingPage()),
  ('Statisztikák (sportoló)', Role.athlete, () => const ExerciseStatsPage()),
  ('Előrejelzés (sportoló)', Role.athlete, () => const PredictionPage()),
  ('Edzéstervem', Role.athlete, () => const MyPlanPage()),
  ('Felmérő kérdőív', Role.athlete, () => const AthleteSurveyPage()),
  ('Edzőhöz csatlakozás', Role.athlete, () => const AthleteRequestsPage()),
  ('Várakozás', Role.athlete, () => const AthleteWaitingPage()),
  ('Profil (sportoló)', Role.athlete, () => const ProfilesPage()),
  ('Profil szerkesztése', Role.athlete, () => const EditProfilePage()),
  ('Jelszó módosítása', Role.athlete, () => const ChangePasswordPage()),

  // Trainer
  ('Áttekintés (edző)', Role.trainer, () => const HomePage()),
  ('Atlétáim', Role.trainer, () => const AthletesPage()),
  ('Sportolók', Role.trainer, () => const RosterPage()),
  ('Csatlakozási kérések', Role.trainer,
      () => const TrainerRequestsPage(isTrainer: true)),
  ('Értesítések', Role.trainer, () => const NotificationsPage()),
  ('Üzenetek (edző)', Role.trainer, () => const MessagingPage()),
  ('Chat', Role.trainer,
      () => const ChatPage(contactId: 'a1', contactName: 'Szabó-Kiss Annamária')),
  ('Atléta adatlap', Role.trainer, () => const AthleteDetailPage(athleteId: 'a1')),
  ('Edzés összeállítása', Role.trainer,
      () => const WorkoutBuilderPage(preselectedAthleteId: 'a1')),
  ('Edzés (edző)', Role.trainer,
      () => const WorkoutDetailPage(workoutId: 'w-next')),
  ('Edzés áttekintése', Role.trainer,
      () => const WorkoutReviewPage(athleteId: 'a1')),
  ('Edzés űrlap', Role.trainer, () => const WorkoutFormPage()),
  ('Statisztikák (edző)', Role.trainer,
      () => const ExerciseStatsPage(
          athleteId: 'a1', athleteName: 'Szabó-Kiss Annamária')),
  ('Előrejelzés (edző)', Role.trainer,
      () => const PredictionPage(
          athleteId: 'a1', athleteName: 'Szabó-Kiss Annamária')),
  ('Tervgenerálás', Role.trainer, () => const PlanGeneratePage(athleteId: 'a1')),
  ('Tervszerkesztő', Role.trainer,
      () => PlanEditorPage(plan: fixturePlan(status: 'Draft'))),
  ('Kérdőív szerkesztő', Role.trainer, () => const TrainerFormBuilderPage()),
  ('Kérdőív válaszok', Role.trainer, () => const TrainerResponsesPage()),
  ('Gyakorlat katalógus', Role.trainer, () => const ExerciseCataloguePage()),
  ('Gyakorlat űrlap', Role.trainer, () => const ExerciseFormPage()),
  ('Sportoló felvétele', Role.trainer, () => const CreateEditAthletePage()),
  ('Profil (edző)', Role.trainer, () => const ProfilesPage()),
];

void main() {
  setUpAll(() async {
    await initializeDateFormatting('hu');
    await loadRealFonts();
  });

  for (final dark in [false, true]) {
    final theme = dark ? 'sötét' : 'világos';
    group('1.3× betűméret, $theme téma', () {
      for (final (name, role, build) in _pages) {
        testWidgets(name, (tester) async {
          await pumpAppPage(tester, build(), role: role, dark: dark);


        });
      }

      testWidgets('Alsó navigáció (edző)', (tester) async {
        await pumpAppPage(
          tester,
          const SizedBox(),
          role: Role.trainer,
          dark: dark,
          initialLocation: '/a',
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (_, __, shell) => BottomNavScaffold(shell: shell),
              branches: [
                for (final path in ['/a', '/b', '/c', '/d'])
                  StatefulShellBranch(routes: [
                    GoRoute(
                        path: path,
                        builder: (_, __) => const Scaffold(body: SizedBox())),
                  ]),
              ],
            ),
          ],
        );
        expect(find.text('Áttekintés'), findsOneWidget);


      });
    });
  }
}
