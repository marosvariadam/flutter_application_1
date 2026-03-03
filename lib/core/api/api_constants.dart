class ApiConstants {
  static const String baseUrl = 'https://api.fitapp.example.com';

  // ── Auth ────────────────────────────────────────────────────────────────────
  static const String login = '/api/auth/login';
  static const String refreshToken = '/api/auth/refresh';
  static const String registerTrainer = '/api/auth/register/trainer';
  static const String registerAthlete = '/api/auth/register/athlete';
  static const String logout = '/api/auth/logout';

  // ── User ────────────────────────────────────────────────────────────────────
  static const String me = '/api/user/me';
  static const String changePassword = '/api/user/change-password';

  static String userById(String id) => '/api/user/$id';

  // ── Athlete roster (trainer) ─────────────────────────────────────────────
  static const String myAthletes = '/api/user/my-athletes';
  static const String createAthlete = '/api/user/athlete';
  static String athlete(String id) => '/api/user/athlete/$id';
  static String resetAthletePassword(String id) =>
      '/api/user/athlete/$id/reset-password';

  // ── Trainer requests ────────────────────────────────────────────────────────
  static const String trainerRequest = '/api/trainer-request';
  static const String myTrainerRequests = '/api/trainer-request/mine';
  static const String pendingRequests = '/api/trainer-request/pending';
  static String acceptRequest(String id) => '/api/trainer-request/$id/accept';
  static String rejectRequest(String id) => '/api/trainer-request/$id/reject';

  // ── Workouts ────────────────────────────────────────────────────────────────
  static const String workout = '/api/workout';
  static String workoutById(String id) => '/api/workout/$id';
  static const String trainerCreated = '/api/workout/trainer/created';
  static const String trainerCalendar = '/api/workout/trainer/calendar';
  static const String trainerReview = '/api/workout/trainer/review';
  static const String myWorkouts = '/api/workout/my-workouts';
  static const String athleteCalendar = '/api/workout/athlete/calendar';
  static String startWorkout(String id) => '/api/workout/$id/start';
  static String logExercise(String workoutId, int index) =>
      '/api/workout/$workoutId/exercises/$index';
  static String completeWorkout(String id) => '/api/workout/$id/complete';

  // ── Exercises ───────────────────────────────────────────────────────────────
  static const String exercise = '/api/exercise';
  static String exerciseById(String id) => '/api/exercise/$id';

  // ── Notifications ───────────────────────────────────────────────────────────
  static const String notifications = '/api/notification';
  static const String unreadCount = '/api/notification/unread-count';
  static String markNotifRead(String id) => '/api/notification/$id/read';
  static const String markAllRead = '/api/notification/mark-all-read';
  static const String notificationHub = '/hubs/notification';

  // ── Messaging ───────────────────────────────────────────────────────────────
  static const String conversations = '/api/message/conversations';
  static String messageThread(String otherId) => '/api/message/$otherId';
  static String sendMessage(String recipientId) => '/api/message/$recipientId';
  static String markRead(String otherId) => '/api/message/$otherId/read';
  static const String chatHub = '/hubs/chat';

  // ── Onboarding ──────────────────────────────────────────────────────────────
  static const String onboardingForm = '/api/onboarding-form';
  static const String onboardingMine = '/api/onboarding-form/mine';
  static const String onboardingResponses = '/api/onboarding-form/responses';
  static String onboardingAthleteResponse(String athleteId) =>
      '/api/onboarding-form/responses/$athleteId';
  static const String onboardingMyForm =
      '/api/onboarding-form/my-trainer-form';
  static const String onboardingSubmit = '/api/onboarding-form/submit';
  static const String onboardingMyResponse = '/api/onboarding-form/my-response';
}
