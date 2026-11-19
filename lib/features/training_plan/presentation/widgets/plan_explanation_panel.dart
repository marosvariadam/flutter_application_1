import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/training_plan/bloc/plan_explanation_cubit.dart';
import 'package:flutter_application_1/features/training_plan/data/repositories/training_plan_repository.dart';

/// Card that asks the backend to explain a plan in plain Hungarian. Shared
/// by the trainer's plan editor and the athlete's read-only plan view.
/// Nothing is fetched until the user taps the button: every request costs
/// an LLM call and counts against the rate limit.
class PlanExplanationPanel extends StatelessWidget {
  final String planId;
  const PlanExplanationPanel({super.key, required this.planId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          PlanExplanationCubit(ctx.read<TrainingPlanRepository>()),
      child: _PanelView(planId: planId),
    );
  }
}

class _PanelView extends StatelessWidget {
  final String planId;
  const _PanelView({required this.planId});

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    return BlocBuilder<PlanExplanationCubit, PlanExplanationState>(
      builder: (context, state) {
        final cubit = context.read<PlanExplanationCubit>();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DT.s4),
          decoration: BoxDecoration(
            color: c.cardSurface,
            borderRadius: BorderRadius.circular(DT.rCard),
            boxShadow: [
              BoxShadow(
                  color: c.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_stories, color: c.accentPrimary),
                  const SizedBox(width: DT.s2),
                  Expanded(
                    child: Text(
                      'Magyarázat',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (state is PlanExplanationLoaded)
                    IconButton(
                      tooltip: 'Új magyarázat',
                      icon: Icon(Icons.refresh, color: c.iconLight),
                      onPressed: () => cubit.load(planId),
                    ),
                ],
              ),
              const SizedBox(height: DT.s2),
              _body(context, state, () => cubit.load(planId)),
            ],
          ),
        );
      },
    );
  }

  Widget _body(
      BuildContext context, PlanExplanationState state, VoidCallback load) {
    final c = DT.of(context);
    if (state is PlanExplanationLoading) {
      return Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: c.accentPrimary),
          ),
          const SizedBox(width: DT.s3),
          Expanded(
            child: Text(
              'Magyarázat készítése… ez akár fél percig is tarthat.',
              style: TextStyle(color: c.textSecondary, fontSize: 13),
            ),
          ),
        ],
      );
    }
    if (state is PlanExplanationLoaded) {
      return MarkdownBody(
        data: state.explanation.explanation,
        styleSheet: _styleSheet(context),
      );
    }
    if (state is PlanExplanationForbidden) {
      return Text('Ehhez a tervhez nincs hozzáférésed.',
          style: TextStyle(color: c.textSecondary, fontSize: 13));
    }
    if (state is PlanExplanationRateLimited) {
      return _RetryRow(
          message: 'Túl sok kérés — próbáld újra egy perc múlva.',
          onRetry: load);
    }
    if (state is PlanExplanationUnavailable) {
      return _RetryRow(
          message: 'A magyarázat most nem érhető el. Próbáld újra később.',
          onRetry: load);
    }
    if (state is PlanExplanationError) {
      return _RetryRow(message: state.message, onRetry: load);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rövid, közérthető összefoglaló arról, miért így épül fel a terv.',
          style: TextStyle(color: c.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: DT.s3),
        OutlinedButton.icon(
          onPressed: load,
          icon: const Icon(Icons.auto_awesome, size: 18),
          label: const Text('Magyarázat kérése'),
          style: OutlinedButton.styleFrom(
            foregroundColor: c.accentPrimary,
            side: BorderSide(color: c.accentPrimary),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DT.rCardSmall)),
          ),
        ),
      ],
    );
  }

  MarkdownStyleSheet _styleSheet(BuildContext context) {
    final c = DT.of(context);
    final body = TextStyle(color: c.textPrimary, fontSize: 14, height: 1.45);
    return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: body,
      listBullet: body,
      strong: body.copyWith(fontWeight: FontWeight.w700),
      em: body.copyWith(fontStyle: FontStyle.italic),
      h1: body.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
      h2: body.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
      h3: body.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
    );
  }
}

class _RetryRow extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _RetryRow({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    return Row(
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
    );
  }
}
