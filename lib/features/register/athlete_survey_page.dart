import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';

class AthleteSurveyPage extends StatefulWidget {
  const AthleteSurveyPage({super.key});

  @override
  State<AthleteSurveyPage> createState() => _AthleteSurveyPageState();
}

class _AthleteSurveyPageState extends State<AthleteSurveyPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 5;

  // Step 1 — Goals
  String? _selectedGoal;

  // Step 2 — Sport history
  final _sportHistoryController = TextEditingController();

  // Step 3 — Previous injuries
  final Set<String> _selectedInjuries = {};

  // Step 4 — Gym frequency
  int _gymFrequency = 3;

  // Step 5 — Equipment
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

  @override
  void dispose() {
    _pageController.dispose();
    _sportHistoryController.dispose();
    super.dispose();
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        return _selectedGoal != null;
      case 2:
        return _selectedInjuries.isNotEmpty;
      case 4:
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

  Future<void> _finish() async {
    const storage = FlutterSecureStorage();
    await storage.write(
      key: 'athlete_survey',
      value: jsonEncode({
        'goal': _selectedGoal,
        'sportHistory': _sportHistoryController.text.trim(),
        'injuries': _selectedInjuries.toList(),
        'gymFrequency': _gymFrequency,
        'equipment': _selectedEquipment.toList(),
      }),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Köszönjük! Profil sikeresen létrehozva.')),
    );
    context.go('/login');
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
                _buildGoalsStep(),
                _buildSportHistoryStep(),
                _buildInjuriesStep(),
                _buildGymFrequencyStep(),
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
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DT.metricBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DT.rCardSmall),
                  ),
                ),
                child: Text(
                  _currentPage < _totalPages - 1 ? 'Következő' : 'Befejezés',
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

  // ── Step 1: Goals ────────────────────────────────────────────────────────────

  Widget _buildGoalsStep() {
    return _buildStepWrapper(
      title: 'Mi a célod?',
      subtitle: 'Válassz egyet, ami legjobban leírja a célodat.',
      child: Column(
        children: _goals.map((goal) {
          final isSelected = _selectedGoal == goal;
          return GestureDetector(
            onTap: () => setState(() => _selectedGoal = goal),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: DT.s3),
              padding: const EdgeInsets.symmetric(
                  horizontal: DT.s4, vertical: DT.s4),
              decoration: BoxDecoration(
                color: isSelected
                    ? DT.metricBlue.withOpacity(0.08)
                    : Colors.white,
                border: Border.all(
                  color: isSelected ? DT.metricBlue : DT.of(context).borderGrey,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(DT.rCardSmall),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected ? DT.metricBlue : DT.of(context).iconLight,
                  ),
                  const SizedBox(width: DT.s3),
                  Text(
                    goal,
                    style: TextStyle(
                      color:
                          isSelected ? DT.metricBlue : DT.of(context).textPrimary,
                      fontSize: DT.s4,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Step 2: Sport history ────────────────────────────────────────────────────

  Widget _buildSportHistoryStep() {
    return _buildStepWrapper(
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
            borderSide:
                const BorderSide(color: DT.metricBlue, width: 2),
          ),
        ),
      ),
    );
  }

  // ── Step 3: Previous injuries ────────────────────────────────────────────────

  Widget _buildInjuriesStep() {
    return _buildStepWrapper(
      title: 'Korábbi sérülések',
      subtitle:
          'Jelöld meg, ha volt korábbi sérülésed. Többet is választhatsz.',
      child: Wrap(
        spacing: DT.s2,
        runSpacing: DT.s2,
        children: _injuryOptions.map((injury) {
          final isSelected = _selectedInjuries.contains(injury);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (injury == 'Nincs korábbi sérülés') {
                  _selectedInjuries.clear();
                  _selectedInjuries.add(injury);
                } else {
                  _selectedInjuries.remove('Nincs korábbi sérülés');
                  if (isSelected) {
                    _selectedInjuries.remove(injury);
                  } else {
                    _selectedInjuries.add(injury);
                  }
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: DT.s4, vertical: DT.s3),
              decoration: BoxDecoration(
                color: isSelected
                    ? DT.metricBlue.withOpacity(0.08)
                    : Colors.white,
                border: Border.all(
                  color: isSelected ? DT.metricBlue : DT.of(context).borderGrey,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(DT.rChip),
              ),
              child: Text(
                injury,
                style: TextStyle(
                  color:
                      isSelected ? DT.metricBlue : DT.of(context).textPrimary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Step 4: Gym frequency ────────────────────────────────────────────────────

  Widget _buildGymFrequencyStep() {
    return _buildStepWrapper(
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
              overlayColor: DT.metricBlue.withOpacity(0.1),
              trackHeight: 6,
            ),
            child: Slider(
              value: _gymFrequency.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              onChanged: (val) =>
                  setState(() => _gymFrequency = val.round()),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: DT.s2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1x', style: TextStyle(color: DT.of(context).textSecondary)),
                Text('7x', style: TextStyle(color: DT.of(context).textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 5: Equipment ────────────────────────────────────────────────────────

  Widget _buildEquipmentStep() {
    return _buildStepWrapper(
      title: 'Elérhető eszközök',
      subtitle:
          'Milyen edzőeszközökhöz van hozzáférésed? Többet is választhatsz.',
      child: Wrap(
        spacing: DT.s2,
        runSpacing: DT.s2,
        children: _equipmentOptions.map((equipment) {
          final isSelected = _selectedEquipment.contains(equipment);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedEquipment.remove(equipment);
                } else {
                  _selectedEquipment.add(equipment);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: DT.s4, vertical: DT.s3),
              decoration: BoxDecoration(
                color: isSelected
                    ? DT.metricBlue.withOpacity(0.08)
                    : Colors.white,
                border: Border.all(
                  color: isSelected ? DT.metricBlue : DT.of(context).borderGrey,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(DT.rChip),
              ),
              child: Text(
                equipment,
                style: TextStyle(
                  color:
                      isSelected ? DT.metricBlue : DT.of(context).textPrimary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
