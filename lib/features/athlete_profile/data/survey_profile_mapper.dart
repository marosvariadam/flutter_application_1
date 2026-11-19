import 'package:flutter_application_1/features/athlete_profile/data/models/athlete_profile_model.dart';

/// Answer options of the register-time profile survey (Hungarian labels as
/// shown to the athlete) and how each maps to the backend vocabulary.
class AthleteSurveyOptions {
  static const goals = [
    'Fogyás',
    'Izomépítés',
    'Állóképesség',
    'Erőnlét',
    'Általános fitness',
    'Sportspecifikus cél',
  ];

  static const noInjury = 'Nincs korábbi sérülés';

  static const injuries = [
    noInjury,
    'Térd',
    'Váll',
    'Derék / Hát',
    'Boka',
    'Könyök',
    'Csípő',
    'Csukló',
    'Egyéb',
  ];

  static const equipment = [
    'Kézisúlyok',
    'Rúd + tárcsák',
    'Húzódzkodó rúd',
    'Ellenálló szalagok',
    'Edzőgépek',
    'Kardió eszközök',
    'Saját testsúly (nincs eszköz)',
  ];

  /// Goals without a dedicated enum fall back to GeneralFitness.
  static const goalToEnum = {
    'Izomépítés': AthleteProfileGoals.hypertrophy,
    'Erőnlét': AthleteProfileGoals.strength,
    'Fogyás': AthleteProfileGoals.fatLoss,
    'Állóképesség': AthleteProfileGoals.generalFitness,
    'Általános fitness': AthleteProfileGoals.generalFitness,
    'Sportspecifikus cél': AthleteProfileGoals.generalFitness,
  };

  /// "No injury" and "Egyéb" deliberately map to nothing.
  static const injuryToStressTag = {
    'Térd': AthleteProfileStressTags.knee,
    'Váll': AthleteProfileStressTags.shoulder,
    'Derék / Hát': AthleteProfileStressTags.lowerBack,
    'Boka': AthleteProfileStressTags.ankle,
    'Könyök': AthleteProfileStressTags.elbow,
    'Csípő': AthleteProfileStressTags.hip,
    'Csukló': AthleteProfileStressTags.wrist,
  };

  /// Cardio equipment has no mapping: the plan generator doesn't use it.
  static const equipmentToEnum = {
    'Kézisúlyok': AthleteProfileEquipment.dumbbell,
    'Rúd + tárcsák': AthleteProfileEquipment.barbell,
    'Húzódzkodó rúd': AthleteProfileEquipment.bodyweight,
    'Ellenálló szalagok': AthleteProfileEquipment.band,
    'Edzőgépek': AthleteProfileEquipment.machine,
    'Saját testsúly (nincs eszköz)': AthleteProfileEquipment.bodyweight,
  };
}

/// Body weight typed by the athlete, accepting the Hungarian decimal comma
/// ("72,5"). Null for empty, unparsable or non-positive input.
double? parseSurveyWeight(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  return value != null && value > 0 ? value : null;
}

/// Builds the profile the survey PUTs to `/api/athleteprofile/me`. The
/// athlete id is left empty: the server takes it from the JWT.
AthleteProfileModel profileFromSurvey({
  required String weightText,
  required String? goalLabel,
  required String experienceLevel,
  required String sportHistory,
  required Iterable<String> injuryLabels,
  required int daysPerWeek,
  required int sessionMinutes,
  required Iterable<String> equipmentLabels,
}) {
  final history = sportHistory.trim();
  return AthleteProfileModel(
    athleteId: '',
    goal: AthleteSurveyOptions.goalToEnum[goalLabel] ??
        AthleteProfileGoals.generalFitness,
    experienceLevel: experienceLevel,
    daysPerWeek: daysPerWeek.clamp(2, 6),
    sessionMinutes: sessionMinutes.clamp(30, 120),
    availableEquipment: equipmentLabels
        .map((e) => AthleteSurveyOptions.equipmentToEnum[e])
        .whereType<String>()
        .toSet()
        .toList(),
    avoidStressTags: injuryLabels
        .map((i) => AthleteSurveyOptions.injuryToStressTag[i])
        .whereType<String>()
        .toSet()
        .toList(),
    weightKg: parseSurveyWeight(weightText),
    sportHistory: history.isEmpty ? null : history,
  );
}
