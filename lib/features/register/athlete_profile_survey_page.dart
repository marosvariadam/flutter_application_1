import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/athlete_profile/data/models/athlete_profile_model.dart';
import 'package:flutter_application_1/features/athlete_profile/data/repositories/athlete_profile_repository.dart';
import 'package:flutter_application_1/features/athlete_profile/data/survey_profile_mapper.dart';
import 'package:flutter_application_1/features/register/widgets/survey_widgets.dart';

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

  static const _goals = AthleteSurveyOptions.goals;
  static const _injuryOptions = AthleteSurveyOptions.injuries;
  static const _equipmentOptions = AthleteSurveyOptions.equipment;

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
        return parseSurveyWeight(_weightController.text) != null;
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
        SnackBar(
          content: Text(_currentPage == 0
              ? 'Add meg a testsúlyodat kilogrammban (pl. 72,5).'
              : 'Kérjük, válassz legalább egy lehetőséget!'),
        ),
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

  AthleteProfileModel _buildProfile() => profileFromSurvey(
        weightText: _weightController.text,
        goalLabel: _selectedGoal,
        experienceLevel: _experienceLevel,
        sportHistory: _sportHistoryController.text,
        injuryLabels: _selectedInjuries,
        daysPerWeek: _gymFrequency,
        sessionMinutes: _sessionMinutes,
        equipmentLabels: _selectedEquipment,
      );

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
                tooltip: 'Vissza',
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
            valueColor: AlwaysStoppedAnimation<Color>(DT.of(context).accentPrimary),
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
                  backgroundColor: DT.of(context).accentPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DT.rCardSmall),
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: DT.of(context).textOnAccent),
                      )
                    : Text(
                        _currentPage < _totalPages - 1
                            ? 'Következő'
                            : 'Befejezés',
                        style: TextStyle(
                          color: DT.of(context).textOnAccent,
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
                    style: TextStyle(
                      color: DT.of(context).accentPrimary,
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '70',
                      hintStyle: TextStyle(
                        color: DT.of(context).accentPrimary,
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
            return SurveyOptionRow(
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
            return SurveyOptionRow(
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
            fillColor: DT.of(context).cardSurface,
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
              borderSide: BorderSide(color: DT.of(context).accentPrimary, width: 2),
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
            return SurveyChipOption(
              label: injury,
              selected: isSelected,
              onTap: () => setState(() {
                if (injury == AthleteSurveyOptions.noInjury) {
                  _selectedInjuries
                    ..clear()
                    ..add(injury);
                } else {
                  _selectedInjuries.remove(AthleteSurveyOptions.noInjury);
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
        child: SurveyNumberSlider(
          value: _gymFrequency,
          min: 2,
          max: 6,
          divisions: 4,
          unit: 'x / hét',
          minLabel: '2x',
          maxLabel: '6x',
          onChanged: (v) => setState(() => _gymFrequency = v),
        ),
      );

  Widget _buildSessionMinutesStep() => _buildStepWrapper(
        title: 'Egy edzés hossza',
        subtitle: 'Mennyi időt tudsz egy edzésre szánni?',
        child: SurveyNumberSlider(
          value: _sessionMinutes,
          min: 30,
          max: 120,
          divisions: 18,
          unit: 'perc',
          minLabel: '30 perc',
          maxLabel: '120 perc',
          onChanged: (v) => setState(() => _sessionMinutes = v),
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
            return SurveyChipOption(
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
