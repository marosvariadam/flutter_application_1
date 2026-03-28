class TrainerRequestModel {
  final String id;
  final String athleteId;
  final String? athleteName;
  final String? athleteEmail;
  final String? trainerEmail;
  final String? trainerId;
  final String? trainerName;
  final String status; // 'Pending' | 'Accepted' | 'Rejected'
  final String? note;
  final DateTime createdAt;

  const TrainerRequestModel({
    required this.id,
    required this.athleteId,
    this.athleteName,
    this.athleteEmail,
    this.trainerEmail,
    this.trainerId,
    this.trainerName,
    required this.status,
    this.note,
    required this.createdAt,
  });

  factory TrainerRequestModel.fromJson(Map<String, dynamic> j) =>
      TrainerRequestModel(
        id: j['id'] as String,
        athleteId: j['athleteId'] as String,
        athleteName: j['athleteName'] as String?,
        athleteEmail: j['athleteEmail'] as String?,
        trainerEmail: j['trainerEmail'] as String?,
        trainerId: j['trainerId'] as String?,
        trainerName: j['trainerName'] as String?,
        status: j['status'] as String,
        note: j['note'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isAccepted => status.toLowerCase() == 'accepted';
  bool get isRejected => status.toLowerCase() == 'rejected';

  String get athleteFullName => athleteName ?? '';
  String get athleteFirstName {
    final name = athleteName ?? '';
    final spaceIdx = name.indexOf(' ');
    return spaceIdx > 0 ? name.substring(0, spaceIdx) : name;
  }
}

class AthleteModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;

  const AthleteModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  String get fullName => '$firstName $lastName';

  factory AthleteModel.fromJson(Map<String, dynamic> j) => AthleteModel(
        id: j['id'] as String,
        firstName: j['firstName'] as String,
        lastName: j['lastName'] as String,
        email: j['email'] as String,
      );
}

class PaginatedAthletes {
  final List<AthleteModel> items;
  final int total;
  final int page;
  final int pageSize;

  const PaginatedAthletes({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  bool get hasMore => (page * pageSize) < total;

  factory PaginatedAthletes.fromJson(Map<String, dynamic> j) =>
      PaginatedAthletes(
        items: (j['items'] as List)
            .map((e) => AthleteModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: j['total'] as int,
        page: j['page'] as int,
        pageSize: j['pageSize'] as int,
      );
}
