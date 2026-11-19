import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/athlete_profile/bloc/athlete_profile_cubit.dart';
import 'package:flutter_application_1/features/athlete_profile/data/repositories/athlete_profile_repository.dart';
import 'package:flutter_application_1/features/training_block/bloc/training_block_bloc.dart';
import 'package:flutter_application_1/features/training_plan/bloc/plan_generate_cubit.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';
import 'package:flutter_application_1/features/training_plan/data/repositories/training_plan_repository.dart';
import 'package:flutter_application_1/features/training_plan/presentation/widgets/plan_generate_form_view.dart';
import 'package:flutter_application_1/features/training_plan/presentation/widgets/plan_generating_view.dart';
import 'package:flutter_application_1/features/training_plan/presentation/widgets/plan_result_view.dart';

/// Trainer-facing wizard for `POST /api/plan/generate`.
///
/// Step 1: athlete profile summary + mode / weeks / optional training
/// block form. Step 2: staged loading hint. Step 3: `PlanResultView` with
/// the saved plan and candidate comparison.
class PlanGeneratePage extends StatelessWidget {
  final String athleteId;
  const PlanGeneratePage({super.key, required this.athleteId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (ctx) =>
              AthleteProfileCubit(ctx.read<AthleteProfileRepository>())
                ..loadForAthlete(athleteId),
        ),
        BlocProvider(
          create: (ctx) =>
              PlanGenerateCubit(ctx.read<TrainingPlanRepository>()),
        ),
      ],
      child: _PlanGenerateView(athleteId: athleteId),
    );
  }
}

class _PlanGenerateView extends StatefulWidget {
  final String athleteId;
  const _PlanGenerateView({required this.athleteId});

  @override
  State<_PlanGenerateView> createState() => _PlanGenerateViewState();
}

class _PlanGenerateViewState extends State<_PlanGenerateView> {
  String _mode = PlanGenerationSources.hybrid;
  int _weeks = 4;
  String? _trainingBlockId;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<TrainingBlockBloc>()
          .add(LoadTrainingBlocks(widget.athleteId));
    });
  }

  void _submit() {
    setState(() => _inlineError = null);
    context.read<PlanGenerateCubit>().generate(
          athleteId: widget.athleteId,
          mode: _mode,
          weeks: _weeks,
          trainingBlockId: _trainingBlockId,
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
          'AI edzésterv',
          style: TextStyle(
            color: DT.of(context).textPrimary,
            fontSize: DT.s4,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<PlanGenerateCubit, PlanGenerateState>(
        listener: (ctx, state) {
          if (state is PlanGenerateValidationError) {
            setState(() => _inlineError = state.message);
          } else if (state is PlanGenerateForbidden) {
            setState(() => _inlineError =
                'Nincs jogosultságod ehhez a sportolóhoz.');
          } else if (state is PlanGenerateRateLimited) {
            setState(() => _inlineError =
                'Túl sok kérés — próbáld újra egy perc múlva.');
          } else if (state is PlanGenerateLlmUnavailable) {
            setState(() => _inlineError =
                'Az LLM nem elérhető: ${state.message}');
          } else if (state is PlanGenerateError) {
            setState(() => _inlineError = state.message);
          }
        },
        builder: (ctx, state) {
          if (state is PlanGenerateRunning) {
            return const PlanGeneratingView();
          }
          if (state is PlanGenerateSuccess) {
            return PlanResultView(
              result: state.result,
              onRestart: () {
                context.read<PlanGenerateCubit>().reset();
                setState(() => _inlineError = null);
              },
              onOpenEditor: () => context.push(
                '/plan/${state.result.plan.id}/edit',
                extra: state.result.plan,
              ),
            );
          }
          return PlanGenerateFormView(
            athleteId: widget.athleteId,
            mode: _mode,
            weeks: _weeks,
            trainingBlockId: _trainingBlockId,
            inlineError: _inlineError,
            onModeChanged: (m) => setState(() => _mode = m),
            onWeeksChanged: (w) => setState(() => _weeks = w),
            onTrainingBlockChanged: (id) =>
                setState(() => _trainingBlockId = id),
            onSubmit: _submit,
          );
        },
      ),
    );
  }
}
