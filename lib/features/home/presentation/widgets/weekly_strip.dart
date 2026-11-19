import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/design/dt_text.dart';

/// Monday–Sunday of the current week as day pills. The selected day is
/// filled with the accent and today is outlined. Under each day a dot shows
/// its workout: a ring for a planned one, a filled dot once completed.
class WeeklyStrip extends StatelessWidget {
  final DateTime selected;

  /// [dayKey] of each day that has a workout → whether it's completed.
  final Map<String, bool> workoutDays;
  final ValueChanged<DateTime> onDateSelected;

  /// Injectable clock for tests.
  final DateTime Function() now;

  const WeeklyStrip({
    super.key,
    required this.selected,
    required this.workoutDays,
    required this.onDateSelected,
    this.now = DateTime.now,
  });

  /// Monday 00:00 of [day]'s week. Built from calendar fields, so a DST
  /// switch can't move it to the wrong day.
  static DateTime weekStart(DateTime day) =>
      DateTime(day.year, day.month, day.day - (day.weekday - 1));

  /// Identifies a calendar day regardless of the time of day.
  static String dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  static const _pillHeight = 76.0;

  @override
  Widget build(BuildContext context) {
    final today = now();
    final monday = weekStart(today);
    final selectedKey = dayKey(selected);
    final todayKey = dayKey(today);
    // Room for a larger system font size without clipping the date.
    final height = MediaQuery.textScalerOf(context).scale(_pillHeight)
        .clamp(_pillHeight, _pillHeight * 1.4);
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = DateTime(monday.year, monday.month, monday.day + index);
          final key = dayKey(date);
          return _DayPill(
            date: date,
            isSelected: key == selectedKey,
            isToday: key == todayKey,
            workoutCompleted: workoutDays[key],
            onTap: () {
              HapticFeedback.selectionClick();
              onDateSelected(date);
            },
          );
        },
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;

  /// null: no workout that day.
  final bool? workoutCompleted;
  final VoidCallback onTap;

  const _DayPill({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.workoutCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    final t = DTText.of(context);
    // null keeps the style's own color.
    final onPill = isSelected ? c.textOnAccent : null;
    final dotColor = isSelected
        ? c.textOnAccent
        : (workoutCompleted == true ? c.accentSuccess : c.accentPrimary);
    final hasWorkout = workoutCompleted != null;
    final status = switch (workoutCompleted) {
      null => 'nincs edzés',
      true => 'teljesített edzés',
      false => 'tervezett edzés',
    };
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${DateFormat('MM.dd').format(date)}${isToday ? ', ma' : ''}, $status',
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: DT.fast,
          width: 48,
          margin: const EdgeInsets.only(right: DT.s3),
          decoration: BoxDecoration(
            // Selected: brand accent. Unselected: card surface — white on
            // lavender (light) or the raised slate (dark).
            color: isSelected ? c.accentPrimary : c.cardSurface,
            borderRadius: BorderRadius.circular(DT.rCardSmall),
            border: Border.all(
              color: isToday && !isSelected
                  ? c.accentPrimary
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: DT.shadowCard(context),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(DateFormat('E').format(date),
                  maxLines: 1, style: t.caption.copyWith(color: onPill)),
              const SizedBox(height: 2),
              Text(DateFormat('d').format(date),
                  maxLines: 1, style: t.title.copyWith(color: onPill)),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: DT.fast,
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Planned: ring. Completed: filled.
                  color: workoutCompleted == true
                      ? dotColor
                      : Colors.transparent,
                  border: Border.all(
                    color: dotColor.withValues(alpha: hasWorkout ? 1 : 0),
                    width: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
