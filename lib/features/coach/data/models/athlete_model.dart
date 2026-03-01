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

  String get fullName => '$lastName $firstName';
  String get initials => '${firstName[0]}${lastName[0]}';
}
