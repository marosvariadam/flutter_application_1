/// Hungarian greeting for the time of day: „Jó reggelt” from 5:00 to 9:59,
/// „Szép napot” until 17:59, „Jó estét” otherwise.
String timeOfDayGreeting(DateTime time) {
  if (time.hour >= 5 && time.hour < 10) return 'Jó reggelt';
  if (time.hour >= 10 && time.hour < 18) return 'Szép napot';
  return 'Jó estét';
}
