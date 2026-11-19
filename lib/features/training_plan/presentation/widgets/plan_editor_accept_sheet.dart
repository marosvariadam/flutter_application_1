import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';

/// The Monday after [from] (a week later when [from] is a Monday), at
/// midnight. Uses calendar days rather than 24-hour durations so a DST
/// change can't land on the previous day.
DateTime nextMondayAfter(DateTime from) {
  // DateTime.weekday: Monday = 1 … Sunday = 7.
  final add = (8 - from.weekday) % 7;
  return DateTime(from.year, from.month, from.day + (add == 0 ? 7 : add));
}

/// Bottom sheet shown by the Accept → Materialize flow. Trainer picks a
/// start date (defaults to the next Monday) and either accepts first or
/// materializes directly if the plan is already accepted.
class PlanEditorAcceptSheet extends StatefulWidget {
  /// Shown when the plan is still a Draft — the UI should accept first.
  final bool needsAcceptFirst;

  /// Fires after the user confirms. The page handles sequencing the
  /// accept → materialize calls on the bloc.
  final void Function(DateTime startDate) onConfirm;

  const PlanEditorAcceptSheet({
    super.key,
    required this.needsAcceptFirst,
    required this.onConfirm,
  });

  @override
  State<PlanEditorAcceptSheet> createState() => _PlanEditorAcceptSheetState();
}

class _PlanEditorAcceptSheetState extends State<PlanEditorAcceptSheet> {
  late DateTime _startDate;

  @override
  void initState() {
    super.initState();
    _startDate = nextMondayAfter(DateTime.now());
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _startDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: DT.s3,
        left: DT.s5,
        right: DT.s5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DT.of(context).borderGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: DT.s3),
          Text(
            widget.needsAcceptFirst
                ? 'Elfogadás és ütemezés'
                : 'Ütemezés',
            style: TextStyle(
              color: DT.of(context).textPrimary,
              fontSize: DT.s5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: DT.s2),
          Text(
            widget.needsAcceptFirst
                ? 'Elfogadjuk a tervet, majd lefoglaljuk az edzéseket a megadott kezdőnaptól.'
                : 'Mikor kezdődjön a terv? A rendszer létrehozza az edzéseket a naptárban.',
            style: TextStyle(
                color: DT.of(context).textSecondary, fontSize: DT.s3),
          ),
          const SizedBox(height: DT.s4),
          Text('Kezdő dátum',
              style: TextStyle(
                  color: DT.of(context).textSecondary, fontSize: DT.s3)),
          const SizedBox(height: DT.s1),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(DT.rCardSmall),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: DT.s3, vertical: DT.s3),
              decoration: BoxDecoration(
                color: DT.of(context).bg,
                borderRadius: BorderRadius.circular(DT.rCardSmall),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 18, color: DT.of(context).iconLight),
                  const SizedBox(width: DT.s2),
                  Expanded(
                    child: Text(
                      DateFormat('yyyy.MM.dd. (EEEE)', 'hu').format(_startDate),
                      style: TextStyle(
                          color: DT.of(context).textPrimary,
                          fontSize: DT.s4),
                    ),
                  ),
                  Icon(Icons.edit_calendar,
                      size: 18, color: DT.of(context).iconLight),
                ],
              ),
            ),
          ),
          const SizedBox(height: DT.s5),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DT.of(context).textSecondary,
                    side: BorderSide(color: DT.of(context).borderGrey),
                    padding: const EdgeInsets.symmetric(vertical: DT.s3),
                  ),
                  child: const Text('Mégse'),
                ),
              ),
              const SizedBox(width: DT.s3),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    widget.onConfirm(_startDate);
                  },
                  icon: const Icon(Icons.check),
                  label: Text(widget.needsAcceptFirst
                      ? 'Elfogad + Ütemez'
                      : 'Ütemezés'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DT.metricBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: DT.s3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DT.s3),
        ],
      ),
    );
  }
}
