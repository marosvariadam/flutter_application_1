import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/design/dt_colors.dart';
import 'package:flutter_application_1/features/autoregulation/bloc/autoregulation_cubit.dart';
import 'package:flutter_application_1/features/autoregulation/data/models/autoregulation_model.dart';
import 'package:flutter_application_1/features/autoregulation/presentation/autoregulation_copy.dart';

/// Next-week load suggestion for one exercise in the workout builder.
/// Renders nothing until the athlete's suggestions are loaded or when the
/// exercise isn't part of their accepted plan.
class AutoregulationSuggestionChip extends StatelessWidget {
  final String? exerciseId;
  final String exerciseName;

  /// True when the exercise's sets already match the suggestion; the chip
  /// then shows a check and stops reacting to taps until something changes.
  final bool Function(AutoregulationSuggestionModel suggestion) isApplied;
  final ValueChanged<AutoregulationSuggestionModel> onApply;

  /// Applied only when the chip is visible, so hosts don't get an empty gap
  /// for exercises without a suggestion.
  final EdgeInsetsGeometry padding;

  const AutoregulationSuggestionChip({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
    required this.isApplied,
    required this.onApply,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AutoregulationCubit, AutoregulationState>(
      builder: (context, state) {
        if (state is! AutoregulationLoaded) return const SizedBox.shrink();
        final suggestion = state.result
            .suggestionFor(exerciseId: exerciseId, name: exerciseName);
        if (suggestion == null || !suggestion.isActionable) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: padding,
          child: _SuggestionPill(
            suggestion: suggestion,
            applied: isApplied(suggestion),
            onTap: () => onApply(suggestion),
          ),
        );
      },
    );
  }
}

class _SuggestionPill extends StatelessWidget {
  final AutoregulationSuggestionModel suggestion;
  final bool applied;
  final VoidCallback onTap;

  const _SuggestionPill({
    required this.suggestion,
    required this.applied,
    required this.onTap,
  });

  Color _tone(DTColors c) {
    if (suggestion.isDeload) return c.accentTeal;
    final delta = suggestion.deltaKg;
    if (delta == null || delta.abs() < 0.01) return c.accentInfo;
    return delta > 0 ? c.accentSuccess : c.accentWarning;
  }

  IconData _icon() {
    if (applied) return Icons.check_circle;
    if (suggestion.isDeload) return Icons.battery_charging_full;
    final delta = suggestion.deltaKg;
    if (delta == null || delta.abs() < 0.01) return Icons.trending_flat;
    return delta > 0 ? Icons.trending_up : Icons.trending_down;
  }

  @override
  Widget build(BuildContext context) {
    final tone = _tone(DT.of(context));
    final label = autoregulationChipLabel(suggestion);
    return Tooltip(
      message: autoregulationExplanation(suggestion),
      triggerMode: TooltipTriggerMode.longPress,
      child: Semantics(
        button: true,
        label: applied ? '$label, alkalmazva' : 'Javaslat alkalmazása: $label',
        excludeSemantics: true,
        child: Material(
          color: tone.withValues(alpha: applied ? 0.22 : 0.12),
          borderRadius: BorderRadius.circular(DT.rChip),
          child: InkWell(
            borderRadius: BorderRadius.circular(DT.rChip),
            onTap: applied ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: DT.s3, vertical: DT.s2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_icon(), size: 16, color: tone),
                  const SizedBox(width: DT.s1),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tone,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
