class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:5233';

  // ── Auth ────────────────────────────────────────────────────────────────────
  /// POST { email, password } → { token, userId, role }
  static const String login = '/api/auth/login';

  // ── User ────────────────────────────────────────────────────────────────────
  /// POST { firstName, lastName, email, password, role }
  static const String register = '/api/user/register';
  static String userById(String id) => '/api/user/$id';
  static String updateUser(String id) => '/api/user/$id';
  static String deleteUser(String id) => '/api/user/$id';
  static const String changePassword = '/api/user/change-password';

  // ── Trainer's athletes ───────────────────────────────────────────────────────
  static String trainerAthletes(String trainerId) =>
      '/api/user/trainer/$trainerId/athletes';

  // ── Workouts ────────────────────────────────────────────────────────────────
  static const String workout = '/api/workout';
  static String workoutById(String id) => '/api/workout/$id';
  static const String trainerCreated = '/api/workout/trainer/created';
  static const String myWorkouts = '/api/workout/my-workouts';
  static String completeWorkout(String id) => '/api/workout/$id/complete';
  static String startWorkout(String id) => '/api/workout/$id/start';
  static String logExercise(String workoutId, int index) =>
      '/api/workout/$workoutId/exercise/$index';
  static String trainerReview(String athleteId) =>
      '/api/workout/trainer/review/$athleteId';
  static const String trainerCalendar = '/api/workout/trainer/calendar';
  static const String athleteCalendar = '/api/workout/my-workouts/calendar';

  // ── Exercises ───────────────────────────────────────────────────────────────
  static const String exercise = '/api/exercise';
  static String exerciseById(String id) => '/api/exercise/$id';

  // ── Notifications (not yet in backend — kept for future) ────────────────────
  static const String notifications = '/api/notification';
  static const String unreadCount = '/api/notification/unread-count';
  static String markNotifRead(String id) => '/api/notification/$id/read';
  static const String markAllRead = '/api/notification/mark-all-read';

  // ── Messaging (not yet in backend — kept for future) ────────────────────────
  static const String conversations = '/api/message/conversations';
  static String messageThread(String otherId) => '/api/message/$otherId';
  static String sendMessage(String recipientId) => '/api/message/$recipientId';
  static String markRead(String otherId) => '/api/message/$otherId/read';

  // ── Trainer requests ─────────────────────────────────────────────────────────
  static const String trainerRequest = '/api/trainer-request';
  static const String myTrainerRequests = '/api/trainer-request/mine';
  static const String pendingRequests = '/api/trainer-request/pending';
  static String acceptRequest(String id) => '/api/trainer-request/$id/accept';
  static String rejectRequest(String id) => '/api/trainer-request/$id/reject';
  static String cancelRequest(String id) => '/api/trainer-request/$id';

  // ── Trainer / Athlete link management ────────────────────────────────────────
  static const String leaveTrainer = '/api/user/leave-trainer';
  static String removeAthlete(String athleteId) =>
      '/api/user/remove-athlete/$athleteId';

  // ── SignalR Hubs ────────────────────────────────────────────────────────────
  static const String chatHub = '/hubs/chat';
  static const String notificationHub = '/hubs/notifications';

  // ── Onboarding (not yet in backend — kept for future) ───────────────────────
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
