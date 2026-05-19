import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Wraps [FlutterLocalNotificationsPlugin] for the three triggers this app
/// cares about:
///   1. New chat messages           -> [showChat]
///   2. Backend SignalR notifications -> [showGeneric]
///   3. Workout reminders           -> [scheduleWorkoutReminder]
///
/// Routing on tap is exposed via the [taps] stream which emits a payload
/// string (JSON-encoded route hint). The app wires this to GoRouter.
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final _tapController = StreamController<NotificationTap>.broadcast();

  /// Emits whenever the user taps a notification. The app listens to this and
  /// deep-links to the relevant screen.
  Stream<NotificationTap> get taps => _tapController.stream;

  bool _initialized = false;
  bool _permissionGranted = false;

  // Channel IDs
  static const _channelChat = 'chat_messages';
  static const _channelGeneric = 'app_notifications';
  static const _channelWorkout = 'workout_reminders';

  // Init
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Required for `zonedSchedule` so reminders fire in the user's local time.
    tz_data.initializeTimeZones();
    try {
      // Best-effort guess: rely on the system zone via DateTime.now().
      // (The `flutter_native_timezone` package would give the actual zone,
      // but we keep deps lean - for scheduling within hours/days the local
      // offset is sufficient.)
      tz.setLocalLocation(tz.local);
    } catch (_) {}

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // we request explicitly below
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const init = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(
      init,
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundTap,
    );

    // Cold-start: the app may have been launched by tapping a notification.
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails != null &&
        launchDetails.didNotificationLaunchApp &&
        launchDetails.notificationResponse?.payload != null) {
      // Defer emit until subscribers have hooked up.
      scheduleMicrotask(() => _emitTap(
            launchDetails.notificationResponse!.payload!,
          ));
    }

    await _requestPermissions();
    await _createAndroidChannels();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final android =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      // Runtime POST_NOTIFICATIONS permission (Android 13+).
      final granted = await android?.requestNotificationsPermission();
      _permissionGranted = granted ?? true;
      // Exact-alarm permission (Android 12+) -, pre-12.
      await android?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      _permissionGranted = granted;
    } else {
      _permissionGranted = true;
    }
  }

  Future<void> _createAndroidChannels() async {
    if (!Platform.isAndroid) return;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(const AndroidNotificationChannel(
      _channelChat,
      'Üzenetek',
      description: 'Új csevegő üzenetek',
      importance: Importance.high,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      _channelGeneric,
      'Értesítések',
      description: 'Általános alkalmazás értesítések',
      importance: Importance.high,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      _channelWorkout,
      'Edzés emlékeztetők',
      description: 'Közelgő edzések előtti emlékeztetők',
      importance: Importance.high,
    ));
  }

  // Show: chat message
  /// Fires immediately. [contactId] becomes both the dedupe key and the deep
  /// link target - tapping opens `/messages/{contactId}`.
  Future<void> showChat({
    required String contactId,
    required String contactName,
    required String body,
  }) async {
    if (!_initialized || !_permissionGranted) return;
    await _plugin.show(
      _hashId('chat_$contactId'),
      contactName,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelChat,
          'Üzenetek',
          channelDescription: 'Új csevegő üzenetek',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.message,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode({
        'type': 'chat',
        'contactId': contactId,
        'contactName': contactName,
      }),
    );
  }

  // Show: backend / SignalR notification
  Future<void> showGeneric({
    required String title,
    required String body,
    String? deepLink, // e.g. '/notifications'
    String? notificationId,
  }) async {
    if (!_initialized || !_permissionGranted) return;
    await _plugin.show(
      _hashId('generic_${notificationId ?? DateTime.now().millisecondsSinceEpoch}'),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelGeneric,
          'Értesítések',
          channelDescription: 'Általános alkalmazás értesítések',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode({
        'type': 'generic',
        'deepLink': deepLink ?? '/notifications',
      }),
    );
  }

  // Schedule: workout reminder
  /// Schedules a one-shot reminder [leadMinutes] before [scheduledFor].
  /// If [scheduledFor] is already in the past (or within [leadMinutes]), this
  /// is a. Calling again with the same [workoutId] replaces the previous
  /// reminder.
  Future<void> scheduleWorkoutReminder({
    required String workoutId,
    required String workoutTitle,
    required DateTime scheduledFor,
    int leadMinutes = 30,
  }) async {
    if (!_initialized || !_permissionGranted) return;

    final fireAt = scheduledFor.subtract(Duration(minutes: leadMinutes));
    if (fireAt.isBefore(DateTime.now())) return;

    final id = _hashId('workout_$workoutId');
    // Replace any prior reminder for this workout.
    await _plugin.cancel(id);

    final tzTime = tz.TZDateTime.from(fireAt, tz.local);

    try {
      await _plugin.zonedSchedule(
        id,
        'Edzés hamarosan',
        '$workoutTitle — $leadMinutes perc múlva',
        tzTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelWorkout,
            'Edzés emlékeztetők',
            channelDescription: 'Közelgő edzések előtti emlékeztetők',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBanner: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: jsonEncode({
          'type': 'workout',
          'workoutId': workoutId,
        }),
      );
    } catch (_) {
      // Exact-alarm permission may be denied on some devices - silently skip.
    }
  }

  Future<void> cancelWorkoutReminder(String workoutId) async {
    if (!_initialized) return;
    await _plugin.cancel(_hashId('workout_$workoutId'));
  }

  /// Cancel every scheduled / shown notification. Call on logout.
  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }

  // Tap handling
  void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    _emitTap(payload);
  }

  void _emitTap(String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _tapController.add(NotificationTap.fromJson(data));
    } catch (_) {
      // Malformed payload - drop silently.
    }
  }

  // Helpers
  /// Stable 31-bit positive id from a string key, so repeated `show`/`schedule`
  /// calls for the same logical notification dedupe.
  int _hashId(String key) {
    var h = 0;
    for (final cu in key.codeUnits) {
      h = 0x1fffffff & (h + cu);
      h = 0x1fffffff & (h + ((0x0007ffff & h) << 10));
      h ^= h >> 6;
    }
    h = 0x1fffffff & (h + ((0x03ffffff & h) << 3));
    h ^= h >> 11;
    h = 0x1fffffff & (h + ((0x00003fff & h) << 15));
    // Keep in safe int range for the platform channel.
    return h & 0x7fffffff;
  }
}

/// Background-isolate handler for flutter_local_notifications. Must be
/// a top-level / static function. We don't do any work here; the tap is
/// re-delivered to the foreground isolate when the app comes back up.
@pragma('vm:entry-point')
void _onBackgroundTap(NotificationResponse response) {
  // Intentionally empty.
}

/// Parsed payload describing what the user tapped.
class NotificationTap {
  /// One of: 'chat', 'generic', 'workout'.
  final String type;
  final Map<String, dynamic> data;

  const NotificationTap({required this.type, required this.data});

  factory NotificationTap.fromJson(Map<String, dynamic> j) => NotificationTap(
        type: j['type'] as String? ?? 'generic',
        data: j,
      );

  String? get contactId => data['contactId'] as String?;
  String? get contactName => data['contactName'] as String?;
  String? get workoutId => data['workoutId'] as String?;
  String? get deepLink => data['deepLink'] as String?;
}
