import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/design/dt_text.dart';
import 'package:flutter_application_1/app/user_session.dart';
import 'package:flutter_application_1/features/training_block/data/models/training_block_model.dart';
import 'package:flutter_application_1/features/training_block/data/repositories/training_block_repository.dart';

/// Read-only pill shown on the athlete dashboard when a training block covers
/// today. Renders nothing while loading, when there is no active block, or on
/// any error.
class CurrentBlockPill extends StatefulWidget {
  const CurrentBlockPill({super.key});

  @override
  State<CurrentBlockPill> createState() => _CurrentBlockPillState();
}

class _CurrentBlockPillState extends State<CurrentBlockPill> {
  TrainingBlockModel? _current;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = UserSession.instance.userId;
    if (userId == null) return;
    try {
      final repo = context.read<TrainingBlockRepository>();
      final blocks = await repo.getForAthlete(userId);
      final today = DateTime.now();
      final dayOnly = DateTime(today.year, today.month, today.day);
      TrainingBlockModel? hit;
      for (final b in blocks) {
        final s = DateTime(b.startDate.year, b.startDate.month, b.startDate.day);
        final e = DateTime(b.endDate.year, b.endDate.month, b.endDate.day);
        if (!dayOnly.isBefore(s) && !dayOnly.isAfter(e)) {
          hit = b;
          break;
        }
      }
      if (mounted) {
        setState(() {
          _current = hit;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _current == null) return const SizedBox.shrink();
    final b = _current!;
    final c = DT.of(context);
    final remaining =
        b.endDate.difference(DateTime.now()).inDays.clamp(0, 9999);
    return Container(
      margin: const EdgeInsets.only(bottom: DT.s4),
      padding: const EdgeInsets.symmetric(horizontal: DT.s4, vertical: DT.s2),
      decoration: BoxDecoration(
        color: c.accentPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DT.rChip),
        border: Border.all(color: c.accentPrimary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt, size: 16, color: c.accentPrimary),
          const SizedBox(width: DT.s2),
          Expanded(
            child: Text(
              'Aktuális blokk: ${b.focus} · még $remaining nap',
              style: DTText.of(context)
                  .caption
                  .copyWith(color: c.accentPrimary, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
