/// Backend enum names for the plan generator. Kept as strings so we don't
/// pay the enum-mapping tax everywhere; UI reads these via Hungarian label
/// maps alongside this file.
class AthleteProfileGoals {
  static const hypertrophy = 'Hypertrophy';
  static const strength = 'Strength';
  static const generalFitness = 'GeneralFitness';
  static const fatLoss = 'FatLoss';

  static const all = <String>[
    hypertrophy,
    strength,
    generalFitness,
    fatLoss,
  ];

  /// Hungarian label shown in the UI.
  static const Map<String, String> labels = {
    hypertrophy: 'Izomépítés',
    strength: 'Erőnlét',
    generalFitness: 'Általános fitness',
    fatLoss: 'Fogyás',
  };
}

class AthleteProfileExperienceLevels {
  static const beginner = 'Beginner';
  static const intermediate = 'Intermediate';
  static const advanced = 'Advanced';

  static const all = <String>[beginner, intermediate, advanced];

  static const Map<String, String> labels = {
    beginner: 'Kezdő',
    intermediate: 'Haladó',
    advanced: 'Profi',
  };
}

/// Equipment enum names. `Cable` isn't exposed in the survey today but kept
/// here so the edit sheet can offer it to trainers.
class AthleteProfileEquipment {
  static const barbell = 'Barbell';
  static const dumbbell = 'Dumbbell';
  static const machine = 'Machine';
  static const cable = 'Cable';
  static const bodyweight = 'Bodyweight';
  static const kettlebell = 'Kettlebell';
  static const band = 'Band';

  static const all = <String>[
    barbell, dumbbell, machine, cable, bodyweight, kettlebell, band,
  ];

  static const Map<String, String> labels = {
    barbell: 'Rúd + tárcsák',
    dumbbell: 'Kézisúlyok',
    machine: 'Edzőgépek',
    cable: 'Kábel',
    bodyweight: 'Saját testsúly',
    kettlebell: 'Kettlebell',
    band: 'Ellenálló szalagok',
  };
}

/// Snake-case tags matching the backend `AvoidStressTags` vocabulary.
class AthleteProfileStressTags {
  static const knee = 'knee';
  static const shoulder = 'shoulder';
  static const lowerBack = 'lower_back';
  static const ankle = 'ankle';
  static const wrist = 'wrist';
  static const elbow = 'elbow';
  static const hip = 'hip';
  static const neck = 'neck';

  static const all = <String>[
    knee, shoulder, lowerBack, ankle, wrist, elbow, hip, neck,
  ];

  static const Map<String, String> labels = {
    knee: 'Térd',
    shoulder: 'Váll',
    lowerBack: 'Derék / Hát',
    ankle: 'Boka',
    wrist: 'Csukló',
    elbow: 'Könyök',
    hip: 'Csípő',
    neck: 'Nyak',
  };
}

/// Priority multiplier bounds enforced by the backend scorer.
const double kProfilePriorityMin = 0.5;
const double kProfilePriorityMax = 1.5;
const double kProfilePriorityDefault = 1.0;

/// The structured, machine-readable profile the plan generator reads. Mirrors
/// `Models/AthleteProfile.cs`.
class AthleteProfileModel {
  final String? id;
  final String athleteId;
  final String goal;
  final String experienceLevel;
  final int daysPerWeek;
  final int sessionMinutes;
  final List<String> availableEquipment;
  final List<String> avoidStressTags;
  final List<String> excludedExerciseIds;
  final Map<String, double> muscleGroupPriority;
  final double? weightKg;
  final String? sportHistory;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AthleteProfileModel({
    this.id,
    required this.athleteId,
    required this.goal,
    required this.experienceLevel,
    required this.daysPerWeek,
    required this.sessionMinutes,
    this.availableEquipment = const [],
    this.avoidStressTags = const [],
    this.excludedExerciseIds = const [],
    this.muscleGroupPriority = const {},
    this.weightKg,
    this.sportHistory,
    this.createdAt,
    this.updatedAt,
  });

  factory AthleteProfileModel.fromJson(Map<String, dynamic> j) {
    final rawPriority = j['muscleGroupPriority'];
    final priority = <String, double>{};
    if (rawPriority is Map) {
      rawPriority.forEach((k, v) {
        if (v is num) priority[k.toString()] = v.toDouble();
      });
    }
    return AthleteProfileModel(
      id: j['id'] as String?,
      athleteId: j['athleteId'] as String? ?? '',
      goal: j['goal'] as String? ?? AthleteProfileGoals.generalFitness,
      experienceLevel: j['experienceLevel'] as String? ??
          AthleteProfileExperienceLevels.beginner,
      daysPerWeek: (j['daysPerWeek'] as num?)?.toInt() ?? 3,
      sessionMinutes: (j['sessionMinutes'] as num?)?.toInt() ?? 60,
      availableEquipment: (j['availableEquipment'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      avoidStressTags: (j['avoidStressTags'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      excludedExerciseIds: (j['excludedExerciseIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      muscleGroupPriority: priority,
      weightKg: (j['weightKg'] as num?)?.toDouble(),
      sportHistory: j['sportHistory'] as String?,
      createdAt: _parseDate(j['createdAt']),
      updatedAt: _parseDate(j['updatedAt']),
    );
  }

  /// JSON payload matching the backend's `AthleteProfileRequest`. Id and
  /// timestamps are server-owned, so they are omitted here.
  Map<String, dynamic> toRequestJson() => {
        'goal': goal,
        'experienceLevel': experienceLevel,
        'daysPerWeek': daysPerWeek,
        'sessionMinutes': sessionMinutes,
        'availableEquipment': availableEquipment,
        'avoidStressTags': avoidStressTags,
        'excludedExerciseIds': excludedExerciseIds,
        'muscleGroupPriority': muscleGroupPriority,
        if (weightKg != null) 'weightKg': weightKg,
        if (sportHistory != null && sportHistory!.isNotEmpty)
          'sportHistory': sportHistory,
      };

  AthleteProfileModel copyWith({
    String? goal,
    String? experienceLevel,
    int? daysPerWeek,
    int? sessionMinutes,
    List<String>? availableEquipment,
    List<String>? avoidStressTags,
    List<String>? excludedExerciseIds,
    Map<String, double>? muscleGroupPriority,
    double? weightKg,
    String? sportHistory,
  }) =>
      AthleteProfileModel(
        id: id,
        athleteId: athleteId,
        goal: goal ?? this.goal,
        experienceLevel: experienceLevel ?? this.experienceLevel,
        daysPerWeek: daysPerWeek ?? this.daysPerWeek,
        sessionMinutes: sessionMinutes ?? this.sessionMinutes,
        availableEquipment: availableEquipment ?? this.availableEquipment,
        avoidStressTags: avoidStressTags ?? this.avoidStressTags,
        excludedExerciseIds: excludedExerciseIds ?? this.excludedExerciseIds,
        muscleGroupPriority: muscleGroupPriority ?? this.muscleGroupPriority,
        weightKg: weightKg ?? this.weightKg,
        sportHistory: sportHistory ?? this.sportHistory,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static DateTime? _parseDate(dynamic v) {
    if (v is String && v.isNotEmpty) {
      return DateTime.tryParse(v);
    }
    return null;
  }
}
