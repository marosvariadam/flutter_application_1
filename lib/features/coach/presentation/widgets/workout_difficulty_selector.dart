import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';

class WorkoutDifficultySelector extends StatelessWidget {
  final WorkoutDifficulty selected;
  final ValueChanged<WorkoutDifficulty> onChanged;
  const WorkoutDifficultySelector(
      {super.key, required this.selected, required this.onChanged});

  static const _opts = [
    (WorkoutDifficulty.easy, 'Könnyű', DT.difficultyLight),
    (WorkoutDifficulty.moderate, 'Közepes', DT.difficultyMedium),
    (WorkoutDifficulty.hard, 'Nehéz', DT.difficultyHard),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _opts.map((opt) {
        final isSelected = opt.$1 == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(opt.$1),
            child: Container(
              margin: EdgeInsets.only(
                  right: opt.$1 == WorkoutDifficulty.hard ? 0 : DT.s2),
              padding:
                  const EdgeInsets.symmetric(vertical: DT.s3),
              decoration: BoxDecoration(
                color: isSelected ? opt.$3 : DT.of(context).cardSurface,
                borderRadius:
                    BorderRadius.circular(DT.rCardSmall),
                border: Border.all(
                    color: isSelected ? opt.$3 : DT.of(context).borderGrey,
                    width: 2),
              ),
              child: Text(opt.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: DT.s3,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : DT.of(context).textSecondary)),
            ),
          ),
        );
      }).toList(),
    );
  }
}
