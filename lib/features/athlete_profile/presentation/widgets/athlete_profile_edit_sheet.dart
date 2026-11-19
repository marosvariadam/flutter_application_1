import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/athlete_profile/bloc/athlete_profile_cubit.dart';
import 'package:flutter_application_1/features/athlete_profile/data/models/athlete_profile_model.dart';

/// Trainer's edit sheet for an athlete's structured profile, including the
/// muscle-group priority sliders (0.5–1.5). Saves through the
/// [AthleteProfileCubit] it is given and closes itself on success.
class AthleteProfileEditSheet extends StatefulWidget {
  final String athleteId;
  final AthleteProfileModel initial;
  const AthleteProfileEditSheet(
      {super.key, required this.athleteId, required this.initial});

  @override
  State<AthleteProfileEditSheet> createState() => _AthleteProfileEditSheetState();
}

class _AthleteProfileEditSheetState extends State<AthleteProfileEditSheet> {
  late String _goal;
  late String _experience;
  late int _daysPerWeek;
  late int _sessionMinutes;
  late Set<String> _equipment;
  late Set<String> _avoidTags;
  late Map<String, double> _priority;

  static const _muscleGroups = <String>[
    'Chest', 'Back', 'Shoulders', 'Legs', 'Arms', 'Core',
  ];

  @override
  void initState() {
    super.initState();
    _goal = widget.initial.goal;
    _experience = widget.initial.experienceLevel;
    _daysPerWeek = widget.initial.daysPerWeek;
    _sessionMinutes = widget.initial.sessionMinutes;
    _equipment = widget.initial.availableEquipment.toSet();
    _avoidTags = widget.initial.avoidStressTags.toSet();
    _priority = {
      for (final g in _muscleGroups)
        g: widget.initial.muscleGroupPriority[g] ?? kProfilePriorityDefault,
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AthleteProfileCubit, AthleteProfileState>(
      listener: (ctx, state) {
        if (state is AthleteProfileLoaded) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil mentve.')),
          );
        } else if (state is AthleteProfileSaveFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.6,
          expand: false,
          builder: (_, scrollCtrl) => Column(
            children: [
              _SheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(DT.s4, DT.s3, DT.s4, DT.s2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Profil szerkesztése',
                          style: TextStyle(
                              fontSize: DT.s4,
                              fontWeight: FontWeight.w700,
                              color: DT.of(context).textPrimary)),
                    ),
                    BlocBuilder<AthleteProfileCubit, AthleteProfileState>(
                      builder: (c, state) {
                        final isSaving = state is AthleteProfileSaving;
                        return TextButton(
                          onPressed: isSaving ? null : _save,
                          child: isSaving
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Text('Mentés',
                                  style: TextStyle(
                                      color: DT.metricBlue,
                                      fontWeight: FontWeight.w600)),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(DT.s4, 0, DT.s4, DT.s5),
                  children: [
                    _SectionTitle('Cél'),
                    _ChoiceGrid(
                      options: AthleteProfileGoals.all,
                      labels: AthleteProfileGoals.labels,
                      selected: _goal,
                      onSelect: (v) => setState(() => _goal = v),
                    ),
                    _SectionTitle('Szint'),
                    _ChoiceGrid(
                      options: AthleteProfileExperienceLevels.all,
                      labels: AthleteProfileExperienceLevels.labels,
                      selected: _experience,
                      onSelect: (v) => setState(() => _experience = v),
                    ),
                    _SectionTitle('Hetente'),
                    _IntSlider(
                      value: _daysPerWeek,
                      min: 2,
                      max: 6,
                      suffix: 'x / hét',
                      onChanged: (v) => setState(() => _daysPerWeek = v),
                    ),
                    _SectionTitle('Egy edzés hossza'),
                    _IntSlider(
                      value: _sessionMinutes,
                      min: 30,
                      max: 120,
                      step: 5,
                      suffix: 'perc',
                      onChanged: (v) => setState(() => _sessionMinutes = v),
                    ),
                    _SectionTitle('Elérhető eszközök'),
                    _MultiChips(
                      options: AthleteProfileEquipment.all,
                      labels: AthleteProfileEquipment.labels,
                      selected: _equipment,
                      onToggle: (v) => setState(() {
                        if (_equipment.contains(v)) {
                          _equipment.remove(v);
                        } else {
                          _equipment.add(v);
                        }
                      }),
                    ),
                    _SectionTitle('Kerülendő terhelések'),
                    _MultiChips(
                      options: AthleteProfileStressTags.all,
                      labels: AthleteProfileStressTags.labels,
                      selected: _avoidTags,
                      onToggle: (v) => setState(() {
                        if (_avoidTags.contains(v)) {
                          _avoidTags.remove(v);
                        } else {
                          _avoidTags.add(v);
                        }
                      }),
                    ),
                    _SectionTitle('Izomcsoport prioritás (0.5–1.5)'),
                    for (final g in _muscleGroups)
                      _PrioritySlider(
                        muscleGroup: g,
                        value: _priority[g] ?? kProfilePriorityDefault,
                        onChanged: (v) => setState(() => _priority[g] = v),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    // Only ship priorities that moved away from the default so the Mongo
    // document doesn't bloat with 1.0 entries the backend would ignore.
    final priority = <String, double>{
      for (final e in _priority.entries)
        if ((e.value - kProfilePriorityDefault).abs() > 0.001) e.key: e.value,
    };
    final profile = widget.initial.copyWith(
      goal: _goal,
      experienceLevel: _experience,
      daysPerWeek: _daysPerWeek,
      sessionMinutes: _sessionMinutes,
      availableEquipment: _equipment.toList(),
      avoidStressTags: _avoidTags.toList(),
      muscleGroupPriority: priority,
    );
    context
        .read<AthleteProfileCubit>()
        .saveForAthlete(widget.athleteId, profile);
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: DT.s3),
        decoration: BoxDecoration(
            color: DT.of(context).borderGrey,
            borderRadius: BorderRadius.circular(2)),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, DT.s4, 0, DT.s2),
      child: Text(text,
          style: TextStyle(
              color: DT.of(context).textSecondary,
              fontSize: DT.s3,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _ChoiceGrid extends StatelessWidget {
  final List<String> options;
  final Map<String, String> labels;
  final String selected;
  final ValueChanged<String> onSelect;

  const _ChoiceGrid({
    required this.options,
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: DT.s2,
      runSpacing: DT.s2,
      children: options.map((o) {
        final isSelected = selected == o;
        return GestureDetector(
          onTap: () => onSelect(o),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: DT.s3, vertical: DT.s2),
            decoration: BoxDecoration(
              color: isSelected
                  ? DT.metricBlue.withValues(alpha: 0.12)
                  : DT.of(context).bg,
              borderRadius: BorderRadius.circular(DT.rCardSmall),
              border: Border.all(
                  color: isSelected ? DT.metricBlue : DT.of(context).borderGrey,
                  width: 1.5),
            ),
            child: Text(
              labels[o] ?? o,
              style: TextStyle(
                color: isSelected
                    ? DT.metricBlue
                    : DT.of(context).textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MultiChips extends StatelessWidget {
  final List<String> options;
  final Map<String, String> labels;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _MultiChips({
    required this.options,
    required this.labels,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: DT.s2,
      runSpacing: DT.s2,
      children: options.map((o) {
        final isSelected = selected.contains(o);
        return GestureDetector(
          onTap: () => onToggle(o),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: DT.s3, vertical: DT.s2),
            decoration: BoxDecoration(
              color: isSelected
                  ? DT.metricBlue.withValues(alpha: 0.12)
                  : DT.of(context).bg,
              borderRadius: BorderRadius.circular(DT.rChip),
              border: Border.all(
                  color: isSelected ? DT.metricBlue : DT.of(context).borderGrey,
                  width: 1.5),
            ),
            child: Text(
              labels[o] ?? o,
              style: TextStyle(
                color: isSelected
                    ? DT.metricBlue
                    : DT.of(context).textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: DT.s3,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _IntSlider extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final int step;
  final String suffix;
  final ValueChanged<int> onChanged;

  const _IntSlider({
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final divisions = ((max - min) / step).round();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text('$value $suffix',
                  style: TextStyle(
                      color: DT.of(context).textPrimary,
                      fontSize: DT.s4,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: divisions,
          activeColor: DT.metricBlue,
          onChanged: (v) {
            // Snap to the configured step so e.g. 5-minute increments stay
            // on sensible values.
            final snapped = min + ((v - min) / step).round() * step;
            onChanged(snapped.toInt());
          },
        ),
      ],
    );
  }
}

class _PrioritySlider extends StatelessWidget {
  final String muscleGroup;
  final double value;
  final ValueChanged<double> onChanged;

  const _PrioritySlider({
    required this.muscleGroup,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DT.s1),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(muscleGroup,
                style: TextStyle(
                    color: DT.of(context).textPrimary,
                    fontSize: DT.s3,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: kProfilePriorityMin,
              max: kProfilePriorityMax,
              divisions: 10,
              activeColor: _priorityColor(value),
              label: '${value.toStringAsFixed(2)}×',
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '${value.toStringAsFixed(2)}×',
              textAlign: TextAlign.end,
              style: TextStyle(
                  color: DT.of(context).textSecondary, fontSize: DT.s3),
            ),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(double v) {
    if (v > kProfilePriorityDefault) return DT.metricBlue;
    if (v < kProfilePriorityDefault) return DT.cardOrange;
    return DT.cardTeal;
  }
}
