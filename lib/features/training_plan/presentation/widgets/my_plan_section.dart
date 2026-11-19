import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/training_plan/bloc/my_plans_cubit.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';

/// "Edzéstervem" card at the top of the athlete's session tab. Reads the
/// [MyPlansCubit] provided by the host page and opens the read-only plan
/// view. Stays hidden while loading and when the athlete has no accepted
/// plan, so athletes without a plan see no extra clutter.
class MyPlanSection extends StatelessWidget {
  const MyPlanSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyPlansCubit, MyPlansState>(
      builder: (context, state) {
        if (state is MyPlansLoaded) return _PlanCard(plan: state.current);
        if (state is MyPlansError) {
          return _ErrorRow(
            message: state.message,
            onRetry: () => context.read<MyPlansCubit>().load(),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

/// "4 hét · 3 nap / hét · Elfogadva".
String planSummaryLine(TrainingPlanModel plan) {
  final status = PlanStatuses.labels[plan.status] ?? plan.status;
  return '${plan.weeks} hét · ${plan.days.length} nap / hét · $status';
}

class _PlanCard extends StatelessWidget {
  final TrainingPlanModel plan;
  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: DT.s4),
      child: Material(
        color: c.cardSurface,
        borderRadius: BorderRadius.circular(DT.rCard),
        child: InkWell(
          borderRadius: BorderRadius.circular(DT.rCard),
          onTap: () => context.push('/plan/mine'),
          child: Padding(
            padding: const EdgeInsets.all(DT.s4),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c.accentPrimary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.event_note, color: c.accentPrimary),
                ),
                const SizedBox(width: DT.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EDZÉSTERVEM',
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plan.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        planSummaryLine(plan),
                        style: TextStyle(color: c.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: c.iconLight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRow({required this.message, required this.onRetry});

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
            child: Text(message,
                style: TextStyle(color: c.textSecondary, fontSize: 13)),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text('Újra', style: TextStyle(color: c.accentPrimary)),
          ),
        ],
      ),
    );
  }
}
