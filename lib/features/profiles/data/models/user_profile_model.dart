class UserProfileModel {
  final String id;
  final String name;
  final String location;
  final String avatarUrl;
  final int workoutCount;
  final int streakDays;
  final double startingWeightKg;
  final double currentWeightKg;
  final double heightCm;

  const UserProfileModel({
    required this.id,
    required this.name,
    required this.location,
    required this.avatarUrl,
    required this.workoutCount,
    required this.streakDays,
    required this.startingWeightKg,
    required this.currentWeightKg,
    required this.heightCm,
  });
}
