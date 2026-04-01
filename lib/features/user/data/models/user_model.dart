class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role; // 'Trainer' | 'Athlete'
  final double? weightKg;

  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.weightKg,
  });

  bool get isTrainer => role.toLowerCase() == 'trainer';
  bool get isAthlete => role.toLowerCase() == 'athlete';

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'] as String,
        firstName: j['firstName'] as String,
        lastName: j['lastName'] as String,
        email: j['email'] as String,
        role: j['role'] as String,
        weightKg: (j['weightKg'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'role': role,
        if (weightKg != null) 'weightKg': weightKg,
      };

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
    Object? weightKg = _sentinel,
  }) =>
      UserModel(
        id: id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        role: role,
        weightKg: weightKg == _sentinel ? this.weightKg : weightKg as double?,
      );
}

// Sentinel so copyWith can explicitly pass null for weightKg.
const _sentinel = Object();
