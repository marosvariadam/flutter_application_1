/// The plan API answers 400 / 409 with English `message` strings. These are
/// the ones it can send; each maps to Hungarian copy. Anything unknown
/// falls back to [fallback] so English never reaches the UI.
String planServerMessageHu(String? serverMessage, {required String fallback}) {
  final m = (serverMessage ?? '').toLowerCase();
  if (m.isEmpty) return fallback;
  if (m.contains('athleteprofile')) {
    return 'A sportolónak még nincs profilja — töltsd ki a generálás előtt.';
  }
  if (m.contains('trainingblockid')) {
    return 'A kiválasztott tréningblokk nem ehhez a sportolóhoz tartozik.';
  }
  if (m.contains('mode must be')) return 'Ismeretlen generálási mód.';
  if (m.contains('athleteid is required')) {
    return 'Hiányzik a sportoló azonosítója.';
  }
  if (m.contains('instruction is required')) {
    return 'Írd le, mit változtassunk a terven.';
  }
  if (m.contains('accept the plan before')) {
    return 'Előbb fogadd el a tervet, csak utána ütemezhető.';
  }
  if (m.contains('already materialized')) {
    return 'A terv már be van ütemezve, ezért nem módosítható.';
  }
  if (m.contains('plan.weeks') ||
      m.contains('plan.days') ||
      m.contains('dayindex') ||
      m.contains('materialization cap')) {
    return 'A terv nem ütemezhető: ellenőrizd a hetek és a napok számát.';
  }
  if (m.contains('not found')) return 'A terv nem található.';
  return fallback;
}
