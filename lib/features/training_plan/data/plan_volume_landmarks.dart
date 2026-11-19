import 'package:flutter_application_1/features/athlete_profile/data/models/athlete_profile_model.dart';

/// Weekly working-set targets per muscle group per experience level. Mirrors
/// `Planning/VolumeLandmarks.cs` on the backend — kept client-side so the
/// editor's volume chart can draw MEV / MAV / MRV reference lines without
/// a round trip.
///
/// `mev` = minimum effective volume, `mav` = maximum adaptive volume,
/// `mrv` = maximum recoverable volume. Values follow Renaissance
/// Periodization published ranges for natural lifters; tune the table on
/// both sides together when you have better internal data.
class VolumeRange {
  final int mev;
  final int mav;
  final int mrv;
  const VolumeRange(this.mev, this.mav, this.mrv);
}

/// Canonical primary-muscle names the chart and the backend seed share.
/// Trainer-authored exercises may use arbitrary names; we draw them with
/// a permissive 0..∞ range (no MEV/MRV lines).
const List<String> kChartMuscleGroups = [
  'Chest',
  'Back',
  'Shoulders',
  'Legs',
  'Arms',
  'Core',
];

const Map<String, String> kChartMuscleGroupLabels = {
  'Chest': 'Mell',
  'Back': 'Hát',
  'Shoulders': 'Váll',
  'Legs': 'Láb',
  'Arms': 'Kar',
  'Core': 'Törzs',
};

/// Private lookup table — `rangeFor` is the public entry point so callers
/// never have to know about default ranges or enum-name casing.
const Map<String, Map<String, VolumeRange>> _table = {
  AthleteProfileExperienceLevels.beginner: {
    'Chest': VolumeRange(6, 10, 16),
    'Back': VolumeRange(8, 12, 18),
    'Shoulders': VolumeRange(6, 10, 16),
    'Legs': VolumeRange(8, 12, 18),
    'Arms': VolumeRange(4, 8, 14),
    'Core': VolumeRange(0, 8, 16),
  },
  AthleteProfileExperienceLevels.intermediate: {
    'Chest': VolumeRange(8, 14, 22),
    'Back': VolumeRange(10, 16, 25),
    'Shoulders': VolumeRange(8, 14, 22),
    'Legs': VolumeRange(10, 16, 25),
    'Arms': VolumeRange(6, 12, 20),
    'Core': VolumeRange(0, 12, 25),
  },
  AthleteProfileExperienceLevels.advanced: {
    'Chest': VolumeRange(10, 18, 26),
    'Back': VolumeRange(12, 20, 30),
    'Shoulders': VolumeRange(10, 18, 26),
    'Legs': VolumeRange(12, 20, 30),
    'Arms': VolumeRange(8, 16, 25),
    'Core': VolumeRange(0, 16, 30),
  },
};

/// Returns the volume range for a (muscle, experience) pair, or a
/// permissive 0..∞ range for unknown muscle names.
VolumeRange rangeFor(String muscleGroup, String experienceLevel) {
  final level = _table[experienceLevel] ?? _table[AthleteProfileExperienceLevels.beginner]!;
  return level[muscleGroup] ?? const VolumeRange(0, 0, 999);
}
