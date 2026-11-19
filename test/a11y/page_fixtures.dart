import 'package:dio/dio.dart';

import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';

import '../helpers/fake_http.dart';

/// Canned backend for the page-level layout tests. Deliberately long
/// Hungarian names and texts, so tight rows show up as overflows.
final _now = DateTime.now();

String _iso(int dayOffset, [int hour = 9]) =>
    DateTime(_now.year, _now.month, _now.day + dayOffset, hour)
        .toIso8601String();

const _exerciseNames = [
  'Guggolás hátul rúddal, szünettel',
  'Fekvenyomás döntött padon',
  'Román felhúzás kézisúlyzóval',
  'Evezés döntött törzzsel',
];

Map<String, dynamic> _exercise(int i, {bool done = false}) => {
      'exerciseId': 'e$i',
      'name': _exerciseNames[i % _exerciseNames.length],
      'index': i,
      'sets': 4,
      'targetReps': 8,
      'targetWeightKg': 82.5,
      'equipmentType': 'Szabadsúly',
      'muscleGroup': 'Láb',
      'instructions':
          'Lassú, kontrollált leengedés, robbanékony felállás; a térd a lábujjak irányába mutasson.',
      if (done) ...{
        'actualSets': 4,
        'actualReps': 8,
        'actualWeightKg': 85,
        'rpe': 8,
        'exerciseNotes': 'Az utolsó sorozat nehéz volt.',
      },
    };

Map<String, dynamic> workoutJson(String id, int dayOffset,
        {String status = 'Planned', String difficulty = 'hard'}) =>
    {
      'id': id,
      'title': 'Alsótest – erő és robbanékonyság fejlesztése',
      'description':
          'Nehéz guggolás és csípődomináns gyakorlatok, a végén core blokk.',
      'scheduledDate': _iso(dayOffset),
      'athleteId': 'a1',
      'coachId': 't1',
      'difficulty': difficulty,
      'status': status,
      'trainerName': 'Kovács Bence',
      'athleteName': 'Szabó-Kiss Annamária',
      'notes': 'Bemelegítés: 10 perc mobilizálás, majd fokozatos terhelés.',
      if (status == 'Completed')
        'athleteFeedback': 'Jól ment, a harmadik gyakorlatnál elfáradtam.',
      'estimatedDuration': '75 perc',
      'kcal': '520 kcal',
      'exercises': [
        for (var i = 0; i < 4; i++)
          _exercise(i, done: status == 'Completed' || (status == 'InProgress' && i == 0)),
      ],
    };

List<Map<String, dynamic>> _workouts() => [
      workoutJson('w-today', 0, status: 'InProgress'),
      workoutJson('w-done', -1, status: 'Completed', difficulty: 'moderate'),
      workoutJson('w-next', 2, difficulty: 'intense'),
      workoutJson('w-later', 4, difficulty: 'easy'),
    ];

final _athletes = [
  {
    'id': 'a1',
    'firstName': 'Annamária',
    'lastName': 'Szabó-Kiss',
    'email': 'annamaria.szabo-kiss@example.com',
  },
  {
    'id': 'a2',
    'firstName': 'Péter',
    'lastName': 'Nagy',
    'email': 'peter.nagy@example.com',
  },
  {
    'id': 'a3',
    'firstName': 'Krisztina',
    'lastName': 'Horváth-Varga',
    'email': 'krisztina.horvath-varga@example.com',
  },
];

Map<String, dynamic> _request(String id, String status) => {
      'id': id,
      'athleteId': 'a2',
      'athleteName': 'Nagy Péter Bálint',
      'athleteEmail': 'peter.balint.nagy@example.com',
      'trainerEmail': 'kovacs.bence@example.com',
      'trainerId': 't1',
      'trainerName': 'Kovács Bence',
      'status': status,
      'note': 'Szeretnék felkészülni egy tavaszi félmaratonra, heti 4 edzéssel.',
      'createdAt': _iso(-2),
    };

final _notifications = [
  for (final (i, type) in [
    'TrainerRequestReceived',
    'TrainerRequestAccepted',
    'WorkoutAssigned',
    'OnboardingFormAvailable',
  ].indexed)
    {
      'id': 'n$i',
      'type': type,
      'message':
          'Kovács Bence új edzést rendelt hozzád: Alsótest – erő és robbanékonyság fejlesztése.',
      'isRead': i.isOdd,
      'createdAt': _iso(-i),
    },
];

final _conversations = [
  {
    'partnerId': 'a1',
    'partnerName': 'Szabó-Kiss Annamária',
    'lastMessage':
        'Köszönöm az új tervet, holnap reggel már az alapján edzek!',
    'lastMessageAt': _iso(0, 8),
    'unreadCount': 12,
  },
  {
    'partnerId': 'a2',
    'partnerName': 'Nagy Péter',
    'lastMessage': 'Rendben.',
    'lastMessageAt': _iso(-3),
    'unreadCount': 0,
  },
];

final _thread = [
  for (var i = 0; i < 6; i++)
    {
      'id': 'm$i',
      'content': i.isEven
          ? 'Szia! A mai guggolásnál a harmadik sorozatban fájt a térdem, csökkentsem a súlyt?'
          : 'Igen, menj vissza 70 kg-ra és figyelj a térd irányára.',
      'createdAt': _iso(0, 8 + i),
      'senderId': i.isEven ? 'a1' : 't1',
    },
];

final _exercises = [
  for (var i = 0; i < 6; i++)
    {
      'id': 'e$i',
      'name': _exerciseNames[i % _exerciseNames.length],
      'muscleGroup': 'Láb',
      'secondaryMuscleGroups': ['Fenék', 'Has'],
      'description': 'Összetett alapgyakorlat az alsótest erejéhez.',
      'equipment': ['Barbell', 'Rack'],
      'movementPattern': 'Squat',
      'isCompound': true,
      'minLevel': 'Intermediate',
      'stressTags': ['knee', 'lowerBack'],
      'usageCount': 12,
    },
];

final _stats = [
  for (var i = 0; i < 8; i++)
    {
      'date': _iso(-7 * (8 - i)),
      'actualSets': 4,
      'actualReps': 8,
      'actualWeightKg': 80 + i * 2.5,
      'targetReps': 8,
      'targetWeightKg': 80 + i * 2.5,
    },
];

Map<String, dynamic> _prediction() => {
      'exerciseName': 'Guggolás hátul rúddal, szünettel',
      'muscleGroup': 'Láb',
      'weeksAhead': 8,
      'focus': 'Strength',
      'modelLoaded': true,
      'modelTrainedAt': _iso(-10),
      'modelRmseKg': 2.4,
      'actual': [
        for (var i = 0; i < 6; i++)
          {'weekStart': _iso(-7 * (6 - i)), 'est1Rm': 120 + i * 2.0},
      ],
      'predicted': [
        for (var i = 1; i <= 8; i++)
          {
            'weekStart': _iso(7 * i),
            'est1Rm': 132 + i * 1.5,
            'confidenceLowKg': 128 + i * 1.0,
            'confidenceHighKg': 136 + i * 2.0,
          },
      ],
    };

final _blocks = [
  {
    'id': 'b1',
    'athleteId': 'a1',
    'focus': 'Lower',
    'startDate': _iso(-7),
    'endDate': _iso(21),
    'notes': 'Erőfázis a tavaszi verseny előtt, heti négy alkalom.',
  },
];

final _profile = {
  'id': 'p1',
  'athleteId': 'a1',
  'goal': 'Hypertrophy',
  'experienceLevel': 'Intermediate',
  'daysPerWeek': 4,
  'sessionMinutes': 75,
  'availableEquipment': ['Barbell', 'Dumbbell', 'Cable', 'Machine'],
  'avoidStressTags': ['knee'],
  'excludedExerciseIds': <String>[],
  'muscleGroupPriority': {'Chest': 1.2, 'Back': 1.0, 'Legs': 0.8},
  'weightKg': 64.5,
  'sportHistory': 'Kézilabda 8 évig, azóta heti háromszor konditerem.',
  'createdAt': '2026-10-01T12:00:00Z',
  'updatedAt': '2026-10-15T12:00:00Z',
};

PlannedExerciseModel _planned(int i) => PlannedExerciseModel(
      exerciseId: 'e$i',
      name: _exerciseNames[i % _exerciseNames.length],
      muscleGroup: 'Legs',
      sets: 4,
      repMin: 6,
      repMax: 10,
      targetRpe: 8,
      restSeconds: 150,
      order: i,
    );

/// A four-week upper/lower plan with long exercise names.
TrainingPlanModel fixturePlan({String status = PlanStatuses.accepted}) =>
    TrainingPlanModel(
      id: 'p1',
      trainerId: 't1',
      athleteId: 'a1',
      title: 'Felső/alsó felosztás – 4 hetes erőfejlesztő blokk',
      goal: 'Hypertrophy',
      weeks: 4,
      split: PlanSplits.upperLower,
      status: status,
      days: [
        for (var d = 0; d < 4; d++)
          PlanDayModel(
            dayIndex: d,
            label: d.isEven ? 'Felsőtest – nyomó' : 'Alsótest – guggolás',
            exercises: [for (var i = 0; i < 4; i++) _planned(i)],
          ),
      ],
      progression: PlanProgressionSchemes.doubleProgression,
      source: PlanGenerationSources.hybrid,
      createdAt: DateTime.utc(2026, 11, 2),
    );

final _form = {
  'id': 'f1',
  'title': 'Felmérő kérdőív új sportolóknak',
  'description':
      'Kérlek, válaszolj őszintén, ez alapján állítom össze az első heteidet.',
  'questions': [
    {'id': 'q1', 'text': 'Volt-e sérülésed az elmúlt két évben?', 'type': 'text', 'options': <String>[]},
    {
      'id': 'q2',
      'text': 'Hány napot tudsz edzeni egy héten?',
      'type': 'single',
      'options': ['2 nap', '3 nap', '4 nap', '5 vagy több nap'],
    },
    {'id': 'q3', 'text': 'Mennyire vagy motivált? (1–10)', 'type': 'scale', 'options': <String>[]},
  ],
};

final _responses = [
  {
    'athleteId': 'a1',
    'athleteName': 'Szabó-Kiss Annamária',
    'answers': [
      {'questionId': 'q1', 'answer': 'Bal boka szalagsérülés 2025-ben.'},
    ],
    'submittedAt': _iso(-5),
  },
];

final _user = {
  'id': 'a1',
  'firstName': 'Annamária',
  'lastName': 'Szabó-Kiss',
  'email': 'annamaria.szabo-kiss@example.com',
  'role': 'Athlete',
  'weightKg': 64.5,
};

/// Routes a fake request to its canned answer; unknown reads get a 404
/// (most screens treat that as "nothing yet"), writes succeed.
FakeResponse fixtureApi(RequestOptions r) {
  final p = r.path;
  if (r.method != 'GET') return const FakeResponse(200, <String, dynamic>{});
  bool m(String pattern) => RegExp('^$pattern\$').hasMatch(p);

  if (m(r'/api/user/trainer/[^/]+/athletes')) return FakeResponse(200, _athletes);
  if (m(r'/api/user/[^/]+')) return FakeResponse(200, _user);

  if (m(r'/api/workout/my-workouts(/calendar)?') ||
      m(r'/api/workout/trainer/(created|calendar)') ||
      m(r'/api/workout/trainer/review/[^/]+')) {
    return FakeResponse(200, _workouts());
  }
  if (m(r'/api/workout/stats/exercise(/[^/]+)?')) return FakeResponse(200, _stats);
  if (m(r'/api/workout/([^/]+)')) {
    final id = p.split('/').last;
    final status = switch (id) {
      'w-today' => 'InProgress',
      'w-done' => 'Completed',
      _ => 'Planned',
    };
    return FakeResponse(200, workoutJson(id, 0, status: status));
  }

  if (m(r'/api/exercise(/for-athlete/[^/]+)?')) return FakeResponse(200, _exercises);

  if (m(r'/api/notification')) return FakeResponse(200, _notifications);
  if (m(r'/api/notification/unread-count')) {
    return const FakeResponse(200, {'count': 2});
  }

  if (m(r'/api/message/conversations')) return FakeResponse(200, _conversations);
  if (m(r'/api/message/[^/]+')) return FakeResponse(200, _thread);

  if (m(r'/api/trainer-request/pending')) {
    return FakeResponse(200, [_request('r1', 'Pending'), _request('r2', 'Pending')]);
  }
  if (m(r'/api/trainer-request/mine')) {
    return FakeResponse(200, [_request('r3', 'Accepted'), _request('r4', 'Rejected')]);
  }

  if (m(r'/api/prediction/exercise(/[^/]+)?')) return FakeResponse(200, _prediction());
  if (m(r'/api/trainingblock/athlete/[^/]+')) return FakeResponse(200, _blocks);
  if (m(r'/api/athleteprofile/[^/]+')) return FakeResponse(200, _profile);
  if (m(r'/api/plan/me') || m(r'/api/plan/athlete/[^/]+')) {
    return FakeResponse(200, [fixturePlan().toJson()]);
  }

  if (m(r'/api/onboarding-form/(mine|my-trainer-form)')) return FakeResponse(200, _form);
  if (m(r'/api/onboarding-form/responses')) return FakeResponse(200, _responses);

  return const FakeResponse(404, {'message': 'not found'});
}
