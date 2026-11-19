import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/training_block/bloc/training_block_bloc.dart';
import 'package:flutter_application_1/features/training_block/data/models/training_block_model.dart';

/// Optional training block dropdown, fed by the app-level
/// `TrainingBlockBloc`.
class PlanGenerateTrainingBlockPicker extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const PlanGenerateTrainingBlockPicker({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrainingBlockBloc, TrainingBlockState>(
      builder: (ctx, state) {
        if (state is TrainingBlockLoading || state is TrainingBlockInitial) {
          return const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is! TrainingBlocksLoaded) {
          return Container(
            padding: const EdgeInsets.all(DT.s3),
            decoration: BoxDecoration(
              color: DT.of(context).cardSurface,
              borderRadius: BorderRadius.circular(DT.rCardSmall),
            ),
            child: Text(
              'Nincs elérhető tréningblokk.',
              style: TextStyle(color: DT.of(context).textSecondary),
            ),
          );
        }
        final blocks = state.blocks;
        if (blocks.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(DT.s3),
            decoration: BoxDecoration(
              color: DT.of(context).cardSurface,
              borderRadius: BorderRadius.circular(DT.rCardSmall),
            ),
            child: Text(
              'Nincs tréningblokk ehhez a sportolóhoz.',
              style: TextStyle(color: DT.of(context).textSecondary),
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: DT.s3),
          decoration: BoxDecoration(
            color: DT.of(context).cardSurface,
            borderRadius: BorderRadius.circular(DT.rCardSmall),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: selectedId,
              isExpanded: true,
              hint: Text('Nincs kiválasztva',
                  style: TextStyle(color: DT.of(context).textSecondary)),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem(value: null, child: Text('Nincs')),
                ...blocks.map((b) => DropdownMenuItem<String?>(
                      value: b.id,
                      child: Text(_blockLabel(b)),
                    )),
              ],
              onChanged: onSelected,
            ),
          ),
        );
      },
    );
  }

  String _blockLabel(TrainingBlockModel b) {
    final s = DateFormat('yyyy.MM.dd').format(b.startDate.toLocal());
    final e = DateFormat('yyyy.MM.dd').format(b.endDate.toLocal());
    return '${b.focus} · $s – $e';
  }
}
