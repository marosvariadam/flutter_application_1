import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/athlete_profile/data/models/athlete_profile_model.dart';
import 'package:flutter_application_1/features/athlete_profile/data/survey_profile_mapper.dart';

AthleteProfileModel _map({
  String weight = '72',
  String? goal = 'Izomépítés',
  String level = AthleteProfileExperienceLevels.intermediate,
  String history = '',
  List<String> injuries = const [AthleteSurveyOptions.noInjury],
  int days = 4,
  int minutes = 60,
  List<String> equipment = const ['Kézisúlyok'],
}) =>
    profileFromSurvey(
      weightText: weight,
      goalLabel: goal,
      experienceLevel: level,
      sportHistory: history,
      injuryLabels: injuries,
      daysPerWeek: days,
      sessionMinutes: minutes,
      equipmentLabels: equipment,
    );

void main() {
  group('parseSurveyWeight', () {
    test('accepts dot and Hungarian comma decimals', () {
      expect(parseSurveyWeight('72.5'), 72.5);
      expect(parseSurveyWeight(' 72,5 '), 72.5);
      expect(parseSurveyWeight('80'), 80);
    });

    test('rejects empty, zero, negative and garbage input', () {
      expect(parseSurveyWeight(''), isNull);
      expect(parseSurveyWeight('0'), isNull);
      expect(parseSurveyWeight('-5'), isNull);
      expect(parseSurveyWeight('abc'), isNull);
    });
  });

  group('profileFromSurvey', () {
    test('maps every goal label as the spec says', () {
      expect(_map(goal: 'Izomépítés').goal, AthleteProfileGoals.hypertrophy);
      expect(_map(goal: 'Erőnlét').goal, AthleteProfileGoals.strength);
      expect(_map(goal: 'Fogyás').goal, AthleteProfileGoals.fatLoss);
      for (final other in [
        'Állóképesség',
        'Általános fitness',
        'Sportspecifikus cél',
        null,
      ]) {
        expect(_map(goal: other).goal, AthleteProfileGoals.generalFitness,
            reason: '$other');
      }
    });

    test('every goal option has a mapping', () {
      for (final g in AthleteSurveyOptions.goals) {
        expect(AthleteSurveyOptions.goalToEnum[g], isNotNull, reason: g);
      }
    });

    test('injuries become stress tags; "none" and "Egyéb" add nothing', () {
      final p = _map(injuries: [
        'Térd',
        'Váll',
        'Derék / Hát',
        'Boka',
        'Csukló',
        'Könyök',
        'Csípő',
        'Egyéb',
      ]);
      expect(p.avoidStressTags.toSet(), {
        AthleteProfileStressTags.knee,
        AthleteProfileStressTags.shoulder,
        AthleteProfileStressTags.lowerBack,
        AthleteProfileStressTags.ankle,
        AthleteProfileStressTags.wrist,
        AthleteProfileStressTags.elbow,
        AthleteProfileStressTags.hip,
      });
      expect(_map().avoidStressTags, isEmpty);
    });

    test('equipment maps to enums, deduplicated, cardio dropped', () {
      final p = _map(equipment: [
        'Húzódzkodó rúd',
        'Saját testsúly (nincs eszköz)',
        'Rúd + tárcsák',
        'Kardió eszközök',
      ]);
      expect(p.availableEquipment, [
        AthleteProfileEquipment.bodyweight,
        AthleteProfileEquipment.barbell,
      ]);
      expect(_map(equipment: ['Edzőgépek', 'Ellenálló szalagok'])
              .availableEquipment,
          [AthleteProfileEquipment.machine, AthleteProfileEquipment.band]);
    });

    test('clamps days and minutes to the backend ranges', () {
      final low = _map(days: 1, minutes: 10);
      expect([low.daysPerWeek, low.sessionMinutes], [2, 30]);
      final high = _map(days: 7, minutes: 200);
      expect([high.daysPerWeek, high.sessionMinutes], [6, 120]);
    });

    test('weight, level and trimmed sport history are carried over', () {
      final p = _map(
        weight: '68,5',
        level: AthleteProfileExperienceLevels.advanced,
        history: '  Foci 8 év  ',
      );
      expect(p.weightKg, 68.5);
      expect(p.experienceLevel, AthleteProfileExperienceLevels.advanced);
      expect(p.sportHistory, 'Foci 8 év');
      expect(_map(history: '   ').sportHistory, isNull);
      expect(p.athleteId, '');
    });
  });
}
