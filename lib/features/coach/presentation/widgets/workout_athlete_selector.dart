import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/trainer/data/models/trainer_request_model.dart';

class WorkoutAthleteSelector extends StatelessWidget {
  final List<AthleteModel> athletes;
  final String? selectedId;
  final bool isFetchingPrev;
  final ValueChanged<String?> onChanged;

  const WorkoutAthleteSelector({
    super.key,
    required this.athletes,
    required this.selectedId,
    required this.isFetchingPrev,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DT.s4),
      decoration: BoxDecoration(
          color: DT.of(context).cardSurface,
          borderRadius: BorderRadius.circular(DT.rCardSmall)),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedId,
                hint: Text('Válassz sportolót…',
                    style: TextStyle(color: DT.of(context).textSecondary)),
                isExpanded: true,
                items: athletes
                    .map((a) => DropdownMenuItem(
                        value: a.id, child: Text(a.fullName)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
          if (isFetchingPrev)
            const Padding(
              padding: EdgeInsets.only(left: DT.s2),
              child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
    );
  }
}
