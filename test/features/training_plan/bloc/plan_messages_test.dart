import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/training_plan/bloc/plan_messages.dart';

void main() {
  const fallback = 'Alapértelmezett.';

  // Every message string the backend's PlanController / PlanMaterializer
  // can return in a 400 or 409 body.
  const cases = {
    'Athlete has no AthleteProfile - fill it in before generating.':
        'A sportolónak még nincs profilja — töltsd ki a generálás előtt.',
    'Athlete has no AthleteProfile.':
        'A sportolónak még nincs profilja — töltsd ki a generálás előtt.',
    'Invalid trainingBlockId.':
        'A kiválasztott tréningblokk nem ehhez a sportolóhoz tartozik.',
    'mode must be Constraint, LlmOnly, or Hybrid.':
        'Ismeretlen generálási mód.',
    'athleteId is required.': 'Hiányzik a sportoló azonosítója.',
    'instruction is required.': 'Írd le, mit változtassunk a terven.',
    'Accept the plan before materializing it.':
        'Előbb fogadd el a tervet, csak utána ütemezhető.',
    'Plan is already materialized.':
        'A terv már be van ütemezve, ezért nem módosítható.',
    'Plan is already materialized; create a new draft to change it.':
        'A terv már be van ütemezve, ezért nem módosítható.',
    'Plan already materialized.':
        'A terv már be van ütemezve, ezért nem módosítható.',
    'plan.Weeks must be in 1..52 (got 0). (Parameter \'plan\')':
        'A terv nem ütemezhető: ellenőrizd a hetek és a napok számát.',
    'plan.Days.Count must be in 1..7 (got 0).':
        'A terv nem ütemezhető: ellenőrizd a hetek és a napok számát.',
    'every PlanDay.DayIndex must be in 0..6.':
        'A terv nem ütemezhető: ellenőrizd a hetek és a napok számát.',
    'plan.Weeks * plan.Days.Count (500) exceeds the materialization cap of 400.':
        'A terv nem ütemezhető: ellenőrizd a hetek és a napok számát.',
    'Plan not found.': 'A terv nem található.',
  };

  cases.forEach((server, hungarian) {
    test('maps "$server"', () {
      expect(planServerMessageHu(server, fallback: fallback), hungarian);
    });
  });

  test('unknown, empty or missing messages use the fallback', () {
    expect(planServerMessageHu('Totally new error', fallback: fallback),
        fallback);
    expect(planServerMessageHu('', fallback: fallback), fallback);
    expect(planServerMessageHu(null, fallback: fallback), fallback);
  });
}
