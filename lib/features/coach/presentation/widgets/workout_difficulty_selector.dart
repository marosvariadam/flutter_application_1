import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/design/dt_text.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:flutter_application_1/features/workout/presentation/widgets/workout_colors.dart';

class WorkoutDifficultySelector extends StatelessWidget {
  final WorkoutDifficulty selected;
  final ValueChanged<WorkoutDifficulty> onChanged;
  const WorkoutDifficultySelector(
      {super.key, required this.selected, required this.onChanged});

  static const _opts = [
    WorkoutDifficulty.easy,
    WorkoutDifficulty.moderate,
    WorkoutDifficulty.hard,
  ];

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    final t = DTText.of(context);
    return Row(
      children: _opts.map((opt) {
        final isSelected = opt == selected;
        final color = opt.color(c);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                right: opt == WorkoutDifficulty.hard ? 0 : DT.s2),
            child: Semantics(
              button: true,
              selected: isSelected,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(opt);
                },
                child: AnimatedContainer(
                  duration: DT.fast,
                  constraints: const BoxConstraints(minHeight: DT.minTap),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: DT.s3),
                  decoration: BoxDecoration(
                    color: isSelected ? color : c.cardSurface,
                    borderRadius: BorderRadius.circular(DT.rCardSmall),
                    border: Border.all(
                        color: isSelected ? color : c.borderGrey, width: 2),
                  ),
                  child: Text(
                    opt.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? c.textOnAccent : c.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
