import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/athlete_profile/data/models/athlete_profile_model.dart';
import 'package:flutter_application_1/features/athlete_profile/data/repositories/athlete_profile_repository.dart';

/// Structured athlete-profile intake survey. Collects the subset of
/// `AthleteProfile` the plan generator needs — weight, goal, experience,
/// days/week, session length, injuries, equipment — and PUTs it to
/// `/api/athleteprofile/me` when the user is already authenticated. If the
/// backend isn't reachable (or the user ran the survey pre-login) the
/// answers are kept in secure storage as an offline fallback so a later
/// sync can replay them.
///
/// Renamed from `AthleteSurveyPage` to disambiguate from the trainer's
/// custom questionnaire under `features/onboarding/`.
class AthleteProfileSurveyPage extends StatefulWidget {
  const AthleteProfileSurveyPage({super.key});

  @override
  State<AthleteProfileSurveyPage> createState() =>
      _AthleteProfileSurveyPageState();
}

class _AthleteProfileSurveyPageState extends State<AthleteProfileSurveyPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;

  // Step 1 - Weight
  final _weightController = TextEditingController();

  // Step 2 - Goals (Hungarian label)
  String? _selectedGoal;

  // Step 3 - Experience level (enum name)
  String _experienceLevel = AthleteProfileExperienceLevels.beginner;

  // Step 4 - Sport history (free text)
  final _sportHistoryController = TextEditingController();

  // Step 5 - Injuries (Hungarian labels)
  final Set<String> _selectedInjuries = {};

  // Step 6 - Gym frequency (days/week)
  int _gymFrequency = 3;

  // Step 7 - Session minutes
  int _sessionMinutes = 60;

  // Step 8 - Equipment (Hungarian labels)
  final Set<String> _selectedEquipment = {};

  static const _goals = [
    'Fogyás',
    'Izomépítés',
    'Állóképesség',
    'Erőnlét',
    'Általános fitness',
    'Sportspecifikus cél',
  ];

  static const _injuryOptions = [
    'Nincs korábbi sérülés',
    'Térd',
    'Váll',
    'Derék / Hát',
    'Boka',
    'Könyök',
    'Csípő',
    'Csukló',
    'Egyéb',
  ];

  static const _equipmentOptions = [
    'Kézisúlyok',
    'Rúd + tárcsák',
    'Húzódzkodó rúd',
    'Ellenálló szalagok',
    'Edzőgépek',
    'Kardió eszközök',
    'Saját testsúly (nincs eszköz)',
  ];

  // Hungarian survey labels → backend enum / tag values.
  static const _goalToEnum = {
    'Izomépítés': AthleteProfileGoals.hypertrophy,
    'Erőnlét': AthleteProfileGoals.strength,
    'Fogyás': AthleteProfileGoals.fatLoss,
    // The rest fall back to GeneralFitness.
    'Állóképesség': AthleteProfileGoals.generalFitness,
    'Általános fitness': AthleteProfileGoals.generalFitness,
    'Sportspecifikus cél': AthleteProfileGoals.generalFitness,
  };

  static const _injuryToStressTag = {
    'Térd': AthleteProfileStressTags.knee,
    'Váll': AthleteProfileStressTags.shoulder,
    'Derék / Hát': AthleteProfileStressTags.lowerBack,
    'Boka': AthleteProfileStressTags.ankle,
    'Könyök': AthleteProfileStressTags.elbow,
    'Csípő': AthleteProfileStressTags.hip,
    'Csukló': AthleteProfileStressTags.wrist,
    // 'Nincs korábbi sérülés' and 'Egyéb' map to nothing on purpose.
  };

  static const _equipmentToEnum = {
    'Kézisúlyok': AthleteProfileEquipment.dumbbell,
    'Rúd + tárcsák': AthleteProfileEquipment.barbell,
    'Húzódzkodó rúd': AthleteProfileEquipment.bodyweight,
    'Ellenálló szalagok': AthleteProfileEquipment.band,
    'Edzőgépek': AthleteProfileEquipment.machine,
    'Saját testsúly (nincs eszköz)': AthleteProfileEquipment.bodyweight,
    // Kardió eszközök intentionally has no mapping — the plan generator does
    // not use cardio equipment yet.
  };

  int get _totalPages => 8;

  @override
  void dispose() {
    _pageController.dispose();
    _weightController.dispose();
    _sportHistoryController.dispose();
    super.dispose();
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        final w = double.tryParse(_weightController.text.trim());
        return w != null && w > 0;
      case 1:
        return _selectedGoal != null;
      case 4:
        return _selectedInjuries.isNotEmpty;
      case 7:
        return _selectedEquipment.isNotEmpty;
      default:
        return true;
    }
  }

  void _next() {
    if (!_canProceed()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kérjük, válassz legalább egy lehetőséget!')),
      );
      return;
    }
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  AthleteProfileModel _buildProfile() {
    final weight = double.tryParse(_weightController.text.trim());
    final goal = _goalToEnum[_selectedGoal] ?? AthleteProfileGoals.generalFitness;
    final stressTags = _selectedInjuries
        .map((inj) => _injuryToStressTag[inj])
        .whereType<String>()
        .toSet()
        .toList();
    final equipment = _selectedEquipment
        .map((eq) => _equipmentToEnum[eq])
        .whereType<String>()
        .toSet()
        .toList();

    return AthleteProfileModel(
      athleteId: '', // server derives it from the JWT.
      goal: goal,
      experienceLevel: _experienceLevel,
      daysPerWeek: _gymFrequency.clamp(2, 6),
      sessionMinutes: _sessionMinutes.clamp(30, 120),
      availableEquipment: equipment,
      avoidStressTags: stressTags,
      weightKg: weight,
      sportHistory: _sportHistoryController.text.trim().isEmpty
          ? null
          : _sportHistoryController.text.trim(),
    );
  }

  Future<void> _finish() async {
    final profile = _buildProfile();
    // Grab both services up-front so we don't look them up after awaits.
    final repo = context.read<AthleteProfileRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    // Always keep an offline copy — the backend may be unreachable, or the
    // survey may have been triggered before the auth token was issued.
    await const FlutterSecureStorage().write(
      key: 'athlete_profile_survey',
      value: jsonEncode({
        'weightKg': profile.weightKg,
        'goal': profile.goal,
        'goalLabel': _selectedGoal,
        'experienceLevel': profile.experienceLevel,
        'daysPerWeek': profile.daysPerWeek,
        'sessionMinutes': profile.sessionMinutes,
        'availableEquipment': profile.availableEquipment,
        'avoidStressTags': profile.avoidStressTags,
        'sportHistory': profile.sportHistory,
      }),
    );

    if (mounted) setState(() => _isSaving = true);
    bool sentToBackend = false;
    try {
      await repo.upsertMine(profile);
      sentToBackend = true;
    } on AthleteProfileUnauthorizedException {
      // Expected when the survey runs mid-registration — the user isn't
      // logged in yet. The local copy is used as fallback.
    } catch (_) {
      // Network error or 5xx — swallow and keep the local copy.
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(sentToBackend
            ? 'Köszönjük! Profil mentve.'
            : 'Köszönjük! Profil lokálisan mentve, később szinkronizáljuk.'),
      ),
    );
    router.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.of(context).bg,
      appBar: AppBar(
        backgroundColor: DT.of(context).bg,
        elevation: 0,
        leading: _currentPage > 0
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: DT.of(context).textPrimary),
                onPressed: _back,
              )
            : null,
        title: Text(
          '${_currentPage + 1} / $_totalPages',
          style: TextStyle(
            color: DT.of(context).textPrimary,
            fontSize: DT.s4,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentPage + 1) / _totalPages,
            minHeight: 4,
            backgroundColor: DT.of(context).borderLight,
            valueColor: const AlwaysStoppedAnimation<Color>(DT.metricBlue),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildWeightStep(),
                _buildGoalsStep(),
                _buildExperienceStep(),
                _buildSportHistoryStep(),
                _buildInjuriesStep(),
                _buildGymFrequencyStep(),
                _buildSessionMinutesStep(),
                _buildEquipmentStep(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(DT.s5, 0, DT.s5, DT.s6),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DT.metricBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DT.rCardSmall),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _currentPage < _totalPages - 1
                            ? 'Következő'
                            : 'Befejezés',
                        style: const TextStyle(
                          color: DT.textWhite,
                          fontSize: DT.s4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepWrapper({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DT.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: DT.s4),
          Text(
            title,
            style: TextStyle(
              color: DT.of(context).textPrimary,
              fontSize: DT.s8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: DT.s2),
          Text(
            subtitle,
            style: TextStyle(
              color: DT.of(context).textSecondary,
              fontSize: DT.s4,
            ),
          ),
          const SizedBox(height: DT.s5),
          child,
        ],
      ),
    );
  }

  Widget _buildWeightStep() => _buildStepWrapper(
        title: 'Mennyi a testsúlyod?',
        subtitle: 'Ez segít az edzőnek a megfelelő terhelés meghatározásában.',
        child: Column(
          children: [
            const SizedBox(height: DT.s5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: DT.metricBlue,
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '70',
                      hintStyle: TextStyle(
                        color: DT.metricBlue,
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: DT.s2),
                Text(
                  'kg',
                  style: TextStyle(
                    color: DT.of(context).textSecondary,
                    fontSize: DT.s5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DT.s6),
            Text(
              'Csak a kezdő értéket kérjük — ezt később bármikor módosíthatod a profilodban.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DT.of(context).textSecondary,
                fontSize: DT.s3,
              ),
            ),
          ],
        ),
      );

  Widget _buildGoalsStep() => _buildStepWrapper(
        title: 'Mi a célod?',
        subtitle: 'Válassz egyet, ami legjobban leírja a célodat.',
        child: Column(
          children: _goals.map((goal) {
            final isSelected = _selectedGoal == goal;
            return _OptionRow(
              label: goal,
              selected: isSelected,
              onTap: () => setState(() => _selectedGoal = goal),
            );
          }).toList(),
        ),
      );

  Widget _buildExperienceStep() => _buildStepWrapper(
        title: 'Edzettségi szinted',
        subtitle: 'Mennyire ismered az erősítő edzést?',
        child: Column(
          children: AthleteProfileExperienceLevels.all.map((lvl) {
            final isSelected = _experienceLevel == lvl;
            return _OptionRow(
              label: AthleteProfileExperienceLevels.labels[lvl] ?? lvl,
              selected: isSelected,
              onTap: () => setState(() => _experienceLevel = lvl),
            );
          }).toList(),
        ),
      );

  Widget _buildSportHistoryStep() => _buildStepWrapper(
        title: 'Sport előzmények',
        subtitle: 'Milyen sportokat űztél korábban és mennyi ideig?',
        child: TextField(
          controller: _sportHistoryController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Pl. Foci – 8 év, úszás – 3 év, futás alkalmanként...',
            hintStyle: TextStyle(color: DT.of(context).textGrey),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DT.rCardSmall),
              borderSide: BorderSide(color: DT.of(context).borderGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DT.rCardSmall),
              borderSide: BorderSide(color: DT.of(context).borderGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DT.rCardSmall),
              borderSide: const BorderSide(color: DT.metricBlue, width: 2),
            ),
          ),
        ),
      );

  Widget _buildInjuriesStep() => _buildStepWrapper(
        title: 'Korábbi sérülések',
        subtitle:
            'Jelöld meg, ha volt korábbi sérülésed. Többet is választhatsz.',
        child: Wrap(
          spacing: DT.s2,
          runSpacing: DT.s2,
          children: _injuryOptions.map((injury) {
            final isSelected = _selectedInjuries.contains(injury);
            return _ChipOption(
              label: injury,
              selected: isSelected,
              onTap: () => setState(() {
                if (injury == 'Nincs korábbi sérülés') {
                  _selectedInjuries
                    ..clear()
                    ..add(injury);
                } else {
                  _selectedInjuries.remove('Nincs korábbi sérülés');
                  if (isSelected) {
                    _selectedInjuries.remove(injury);
                  } else {
                    _selectedInjuries.add(injury);
                  }
                }
              }),
            );
          }).toList(),
        ),
      );

  Widget _buildGymFrequencyStep() => _buildStepWrapper(
        title: 'Edzés gyakorisága',
        subtitle: 'Hányszor tudsz hetente edzeni?',
        child: Column(
          children: [
            const SizedBox(height: DT.s5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$_gymFrequency',
                  style: const TextStyle(
                    color: DT.metricBlue,
                    fontSize: 72,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: DT.s2),
                Text(
                  'x / hét',
                  style: TextStyle(
                    color: DT.of(context).textSecondary,
                    fontSize: DT.s5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DT.s5),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: DT.metricBlue,
                inactiveTrackColor: DT.of(context).borderGrey,
                thumbColor: DT.metricBlue,
                overlayColor: DT.metricBlue.withValues(alpha: 0.1),
                trackHeight: 6,
              ),
              child: Slider(
                value: _gymFrequency.toDouble(),
                min: 2,
                max: 6,
                divisions: 4,
                onChanged: (val) => setState(() => _gymFrequency = val.round()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DT.s2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('2x',
                      style:
                          TextStyle(color: DT.of(context).textSecondary)),
                  Text('6x',
                      style:
                          TextStyle(color: DT.of(context).textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildSessionMinutesStep() => _buildStepWrapper(
        title: 'Egy edzés hossza',
        subtitle: 'Mennyi időt tudsz egy edzésre szánni?',
        child: Column(
          children: [
            const SizedBox(height: DT.s5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$_sessionMinutes',
                  style: const TextStyle(
                    color: DT.metricBlue,
                    fontSize: 72,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: DT.s2),
                Text(
                  'perc',
                  style: TextStyle(
                    color: DT.of(context).textSecondary,
                    fontSize: DT.s5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DT.s5),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: DT.metricBlue,
                inactiveTrackColor: DT.of(context).borderGrey,
                thumbColor: DT.metricBlue,
                overlayColor: DT.metricBlue.withValues(alpha: 0.1),
                trackHeight: 6,
              ),
              child: Slider(
                value: _sessionMinutes.toDouble(),
                min: 30,
                max: 120,
                divisions: 18,
                onChanged: (val) =>
                    setState(() => _sessionMinutes = val.round()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DT.s2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('30 perc',
                      style:
                          TextStyle(color: DT.of(context).textSecondary)),
                  Text('120 perc',
                      style:
                          TextStyle(color: DT.of(context).textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildEquipmentStep() => _buildStepWrapper(
        title: 'Elérhető eszközök',
        subtitle:
            'Milyen edzőeszközökhöz van hozzáférésed? Többet is választhatsz.',
        child: Wrap(
          spacing: DT.s2,
          runSpacing: DT.s2,
          children: _equipmentOptions.map((equipment) {
            final isSelected = _selectedEquipment.contains(equipment);
            return _ChipOption(
              label: equipment,
              selected: isSelected,
              onTap: () => setState(() {
                if (isSelected) {
                  _selectedEquipment.remove(equipment);
                } else {
                  _selectedEquipment.add(equipment);
                }
              }),
            );
          }).toList(),
        ),
      );
}

class _OptionRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: DT.s3),
        padding:
            const EdgeInsets.symmetric(horizontal: DT.s4, vertical: DT.s4),
        decoration: BoxDecoration(
          color: selected ? DT.metricBlue.withValues(alpha: 0.08) : Colors.white,
          border: Border.all(
            color: selected ? DT.metricBlue : DT.of(context).borderGrey,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(DT.rCardSmall),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? DT.metricBlue : DT.of(context).iconLight,
            ),
            const SizedBox(width: DT.s3),
            Text(
              label,
              style: TextStyle(
                color: selected ? DT.metricBlue : DT.of(context).textPrimary,
                fontSize: DT.s4,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChipOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: DT.s4, vertical: DT.s3),
        decoration: BoxDecoration(
          color: selected ? DT.metricBlue.withValues(alpha: 0.08) : Colors.white,
          border: Border.all(
            color: selected ? DT.metricBlue : DT.of(context).borderGrey,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(DT.rChip),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? DT.metricBlue : DT.of(context).textPrimary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
