import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/training_block/bloc/training_block_bloc.dart';
import 'package:flutter_application_1/features/training_block/data/models/training_block_model.dart';

/// Optional training block dropdown, fed by the app-level
/// `TrainingBlockBloc`.
class PlanGenerateTrainingBlockPicker extends StatelessWidget {
  final String athleteId;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const PlanGenerateTrainingBlockPicker({
    super.key,
    required this.athleteId,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrainingBlockBloc, TrainingBlockState>(
      // The bloc is app-wide: ignore the transient overlap/validation
      // states other screens emit while editing blocks.
      buildWhen: (_, s) =>
          s is TrainingBlockInitial ||
          s is TrainingBlockLoading ||
          s is TrainingBlocksLoaded ||
          s is TrainingBlockForbidden ||
          s is TrainingBlockError,
      builder: (ctx, state) {
        final c = DT.of(context);
        if (state is TrainingBlockForbidden) {
          return const _Notice(
              text: 'Nincs jogosultságod a tréningblokkokhoz.');
        }
        if (state is TrainingBlockError) {
          return _Notice(
            text: 'Nem sikerült betölteni a tréningblokkokat.',
            action: TextButton(
              onPressed: () => context
                  .read<TrainingBlockBloc>()
                  .add(LoadTrainingBlocks(athleteId)),
              child: Text('Újra', style: TextStyle(color: c.accentPrimary)),
            ),
          );
        }
        // Another athlete's list may still be in the shared bloc until
        // this athlete's blocks arrive.
        if (state is! TrainingBlocksLoaded || state.athleteId != athleteId) {
          return const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final blocks = state.blocks;
        if (blocks.isEmpty) {
          return const _Notice(
              text: 'Nincs tréningblokk ehhez a sportolóhoz. '
                  'A terv blokk nélkül is generálható.');
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

class _Notice extends StatelessWidget {
  final String text;
  final Widget? action;
  const _Notice({required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DT.s3, vertical: DT.s2),
      decoration: BoxDecoration(
        color: c.cardSurface,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: TextStyle(color: c.textSecondary)),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
