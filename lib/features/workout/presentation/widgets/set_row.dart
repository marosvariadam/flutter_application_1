import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/design/dt_text.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';

/// Local per-set state: editable weight/reps + done flag.
class SetEntry {
  final TextEditingController weightCtrl = TextEditingController();
  final TextEditingController repsCtrl = TextEditingController();
  bool isDone = false;

  /// Typed weight; a decimal comma ("62,5") is accepted.
  double? get weight =>
      double.tryParse(weightCtrl.text.trim().replaceAll(',', '.'));
  int? get reps => int.tryParse(repsCtrl.text.trim());

  void dispose() {
    weightCtrl.dispose();
    repsCtrl.dispose();
  }
}

/// Stepper math for the set rows: ±2.5 kg and ±1 rep, never below zero,
/// starting from the planned value when the field is still empty.
class SetSteps {
  const SetSteps._();

  static const weightStep = 2.5;
  static const repStep = 1;

  static double stepWeight(double? current, double planned, int direction) =>
      math.max(0, (current ?? planned) + direction * weightStep);

  static int stepReps(int? current, int planned, int direction) =>
      math.max(0, (current ?? planned) + direction * repStep);

  /// 60 → "60", 62.5 → "62.5", 61.25 → "61.25".
  static String formatWeight(double kg) {
    if (kg % 1 == 0) return kg.toInt().toString();
    var s = kg.toStringAsFixed(2);
    while (s.endsWith('0')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }
}

/// One set. Open: weight and reps steppers (44 px buttons, numeric
/// keyboard) and a check button; "Kész" on the reps keyboard also checks
/// it off. Done: a compact "62.5 kg × 8" line that can be unchecked.
class SetRow extends StatelessWidget {
  final int setNumber;
  final SetEntry entry;
  final WorkoutExercise exercise;
  final bool isCurrent;
  final VoidCallback onToggle;
  final VoidCallback onEdited;

  const SetRow({
    super.key,
    required this.setNumber,
    required this.entry,
    required this.exercise,
    required this.isCurrent,
    required this.onToggle,
    required this.onEdited,
  });

  String get _plannedWeight => exercise.targetWeightKg > 0
      ? SetSteps.formatWeight(exercise.targetWeightKg)
      : '';

  void _stepWeight(int direction) {
    final next = SetSteps.stepWeight(
        entry.weight, exercise.targetWeightKg, direction);
    entry.weightCtrl.text = SetSteps.formatWeight(next);
    HapticFeedback.selectionClick();
    onEdited();
  }

  void _stepReps(int direction) {
    entry.repsCtrl.text =
        '${SetSteps.stepReps(entry.reps, exercise.targetReps, direction)}';
    HapticFeedback.selectionClick();
    onEdited();
  }

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    final t = DTText.of(context);
    final done = entry.isDone;
    final weight = entry.weightCtrl.text.isNotEmpty
        ? entry.weightCtrl.text
        : (_plannedWeight.isEmpty ? '—' : _plannedWeight);
    final reps = entry.repsCtrl.text.isNotEmpty
        ? entry.repsCtrl.text
        : '${exercise.targetReps}';
    return AnimatedContainer(
      duration: DT.normal,
      margin: const EdgeInsets.fromLTRB(DT.s3, 0, DT.s3, DT.s2),
      padding: const EdgeInsets.all(DT.s2),
      decoration: BoxDecoration(
        color: done ? c.accentSuccess.withValues(alpha: 0.07) : c.bg,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        border: Border.all(
          color: isCurrent ? c.accentPrimary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('$setNumber',
                textAlign: TextAlign.center,
                style: t.title.copyWith(
                    color: done ? c.accentSuccess : c.textSecondary,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: DT.s2),
          Expanded(
            child: done
                ? Text(
                    '$weight kg × $reps',
                    style: t.bodyStrong.copyWith(color: c.accentSuccess),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : Column(
                    children: [
                      _Stepper(
                        controller: entry.weightCtrl,
                        hint: _plannedWeight,
                        suffix: 'kg',
                        decimal: true,
                        what: 'Súly',
                        stepLabel: '2,5 kg',
                        onStep: _stepWeight,
                        action: TextInputAction.next,
                      ),
                      const SizedBox(height: DT.s2),
                      _Stepper(
                        controller: entry.repsCtrl,
                        hint: '${exercise.targetReps}',
                        suffix: 'ism.',
                        decimal: false,
                        what: 'Ismétlés',
                        stepLabel: '1',
                        onStep: _stepReps,
                        action: TextInputAction.done,
                        onSubmitted: onToggle,
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: DT.s2),
          _DoneButton(setNumber: setNumber, done: done, onTap: onToggle),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String suffix;
  final bool decimal;

  /// "Súly" / "Ismétlés" — used in the button labels.
  final String what;
  final String stepLabel;
  final ValueChanged<int> onStep;
  final TextInputAction action;
  final VoidCallback? onSubmitted;

  const _Stepper({
    required this.controller,
    required this.hint,
    required this.suffix,
    required this.decimal,
    required this.what,
    required this.stepLabel,
    required this.onStep,
    required this.action,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    final t = DTText.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(DT.rCardSmall),
      borderSide: BorderSide(color: c.borderGrey),
    );
    return Row(
      children: [
        _StepButton(
          icon: Icons.remove,
          tooltip: '$what csökkentése ($stepLabel)',
          onTap: () => onStep(-1),
        ),
        const SizedBox(width: DT.s1),
        Expanded(
          child: Semantics(
            label: '$what ($suffix)',
            child: TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: decimal),
            inputFormatters: [
              decimal
                  ? FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}'))
                  : FilteringTextInputFormatter.digitsOnly,
            ],
            textInputAction: action,
            onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
            textAlign: TextAlign.center,
            style: t.title,
            decoration: InputDecoration(
              hintText: hint.isEmpty ? '—' : hint,
              hintStyle: t.title.copyWith(
                  color: c.textSecondary.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w400),
              // Always visible (suffixText hides while the field is empty),
              // so weight and reps rows stay distinguishable.
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: DT.s2),
                child: Text(suffix, style: t.caption),
              ),
              suffixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              isDense: true,
              constraints: const BoxConstraints(minHeight: DT.minTap),
              contentPadding: const EdgeInsets.symmetric(
                  vertical: DT.s3, horizontal: DT.s2),
              filled: true,
              fillColor: c.cardSurface,
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyWith(
                  borderSide: BorderSide(color: c.accentPrimary, width: 1.5)),
            ),
          ),
          ),
        ),
        const SizedBox(width: DT.s1),
        _StepButton(
          icon: Icons.add,
          tooltip: '$what növelése ($stepLabel)',
          onTap: () => onStep(1),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _StepButton(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      color: c.accentPrimary,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(DT.minTap),
        minimumSize: const Size.square(DT.minTap),
        backgroundColor: c.primarySoft,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DT.rCardSmall)),
      ),
    );
  }
}

class _DoneButton extends StatelessWidget {
  final int setNumber;
  final bool done;
  final VoidCallback onTap;

  const _DoneButton(
      {required this.setNumber, required this.done, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    return Tooltip(
      message: done ? 'Sorozat visszavonása' : 'Sorozat kész',
      child: Semantics(
        button: true,
        checked: done,
        label: '$setNumber. sorozat kész',
        onTap: onTap,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DT.rCardSmall),
          child: AnimatedContainer(
            duration: DT.normal,
            width: DT.minTap,
            height: DT.minTap,
            decoration: BoxDecoration(
              color: done ? c.accentSuccess : Colors.transparent,
              border: Border.all(
                color: done ? c.accentSuccess : c.iconLightGrey,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(DT.rCardSmall),
            ),
            child: done
                ? Icon(Icons.check, color: c.textOnAccent, size: 22)
                : null,
          ),
        ),
      ),
    );
  }
}
