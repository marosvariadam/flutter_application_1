import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/design/dt_text.dart';

/// Monday–Sunday of the current week as day pills. The selected day is
/// filled with the accent; a dot marks days that have a workout.
class WeeklyStrip extends StatelessWidget {
  final DateTime selected;

  /// [dayKey]s of the days that have a workout.
  final Set<String> workoutDateKeys;
  final ValueChanged<DateTime> onDateSelected;

  const WeeklyStrip({
    super.key,
    required this.selected,
    required this.workoutDateKeys,
    required this.onDateSelected,
  });

  /// Monday 00:00 of [day]'s week. Built from calendar fields, so a DST
  /// switch can't move it to the wrong day.
  static DateTime weekStart(DateTime day) =>
      DateTime(day.year, day.month, day.day - (day.weekday - 1));

  /// Identifies a calendar day regardless of the time of day.
  static String dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    final t = DTText.of(context);
    final monday = weekStart(DateTime.now());
    final selectedKey = dayKey(selected);
    return SizedBox(
      height: 76,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = DateTime(monday.year, monday.month, monday.day + index);
          final key = dayKey(date);
          final isSelected = key == selectedKey;
          final hasWorkout = workoutDateKeys.contains(key);
          // null keeps the style's own color.
          final onPill = isSelected ? c.textOnAccent : null;
          final dot = isSelected ? c.textOnAccent : c.accentPrimary;
          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: AnimatedContainer(
              duration: DT.fast,
              width: 48,
              margin: const EdgeInsets.only(right: DT.s3),
              decoration: BoxDecoration(
                // Selected: brand accent. Unselected: card surface — white on
                // lavender (light) or the raised slate (dark).
                color: isSelected ? c.accentPrimary : c.cardSurface,
                borderRadius: BorderRadius.circular(DT.rCardSmall),
                boxShadow: DT.shadowCard(context),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('E').format(date),
                      style: t.caption.copyWith(color: onPill)),
                  const SizedBox(height: 2),
                  Text(DateFormat('d').format(date),
                      style: t.title.copyWith(color: onPill)),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: DT.fast,
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dot.withValues(alpha: hasWorkout ? 1 : 0),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
