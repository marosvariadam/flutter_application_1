import 'package:flutter_application_1/features/autoregulation/data/models/autoregulation_model.dart';

/// "82.5" / "80" — drops a trailing ".0" so whole numbers read naturally.
/// Loads are rounded to 2.5 kg server-side, so one decimal is enough.
String formatKg(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

/// Chip text, e.g. "+2.5 kg — minden szett RPE 7". Empty when the
/// suggestion has no weight to apply.
String autoregulationChipLabel(AutoregulationSuggestionModel s) {
  final next = s.suggestedWeightKg;
  if (next == null) return '';
  if (s.isDeload) {
    return 'Deload: ${formatKg(next)} kg · ${s.suggestedSets} szett';
  }
  final rpe = 'minden szett RPE ${s.targetRpe}';
  final delta = s.deltaKg;
  if (delta == null) return '${formatKg(next)} kg — $rpe';
  if (delta.abs() < 0.01) return '${formatKg(next)} kg marad — $rpe';
  final sign = delta > 0 ? '+' : '−';
  return '$sign${formatKg(delta.abs())} kg — $rpe';
}

/// Hungarian explanation shown on long-press. Built client-side because the
/// backend `reason` is English.
String autoregulationExplanation(AutoregulationSuggestionModel s) {
  final buffer = StringBuffer();
  if (s.isDeload) {
    buffer.write('Deload hét: −10% terhelés, −40% szettszám.');
  } else if (s.scheme == 'RpeBased') {
    buffer.write('Az e1RM-becslés alapján a cél-RPE-hez illesztett súly.');
  } else if (s.outcome == AutoregulationOutcomes.increase) {
    buffer.write(
        'Minden szett elérte a tartomány tetejét a cél-RPE-n belül.');
  } else if (s.outcome == AutoregulationOutcomes.decrease) {
    buffer.write('Túl magas RPE vagy kevés ismétlés — 5% visszalépés.');
  } else {
    buffer.write(
        'Maradj ezen a súlyon, és gyűjts ismétléseket a tartomány tetejéig.');
  }
  final last = s.lastLogged;
  if (last != null) {
    final rpe = last.rpe == null ? '' : ' @ RPE ${formatKg(last.rpe!)}';
    buffer.write('\nElőző: ${formatKg(last.weightKg)} kg × ${last.reps}$rpe');
  }
  buffer.write('\nKoppints az alkalmazáshoz.');
  return buffer.toString();
}
