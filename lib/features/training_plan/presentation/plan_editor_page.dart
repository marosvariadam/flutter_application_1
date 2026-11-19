import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/shared/widgets/empty_state.dart';
import 'package:flutter_application_1/features/athlete_profile/bloc/athlete_profile_cubit.dart';
import 'package:flutter_application_1/features/athlete_profile/data/repositories/athlete_profile_repository.dart';
import 'package:flutter_application_1/features/training_plan/bloc/plan_editor_bloc.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';
import 'package:flutter_application_1/features/training_plan/data/repositories/training_plan_repository.dart';
import 'package:flutter_application_1/features/training_plan/presentation/widgets/plan_editor_accept_sheet.dart';
import 'package:flutter_application_1/features/training_plan/presentation/widgets/plan_editor_day_tabs.dart';
import 'package:flutter_application_1/features/training_plan/presentation/widgets/plan_editor_refine_bar.dart';
import 'package:flutter_application_1/features/training_plan/presentation/widgets/plan_editor_volume_chart.dart';
import 'package:flutter_application_1/features/training_plan/presentation/widgets/plan_explanation_panel.dart';

/// Trainer-facing plan editor. Owned state (plan, violations, refining
/// flags, undo snapshot) lives in [PlanEditorBloc]; this file is the UI
/// shell plus the Accept → Materialize sequencing.
///
/// Expected entry: `/plan/:id/edit` with the plan passed in as a go_router
/// `extra`. The route is pushed from the generate wizard's result view.
/// The backend has no GET-by-id endpoint, so a deep link without the plan
/// ([plan] null) shows an explanation instead of the editor.
class PlanEditorPage extends StatelessWidget {
  final TrainingPlanModel? plan;
  const PlanEditorPage({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final plan = this.plan;
    if (plan == null) {
      final c = DT.of(context);
      return Scaffold(
        backgroundColor: c.bg,
        appBar: AppBar(
          backgroundColor: c.bg,
          elevation: 0,
          leading: BackButton(color: c.textPrimary),
        ),
        body: EmptyState(
          icon: Icons.link_off,
          title: 'A terv nem nyitható meg',
          message: 'A szerkesztő a tervgenerálás eredményéből nyitható meg.',
          actionLabel: 'Vissza',
          onAction: () => Navigator.of(context).maybePop(),
        ),
      );
    }
    return MultiBlocProvider(
      providers: [
        // The volume chart draws MEV/MRV lines for the athlete's
        // experience level — load the profile up-front so the chart isn't
        // empty on first paint.
        BlocProvider(
          create: (ctx) =>
              AthleteProfileCubit(ctx.read<AthleteProfileRepository>())
                ..loadForAthlete(plan.athleteId),
        ),
        BlocProvider(
          create: (ctx) => PlanEditorBloc(
            ctx.read<TrainingPlanRepository>(),
          )..add(PlanEditorLoad(plan: plan)),
        ),
      ],
      child: _PlanEditorView(plan: plan),
    );
  }
}

class _PlanEditorView extends StatelessWidget {
  final TrainingPlanModel plan;
  const _PlanEditorView({required this.plan});

  Future<void> _openAcceptSheet(
      BuildContext context, PlanEditorReady state) async {
    final bloc = context.read<PlanEditorBloc>();
    final needsAccept = state.plan.status == PlanStatuses.draft;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DT.of(context).cardSurfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DT.rCard)),
      ),
      builder: (sheet) => PlanEditorAcceptSheet(
        needsAcceptFirst: needsAccept,
        onConfirm: (date) {
          Navigator.of(sheet).pop();
          // Accepts a draft first, then schedules (one sequential handler).
          bloc.add(PlanEditorMaterialize(date));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.of(context).bg,
      appBar: AppBar(
        backgroundColor: DT.of(context).bg,
        elevation: 0,
        leading: BackButton(color: DT.of(context).textPrimary),
        title: Text(
          'Terv szerkesztése',
          style: TextStyle(
            color: DT.of(context).textPrimary,
            fontSize: DT.s4,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          BlocBuilder<PlanEditorBloc, PlanEditorState>(
            buildWhen: (p, c) =>
                c is PlanEditorReady &&
                (p is! PlanEditorReady ||
                    p.isSaving != c.isSaving ||
                    p.isValidating != c.isValidating),
            builder: (context, state) {
              if (state is! PlanEditorReady ||
                  !(state.isSaving || state.isValidating)) {
                return const SizedBox.shrink();
              }
              return const Padding(
                padding: EdgeInsets.only(right: DT.s4),
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<PlanEditorBloc, PlanEditorState>(
        listener: (context, state) {
          if (state is PlanEditorMaterialized) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Ütemezve: ${state.result.workoutsCreated} edzés létrehozva.'),
              ),
            );
            // Navigate the trainer to the calendar (existing route in
            // app_router.dart). The editor is left behind in nav history
            // so back returns the trainer to the athlete detail page.
            context.go('/home');
          } else if (state is PlanEditorReady &&
              state.lastErrorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.lastErrorMessage!),
                backgroundColor: DT.cardRed,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PlanEditorMaterialized || state is PlanEditorInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is! PlanEditorReady) return const SizedBox.shrink();
          return _EditorBody(state: state, onAccept: _openAcceptSheet);
        },
      ),
      bottomNavigationBar: BlocBuilder<PlanEditorBloc, PlanEditorState>(
        builder: (context, state) =>
            state is PlanEditorReady ? const PlanEditorRefineBar() : const SizedBox.shrink(),
      ),
    );
  }
}

class _EditorBody extends StatelessWidget {
  final PlanEditorReady state;
  final Future<void> Function(BuildContext, PlanEditorReady) onAccept;
  const _EditorBody({required this.state, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    final profile = _profile(context);
    return ListView(
      padding: const EdgeInsets.all(DT.s4),
      children: [
        _HeaderCard(state: state, onAccept: () => onAccept(context, state)),
        const SizedBox(height: DT.s4),
        PlanEditorVolumeChart(plan: state.plan, profile: profile),
        const SizedBox(height: DT.s4),
        PlanEditorDayTabs(
          plan: state.plan,
          allViolations: [...state.errors, ...state.warnings],
          highlightedDays: state.highlightedDays,
        ),
        const SizedBox(height: DT.s4),
        PlanExplanationPanel(planId: state.plan.id),
        const SizedBox(height: DT.s8),
      ],
    );
  }

  dynamic _profile(BuildContext context) {
    final s = context.watch<AthleteProfileCubit>().state;
    if (s is AthleteProfileLoaded) return s.profile;
    if (s is AthleteProfileSaving) return s.pending;
    return null;
  }
}

class _HeaderCard extends StatelessWidget {
  final PlanEditorReady state;
  final VoidCallback onAccept;
  const _HeaderCard({required this.state, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    final plan = state.plan;
    final errCount = state.errors.length;
    final warnCount = state.warnings.length;

    return Container(
      padding: const EdgeInsets.all(DT.s4),
      decoration: BoxDecoration(
        color: DT.of(context).cardSurface,
        borderRadius: BorderRadius.circular(DT.rCard),
        boxShadow: [
          BoxShadow(
              color: DT.of(context).shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.title,
                  style: TextStyle(
                    color: DT.of(context).textPrimary,
                    fontSize: DT.s5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StatusChip(status: plan.status),
            ],
          ),
          const SizedBox(height: DT.s2),
          Wrap(
            spacing: DT.s2,
            runSpacing: DT.s1,
            children: [
              _InfoPill(text: '${plan.weeks} hét'),
              _InfoPill(
                  text: PlanSplits.labels[plan.split] ?? plan.split),
              _InfoPill(text: '${plan.days.length} nap / hét'),
              _InfoPill(text: '${plan.totalExercises} gyakorlat'),
            ],
          ),
          if (errCount > 0 || warnCount > 0) ...[
            const SizedBox(height: DT.s3),
            Row(
              children: [
                if (errCount > 0) ...[
                  _CountChip(
                      count: errCount, label: 'Hiba', color: DT.cardRed),
                  const SizedBox(width: DT.s2),
                ],
                if (warnCount > 0)
                  _CountChip(
                      count: warnCount,
                      label: 'Figyelem',
                      color: DT.cardOrange),
              ],
            ),
          ],
          const SizedBox(height: DT.s3),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (state.canAccept || state.canMaterialize) &&
                          !state.isAccepting
                      ? onAccept
                      : null,
                  icon: state.isAccepting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(plan.status == PlanStatuses.draft
                      ? 'Elfogad + Ütemez'
                      : 'Ütemezés'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DT.metricBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: DT.s3),
                    disabledBackgroundColor:
                        DT.of(context).borderGrey,
                  ),
                ),
              ),
            ],
          ),
          if (errCount > 0 && plan.status == PlanStatuses.draft) ...[
            const SizedBox(height: DT.s2),
            Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 14, color: DT.cardRed),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Hibákat kell javítani az elfogadás előtt.',
                    style: TextStyle(
                        color: DT.of(context).textSecondary,
                        fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == PlanStatuses.draft
        ? DT.cardOrange
        : status == PlanStatuses.accepted
            ? DT.cardTeal
            : status == PlanStatuses.materialized
                ? DT.metricBlue
                : DT.of(context).iconLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DT.s2, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DT.rChip),
      ),
      child: Text(
        PlanStatuses.labels[status] ?? status,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String text;
  const _InfoPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DT.s2, vertical: 2),
      decoration: BoxDecoration(
        color: DT.of(context).bg,
        borderRadius: BorderRadius.circular(DT.rChip),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: DT.of(context).textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _CountChip({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DT.s2, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DT.rChip),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

