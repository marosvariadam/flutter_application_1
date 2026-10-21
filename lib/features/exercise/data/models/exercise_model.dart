/// A library exercise plus optional per-athlete usage metadata.
///
/// Backend fields `movementPattern` and `minLevel` are serialized as the
/// C# enum names (`HorizontalPush`, `Beginner`, …) — kept as strings here so
/// the UI can label them without an enum dependency. `equipmentTypes` is the
/// new typed list; `equipment` is kept so legacy screens that still render a
/// single free-text equipment string keep working.
class ExerciseModel {
  final String id;
  final String name;
  final String muscleGroup;
  final List<String> secondaryMuscleGroups;
  final String? description;

  /// Legacy free-text equipment. On post-migration documents this is a
  /// comma-joined view of [equipmentTypes]; may still be present as a raw
  /// string on older seed docs.
  final String? equipment;

  /// Typed equipment list from Phase 0 of the plan generator spec.
  final List<String> equipmentTypes;

  /// `HorizontalPush`, `VerticalPull`, `Squat`, … or null for legacy docs.
  final String? movementPattern;

  /// Null on legacy docs; false on isolation moves, true on compounds.
  final bool? isCompound;

  /// `Beginner`, `Intermediate`, `Advanced` or null for legacy docs.
  final String? minLevel;

  /// Joint/region tags the exercise loads: `knee`, `lower_back`, `shoulder`…
  final List<String> stressTags;

  final String? createdByTrainerId;

  /// How many times this exercise was assigned to a specific athlete.
  /// Only populated by the for-athlete endpoint; null otherwise.
  final int? usageCount;

  const ExerciseModel({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.secondaryMuscleGroups = const [],
    this.description,
    this.equipment,
    this.equipmentTypes = const [],
    this.movementPattern,
    this.isCompound,
    this.minLevel,
    this.stressTags = const [],
    this.createdByTrainerId,
    this.usageCount,
  });

  /// Custom exercises were created by a specific trainer.
  bool get isCustom => createdByTrainerId != null;

  factory ExerciseModel.fromJson(Map<String, dynamic> j) {
    // After the Phase 0 migration `equipment` arrives as a List<String> of
    // enum names; before it, as a free-text string. Keep both views so older
    // screens keep rendering while the new catalogue uses the typed list.
    final rawEquipment = j['equipment'];
    List<String> equipmentTypes = const [];
    String? equipment;
    if (rawEquipment is List) {
      equipmentTypes = rawEquipment.map((e) => e.toString()).toList();
      equipment = equipmentTypes.isEmpty ? null : equipmentTypes.join(', ');
    } else if (rawEquipment is String) {
      equipment = rawEquipment;
    }

    return ExerciseModel(
      id: j['id'] as String,
      name: j['name'] as String,
      muscleGroup: j['muscleGroup'] as String? ?? '',
      secondaryMuscleGroups: (j['secondaryMuscleGroups'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      description: j['description'] as String?,
      equipment: equipment,
      equipmentTypes: equipmentTypes,
      movementPattern: j['movementPattern'] as String?,
      isCompound: j['isCompound'] as bool?,
      minLevel: j['minLevel'] as String?,
      stressTags: (j['stressTags'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdByTrainerId: j['createdByTrainerId'] as String?,
      usageCount: (j['usageCount'] as num?)?.toInt(),
    );
  }

  /// Mirrors the backend `UpdateExerciseRequest`. Omits per-request-only
  /// fields (`usageCount`) and server-managed ids where appropriate.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'muscleGroup': muscleGroup,
        'secondaryMuscleGroups': secondaryMuscleGroups,
        if (description != null) 'description': description,
        if (equipmentTypes.isNotEmpty) 'equipment': equipmentTypes,
        if (movementPattern != null) 'movementPattern': movementPattern,
        if (isCompound != null) 'isCompound': isCompound,
        if (minLevel != null) 'minLevel': minLevel,
        'stressTags': stressTags,
        if (createdByTrainerId != null)
          'createdByTrainerId': createdByTrainerId,
        if (usageCount != null) 'usageCount': usageCount,
      };
}

/// Wraps a plain array from the backend so existing blocs don't need to change.
class PaginatedExercises {
  final List<ExerciseModel> items;
  final bool hasMore;

  const PaginatedExercises({required this.items, this.hasMore = false});

  factory PaginatedExercises.fromList(List<dynamic> list) => PaginatedExercises(
        items: list
            .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
