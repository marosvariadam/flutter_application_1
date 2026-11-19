import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/training_plan/bloc/my_plans_cubit.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';
import 'package:flutter_application_1/features/training_plan/data/repositories/training_plan_repository.dart';
import 'package:flutter_application_1/features/training_plan/presentation/widgets/plan_explanation_panel.dart';
import 'package:flutter_application_1/features/training_plan/presentation/widgets/plan_read_only_days.dart';

/// Athlete's read-only view of their accepted training plans
/// (`/plan/mine`). Shows the newest plan by default; older ones can be
/// picked from the chip row.
class MyPlanPage extends StatelessWidget {
  const MyPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          MyPlansCubit(ctx.read<TrainingPlanRepository>())..load(),
      child: const _MyPlanView(),
    );
  }
}

class _MyPlanView extends StatefulWidget {
  const _MyPlanView();

  @override
  State<_MyPlanView> createState() => _MyPlanViewState();
}

class _MyPlanViewState extends State<_MyPlanView> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        leading: BackButton(color: c.textPrimary),
        title: Text(
          'Edzéstervem',
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<MyPlansCubit, MyPlansState>(
        builder: (context, state) {
          if (state is MyPlansEmpty) {
            return const _CenteredMessage(
              icon: Icons.event_note,
              title: 'Még nincs elfogadott edzésterved.',
              message: 'Amint az edződ elfogad egy tervet, itt megjelenik.',
            );
          }
          if (state is MyPlansError) {
            return _CenteredMessage(
              icon: Icons.error_outline,
              title: state.message,
              onRetry: () => context.read<MyPlansCubit>().load(),
            );
          }
          if (state is! MyPlansLoaded) {
            return Center(
                child: CircularProgressIndicator(color: c.accentPrimary));
          }
          final plan = state.plans.firstWhere(
            (p) => p.id == _selectedId,
            orElse: () => state.current,
          );
          return ListView(
            padding: const EdgeInsets.all(DT.s4),
            children: [
              if (state.plans.length > 1) ...[
                _PlanSwitcher(
                  plans: state.plans,
                  selectedId: plan.id,
                  onSelect: (id) => setState(() => _selectedId = id),
                ),
                const SizedBox(height: DT.s3),
              ],
              _PlanHeader(plan: plan),
              const SizedBox(height: DT.s4),
              PlanExplanationPanel(key: ValueKey(plan.id), planId: plan.id),
              const SizedBox(height: DT.s4),
              PlanReadOnlyDays(plan: plan),
              const SizedBox(height: DT.s8),
            ],
          );
        },
      ),
    );
  }
}

class _PlanSwitcher extends StatelessWidget {
  final List<TrainingPlanModel> plans;
  final String selectedId;
  final ValueChanged<String> onSelect;

  const _PlanSwitcher({
    required this.plans,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: plans.length,
        separatorBuilder: (_, __) => const SizedBox(width: DT.s2),
        itemBuilder: (context, i) {
          final p = plans[i];
          final selected = p.id == selectedId;
          return ChoiceChip(
            label: Text(DateFormat('yyyy.MM.dd').format(p.createdAt.toLocal())),
            selected: selected,
            onSelected: (_) => onSelect(p.id),
            selectedColor: c.accentPrimary.withValues(alpha: 0.15),
            backgroundColor: c.cardSurface,
            labelStyle: TextStyle(
              color: selected ? c.accentPrimary : c.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide(
                color: selected ? c.accentPrimary : c.borderGrey),
          );
        },
      ),
    );
  }
}

class _PlanHeader extends StatelessWidget {
  final TrainingPlanModel plan;
  const _PlanHeader({required this.plan});

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    final accepted = plan.acceptedAt;
    final pills = <String>[
      '${plan.weeks} hét',
      PlanSplits.labels[plan.split] ?? plan.split,
      '${plan.days.length} nap / hét',
      PlanProgressionSchemes.labels[plan.progression] ?? plan.progression,
      if (accepted != null)
        'Elfogadva: ${DateFormat('yyyy.MM.dd').format(accepted.toLocal())}',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DT.s4),
      decoration: BoxDecoration(
        color: c.cardSurface,
        borderRadius: BorderRadius.circular(DT.rCard),
        boxShadow: [
          BoxShadow(
              color: c.shadowLight, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  plan.title,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: DT.s2),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: DT.s2, vertical: 2),
                decoration: BoxDecoration(
                  color: c.accentSuccess.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DT.rChip),
                ),
                child: Text(
                  PlanStatuses.labels[plan.status] ?? plan.status,
                  style: TextStyle(
                    color: c.accentSuccess,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DT.s3),
          Wrap(
            spacing: DT.s2,
            runSpacing: DT.s2,
            children: [
              for (final text in pills)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DT.s2, vertical: DT.s1),
                  decoration: BoxDecoration(
                    color: c.bg,
                    borderRadius: BorderRadius.circular(DT.rChip),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final VoidCallback? onRetry;

  const _CenteredMessage({
    required this.icon,
    required this.title,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DT.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: c.accentPrimary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: c.accentPrimary, size: 30),
            ),
            const SizedBox(height: DT.s4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: DT.s2),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary, fontSize: 14),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: DT.s4),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.accentPrimary,
                  side: BorderSide(color: c.accentPrimary),
                ),
                child: const Text('Újra'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
