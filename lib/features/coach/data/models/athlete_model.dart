class AthleteModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String? goal;
  final int workoutCount;
  final int streakDays;
  final String? lastWorkoutDate;

  const AthleteModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    this.goal,
    required this.workoutCount,
    required this.streakDays,
    this.lastWorkoutDate,
  });

  factory AthleteModel.fromJson(Map<String, dynamic> json) {
    return AthleteModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      goal: json['goal'] as String?,
      workoutCount: (json['workoutCount'] as num?)?.toInt() ?? 0,
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
      lastWorkoutDate: json['lastWorkoutDate'] as String?,
    );
  }

  String get fullName => '$lastName $firstName';
  String get initials => '${firstName[0]}${lastName[0]}';
}
