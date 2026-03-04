class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role; // 'Trainer' | 'Athlete'

  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
  });

  bool get isTrainer => role.toLowerCase() == 'trainer';
  bool get isAthlete => role.toLowerCase() == 'athlete';

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'] as String,
        firstName: j['firstName'] as String,
        lastName: j['lastName'] as String,
        email: j['email'] as String,
        role: j['role'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'role': role,
      };

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
  }) =>
      UserModel(
        id: id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        role: role,
      );
}
