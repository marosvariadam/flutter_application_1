import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/autoregulation/data/models/autoregulation_model.dart';
import 'package:flutter_application_1/features/autoregulation/presentation/autoregulation_copy.dart';
import 'package:flutter_application_1/features/autoregulation/presentation/widgets/autoregulation_suggestion_chip.dart';
import 'package:flutter_application_1/features/coach/presentation/widgets/builder_num_field.dart';
import 'package:flutter_application_1/features/coach/presentation/widgets/workout_builder_models.dart';

/// One exercise in the workout builder: header, equipment toggle, the
/// next-week autoregulation chip and the editable per-set table.
class ExerciseBuilderCard extends StatefulWidget {
  final BuilderExercise exercise;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const ExerciseBuilderCard({
    super.key,
    required this.exercise,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<ExerciseBuilderCard> createState() => _ExerciseBuilderCardState();
}

class _ExerciseBuilderCardState extends State<ExerciseBuilderCard> {
  final List<TextEditingController> _repsCtrls = [];
  final List<TextEditingController> _weightCtrls = [];

  @override
  void initState() {
    super.initState();
    for (final s in widget.exercise.setEntries) {
      _repsCtrls.add(TextEditingController(text: s.reps?.toString() ?? ''));
      _weightCtrls.add(TextEditingController(text: s.weightKg?.toString() ?? ''));
    }
  }

  @override
  void dispose() {
    for (final c in _repsCtrls) {
      c.dispose();
    }
    for (final c in _weightCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _addSet() {
    final last = widget.exercise.setEntries.isNotEmpty
        ? widget.exercise.setEntries.last
        : null;
    setState(() {
      widget.exercise.setEntries
          .add(BuilderSetEntry(reps: last?.reps, weightKg: last?.weightKg));
      _repsCtrls.add(
          TextEditingController(text: last?.reps?.toString() ?? ''));
      _weightCtrls.add(
          TextEditingController(text: last?.weightKg?.toString() ?? ''));
    });
    widget.onChanged();
  }

  void _removeSet(int i) {
    _repsCtrls[i].dispose();
    _weightCtrls[i].dispose();
    setState(() {
      widget.exercise.setEntries.removeAt(i);
      _repsCtrls.removeAt(i);
      _weightCtrls.removeAt(i);
    });
    widget.onChanged();
  }

  bool get _isBodyweight => widget.exercise.equipmentType == kEquipmentBodyweight;

  bool _isSuggestionApplied(AutoregulationSuggestionModel s) {
    final target = s.suggestedWeightKg;
    final sets = widget.exercise.setEntries;
    if (target == null || sets.isEmpty) return false;
    if (s.isDeload && sets.length != s.suggestedSets) return false;
    return sets.every((e) => e.weightKg == target);
  }

  /// Writes the suggested load into every set; a deload suggestion also
  /// trims (or extends) the set count to the suggested number.
  void _applySuggestion(AutoregulationSuggestionModel s) {
    final target = s.suggestedWeightKg;
    if (target == null) return;
    final ex = widget.exercise;
    final removed = <TextEditingController>[];
    setState(() {
      if (s.isDeload) {
        while (ex.setEntries.length > s.suggestedSets &&
            ex.setEntries.length > 1) {
          ex.setEntries.removeLast();
          removed
            ..add(_repsCtrls.removeLast())
            ..add(_weightCtrls.removeLast());
        }
        while (ex.setEntries.length < s.suggestedSets) {
          final last = ex.setEntries.isNotEmpty ? ex.setEntries.last : null;
          ex.setEntries.add(BuilderSetEntry(reps: last?.reps));
          _repsCtrls.add(
              TextEditingController(text: last?.reps?.toString() ?? ''));
          _weightCtrls.add(TextEditingController());
        }
      }
      for (var i = 0; i < ex.setEntries.length; i++) {
        ex.setEntries[i].weightKg = target;
        _weightCtrls[i].text = formatKg(target);
      }
    });
    // The dropped rows' fields are unmounted by this rebuild; dispose their
    // controllers once that frame is done.
    if (removed.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final c in removed) {
          c.dispose();
        }
      });
    }
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final hasPrev = ex.prevWeightKg != null || ex.prevReps != null;

    return Container(
      margin: const EdgeInsets.only(bottom: DT.s4),
      decoration: BoxDecoration(
        color: DT.of(context).cardSurface,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        boxShadow: [
          BoxShadow(
              color: DT.of(context).shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(DT.s4, DT.s3, DT.s2, DT.s2),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ex.name,
                          style: TextStyle(
                              fontSize: DT.s4,
                              fontWeight: FontWeight.w700,
                              color: DT.of(context).textPrimary)),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: DT.s2, vertical: 2),
                        decoration: BoxDecoration(
                          color: DT.of(context).accentPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(ex.muscleGroup,
                            style: TextStyle(
                                fontSize: 11,
                                color: DT.of(context).accentPrimary,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                    tooltip: 'Gyakorlat eltávolítása',
                    icon: Icon(Icons.delete_outline, color: DT.of(context).accentDanger),
                    onPressed: widget.onRemove),
              ],
            ),
          ),

          // Equipment type
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: DT.s4, vertical: DT.s2),
            child: Row(
              children: kEquipmentOptions.map((opt) {
                final selected = ex.equipmentType == opt;
                return Padding(
                  padding: const EdgeInsets.only(right: DT.s2),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => ex.equipmentType = opt);
                      widget.onChanged();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: DT.s3, vertical: DT.s1),
                      decoration: BoxDecoration(
                        color: selected
                            ? DT.of(context).accentPrimary
                            : DT.of(context).bg,
                        borderRadius:
                            BorderRadius.circular(DT.rCardSmall),
                        border: Border.all(
                            color: selected
                                ? DT.of(context).accentPrimary
                                : DT.of(context).borderGrey),
                      ),
                      child: Text(opt,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? DT.of(context).textOnAccent
                                  : DT.of(context).textSecondary)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Next-week autoregulation suggestion (weighted exercises only)
          if (!_isBodyweight)
            AutoregulationSuggestionChip(
              exerciseId: ex.exerciseId,
              exerciseName: ex.name,
              isApplied: _isSuggestionApplied,
              onApply: _applySuggestion,
              padding: const EdgeInsets.fromLTRB(DT.s4, 0, DT.s4, DT.s2),
            ),

          // Per-set table
          Container(
            padding: const EdgeInsets.fromLTRB(DT.s4, DT.s3, DT.s4, DT.s2),
            decoration: BoxDecoration(
                border: Border(top: BorderSide(color: DT.of(context).borderLight))),
            child: Column(
              children: [
                // Column headers
                Row(
                  children: [
                    SizedBox(
                        width: 28,
                        child: Text('Set',
                            style: TextStyle(
                                fontSize: 11,
                                color: DT.of(context).textSecondary,
                                fontWeight: FontWeight.w600))),
                    const SizedBox(width: DT.s3),
                    Expanded(
                        child: Text('Ismétlés',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11, color: DT.of(context).textSecondary))),
                    if (!_isBodyweight) ...[
                      const SizedBox(width: DT.s3),
                      Expanded(
                          child: Text('Súly (kg)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 11, color: DT.of(context).textSecondary))),
                    ],
                    const SizedBox(width: 28),
                  ],
                ),
                const SizedBox(height: DT.s2),

                // One row per set
                ...ex.setEntries.asMap().entries.map((entry) {
                  final i = entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: DT.s2),
                    child: Row(
                      children: [
                        // Set number badge
                        SizedBox(
                          width: 28,
                          child: Center(
                            child: Text('${i + 1}',
                                style: TextStyle(
                                    fontSize: DT.s3,
                                    fontWeight: FontWeight.w700,
                                    color: DT.of(context).accentPrimary)),
                          ),
                        ),
                        const SizedBox(width: DT.s3),

                        // Reps
                        Expanded(
                          child: BuilderNumField(
                            controller: _repsCtrls[i],
                            hint: '10',
                            isDecimal: false,
                            onChanged: (v) {
                              ex.setEntries[i].reps = int.tryParse(v);
                              widget.onChanged();
                            },
                          ),
                        ),

                        // Weight
                        if (!_isBodyweight) ...[
                          const SizedBox(width: DT.s3),
                          Expanded(
                            child: BuilderNumField(
                              controller: _weightCtrls[i],
                              hint: '0',
                              isDecimal: true,
                              onChanged: (v) {
                                ex.setEntries[i].weightKg =
                                    double.tryParse(v);
                                widget.onChanged();
                              },
                            ),
                          ),
                        ],

                        // Remove set
                        SizedBox(
                          width: 28,
                          child: ex.setEntries.length > 1
                              ? Tooltip(
                                  message: 'Sorozat törlése',
                                  child: Semantics(
                                    button: true,
                                    label: '${i + 1}. sorozat törlése',
                                    onTap: () => _removeSet(i),
                                    excludeSemantics: true,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => _removeSet(i),
                                      child: SizedBox(
                                        height: DT.minTap,
                                        child: Icon(Icons.close,
                                            size: 16,
                                            color:
                                                DT.of(context).accentDanger),
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  );
                }),

                // Add set button
                GestureDetector(
                  onTap: _addSet,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: DT.s2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 15, color: DT.of(context).accentPrimary),
                        SizedBox(width: 4),
                        Text('Sorozat hozzáadása',
                            style: TextStyle(
                                fontSize: 12,
                                color: DT.of(context).accentPrimary,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Previous data hint
          if (hasPrev)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: DT.s4, vertical: DT.s2),
              decoration: BoxDecoration(
                color: DT.of(context).successSoft,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(DT.rCardSmall),
                  bottomRight: Radius.circular(DT.rCardSmall),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.history, size: 14, color: DT.of(context).textSecondary),
                  const SizedBox(width: DT.s1),
                  Text(
                    _prevText(ex),
                    style: TextStyle(
                        fontSize: 11,
                        color: DT.of(context).textSecondary,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _prevText(BuilderExercise ex) {
    final w = ex.prevWeightKg;
    final r = ex.prevReps;
    if (w != null && r != null) {
      final wStr = w == w.roundToDouble() ? w.toInt().toString() : w.toStringAsFixed(1);
      return 'Előző: $wStr kg × $r ism.';
    }
    if (r != null) return 'Előző: $r ismétlés';
    if (w != null) {
      final wStr = w == w.roundToDouble() ? w.toInt().toString() : w.toStringAsFixed(1);
      return 'Előző: $wStr kg';
    }
    return '';
  }
}
