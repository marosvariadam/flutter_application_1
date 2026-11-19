import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/autoregulation/bloc/autoregulation_cubit.dart';

/// Sits above the builder's exercise list: the deload suggestion when the
/// backend's deload rule fired, a compact notice when suggestions couldn't
/// be loaded, otherwise nothing.
class AutoregulationBanner extends StatelessWidget {
  const AutoregulationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AutoregulationCubit, AutoregulationState>(
      builder: (context, state) {
        if (state is AutoregulationLoaded && state.result.deloadApplied) {
          return const _DeloadBanner();
        }
        if (state is AutoregulationForbidden) {
          return const _Notice(
              message: 'Nincs jogosultságod a sportoló javaslataihoz.');
        }
        if (state is AutoregulationError) {
          return _Notice(
            message: state.message,
            onRetry: () =>
                context.read<AutoregulationCubit>().load(state.athleteId),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _DeloadBanner extends StatelessWidget {
  const _DeloadBanner();

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: DT.s3),
      padding: const EdgeInsets.all(DT.s4),
      decoration: BoxDecoration(
        color: c.accentWarning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        border: Border.all(color: c.accentWarning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.battery_charging_full, color: c.accentWarning),
          const SizedBox(width: DT.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deload hét javasolt',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: DT.s1),
                Text(
                  'Az elmúlt hetekben stagnált az erőbecslés (e1RM), vagy '
                  'túl magas volt az átlagos RPE. A javaslatok −10% '
                  'terhelést és −40% szettszámot tartalmaznak — koppints '
                  'egy gyakorlat javaslatára az alkalmazáshoz.',
                  style: TextStyle(color: c.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _Notice({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: DT.s3),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: c.textSecondary),
          const SizedBox(width: DT.s2),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: c.textSecondary, fontSize: 13),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text('Újra', style: TextStyle(color: c.accentPrimary)),
            ),
        ],
      ),
    );
  }
}
