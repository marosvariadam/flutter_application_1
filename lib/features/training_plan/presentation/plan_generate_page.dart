import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/athlete_profile/bloc/athlete_profile_cubit.dart';
import 'package:flutter_application_1/features/athlete_profile/data/models/athlete_profile_model.dart';
import 'package:flutter_application_1/features/athlete_profile/data/repositories/athlete_profile_repository.dart';
import 'package:flutter_application_1/features/training_block/bloc/training_block_bloc.dart';
import 'package:flutter_application_1/features/training_block/data/models/training_block_model.dart';
import 'package:flutter_application_1/features/training_plan/bloc/plan_generate_cubit.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';
import 'package:flutter_application_1/features/training_plan/data/repositories/training_plan_repository.dart';
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
            return const _GeneratingView();
          }
          if (state is PlanGenerateSuccess) {
            return PlanResultView(
              result: state.result,
              onRestart: () {
                context.read<PlanGenerateCubit>().reset();
                setState(() => _inlineError = null);
              },
              onOpenEditor: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('A szerkesztő a következő fázisban készül el.'),
                ),
              ),
            );
          }
          return _FormView(
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

class _FormView extends StatelessWidget {
  final String athleteId;
  final String mode;
  final int weeks;
  final String? trainingBlockId;
  final String? inlineError;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<int> onWeeksChanged;
  final ValueChanged<String?> onTrainingBlockChanged;
  final VoidCallback onSubmit;

  const _FormView({
    required this.athleteId,
    required this.mode,
    required this.weeks,
    required this.trainingBlockId,
    required this.inlineError,
    required this.onModeChanged,
    required this.onWeeksChanged,
    required this.onTrainingBlockChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(DT.s5),
      children: [
        _ProfileSummary(athleteId: athleteId),
        const SizedBox(height: DT.s4),
        _SectionTitle('Mód'),
        ...PlanGenerationSources.wizardLabels.entries.map((e) {
          return _ModeOption(
            value: e.key,
            label: e.value,
            description: PlanGenerationSources.wizardDescriptions[e.key] ?? '',
            selected: e.key == mode,
            onSelect: () => onModeChanged(e.key),
          );
        }),
        const SizedBox(height: DT.s4),
        _SectionTitle('Hány hét?'),
        _WeeksSelector(weeks: weeks, onChanged: onWeeksChanged),
        const SizedBox(height: DT.s4),
        _SectionTitle('Tréningblokk (opcionális)'),
        _TrainingBlockPicker(
          selectedId: trainingBlockId,
          onSelected: onTrainingBlockChanged,
        ),
        if (inlineError != null) ...[
          const SizedBox(height: DT.s4),
          Container(
            padding: const EdgeInsets.all(DT.s3),
            decoration: BoxDecoration(
              color: DT.cardRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DT.rCardSmall),
              border: Border.all(color: DT.cardRed.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: DT.cardRed),
                const SizedBox(width: DT.s2),
                Expanded(
                  child: Text(
                    inlineError!,
                    style: TextStyle(color: DT.of(context).textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: DT.s5),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: onSubmit,
            icon: const Icon(Icons.auto_awesome),
            label: const Text(
              'Generálás',
              style: TextStyle(
                  fontSize: DT.s4, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: DT.metricBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DT.rCardSmall),
              ),
            ),
          ),
        ),
        const SizedBox(height: DT.s8),
      ],
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  final String athleteId;
  const _ProfileSummary({required this.athleteId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AthleteProfileCubit, AthleteProfileState>(
      builder: (ctx, state) {
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
          child: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AthleteProfileState state) {
    if (state is AthleteProfileLoading || state is AthleteProfileInitial) {
      return const SizedBox(
        height: 72,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state is AthleteProfileForbidden) {
      return Text('Nincs jogosultság.',
          style: TextStyle(color: DT.of(context).textSecondary));
    }
    if (state is AthleteProfileMissing) {
      return Row(
        children: [
          const Icon(Icons.warning_amber, color: DT.cardOrange),
          const SizedBox(width: DT.s2),
          Expanded(
            child: Text(
              'A sportolónak még nincs profilja. Töltsd ki a generáláshoz.',
              style: TextStyle(color: DT.of(context).textPrimary),
            ),
          ),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Vissza'),
          ),
        ],
      );
    }
    if (state is AthleteProfileLoaded ||
        state is AthleteProfileSaving) {
      final profile = state is AthleteProfileLoaded
          ? state.profile
          : (state as AthleteProfileSaving).pending;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: DT.of(context).iconLight),
              const SizedBox(width: DT.s2),
              Expanded(
                child: Text(
                  'Sportolói profil',
                  style: TextStyle(
                    fontSize: DT.s4,
                    fontWeight: FontWeight.w700,
                    color: DT.of(context).textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Szerkesztés',
                    style: TextStyle(color: DT.metricBlue)),
              ),
            ],
          ),
          const SizedBox(height: DT.s2),
          Wrap(
            spacing: DT.s2,
            runSpacing: DT.s1,
            children: [
              _MiniChip(
                  text:
                      AthleteProfileGoals.labels[profile.goal] ?? profile.goal),
              _MiniChip(
                  text: AthleteProfileExperienceLevels
                          .labels[profile.experienceLevel] ??
                      profile.experienceLevel),
              _MiniChip(
                  text:
                      '${profile.daysPerWeek}x · ${profile.sessionMinutes}p'),
              if (profile.avoidStressTags.isNotEmpty)
                _MiniChip(
                  text:
                      'Kerül: ${profile.avoidStressTags.length}',
                  color: DT.cardRed,
                ),
            ],
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  final Color? color;
  const _MiniChip({required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? DT.cardTeal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DT.s2, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DT.rChip),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: c.withValues(alpha: 0.9),
            fontSize: 11,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: DT.s2),
        child: Text(
          text,
          style: TextStyle(
            fontSize: DT.s4,
            fontWeight: FontWeight.w700,
            color: DT.of(context).textPrimary,
          ),
        ),
      );
}

class _ModeOption extends StatelessWidget {
  final String value;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onSelect;

  const _ModeOption({
    required this.value,
    required this.label,
    required this.description,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: DT.s2),
        padding: const EdgeInsets.all(DT.s3),
        decoration: BoxDecoration(
          color: selected
              ? DT.metricBlue.withValues(alpha: 0.08)
              : DT.of(context).cardSurface,
          borderRadius: BorderRadius.circular(DT.rCardSmall),
          border: Border.all(
            color:
                selected ? DT.metricBlue : DT.of(context).borderGrey,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color:
                  selected ? DT.metricBlue : DT.of(context).iconLight,
            ),
            const SizedBox(width: DT.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? DT.metricBlue
                          : DT.of(context).textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                          color: DT.of(context).textSecondary,
                          fontSize: DT.s3),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeksSelector extends StatelessWidget {
  final int weeks;
  final ValueChanged<int> onChanged;
  const _WeeksSelector({required this.weeks, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$weeks',
              style: const TextStyle(
                color: DT.metricBlue,
                fontSize: 48,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: DT.s2),
            Text(
              'hét',
              style: TextStyle(
                color: DT.of(context).textSecondary,
                fontSize: DT.s4,
              ),
            ),
          ],
        ),
        Slider(
          value: weeks.toDouble(),
          min: 2,
          max: 12,
          divisions: 10,
          activeColor: DT.metricBlue,
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}

class _TrainingBlockPicker extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const _TrainingBlockPicker({
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

class _GeneratingView extends StatefulWidget {
  const _GeneratingView();

  @override
  State<_GeneratingView> createState() => _GeneratingViewState();
}

class _GeneratingViewState extends State<_GeneratingView> {
  int _stageIndex = 0;
  Timer? _ticker;

  static const _stages = [
    'Jelöltek generálása…',
    'ML pontozás…',
    'Ellenőrzés…',
  ];

  @override
  void initState() {
    super.initState();
    // Cycle the hint every ~4 s. The real request takes 10–30 s, so this
    // is a UX cue, not a progress read.
    _ticker = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _stageIndex = (_stageIndex + 1) % _stages.length;
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48, height: 48,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: DT.s5),
          Text(
            _stages[_stageIndex],
            style: TextStyle(
              color: DT.of(context).textPrimary,
              fontSize: DT.s4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DT.s2),
          Text(
            'A generálás 10–30 másodpercet is igénybe vehet.',
            style: TextStyle(
                color: DT.of(context).textSecondary, fontSize: DT.s3),
          ),
        ],
      ),
    );
  }
}
