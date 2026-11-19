import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/athlete_profile/bloc/athlete_profile_cubit.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';
import 'package:flutter_application_1/features/training_plan/presentation/widgets/plan_generate_mode_option.dart';
import 'package:flutter_application_1/features/training_plan/presentation/widgets/plan_generate_profile_summary.dart';
import 'package:flutter_application_1/features/training_plan/presentation/widgets/plan_generate_training_block_picker.dart';
import 'package:flutter_application_1/features/training_plan/presentation/widgets/plan_generate_weeks_selector.dart';

/// Step 1 of the plan generator wizard: profile summary, mode, weeks,
/// optional training block, inline error and the submit button.
class PlanGenerateFormView extends StatelessWidget {
  final String athleteId;
  final String mode;
  final int weeks;
  final String? trainingBlockId;
  final String? inlineError;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<int> onWeeksChanged;
  final ValueChanged<String?> onTrainingBlockChanged;
  final VoidCallback onSubmit;

  const PlanGenerateFormView({
    super.key,
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
        PlanGenerateProfileSummary(athleteId: athleteId),
        const SizedBox(height: DT.s4),
        _SectionTitle('Mód'),
        ...PlanGenerationSources.wizardLabels.entries.map((e) {
          return PlanGenerateModeOption(
            value: e.key,
            label: e.value,
            description: PlanGenerationSources.wizardDescriptions[e.key] ?? '',
            selected: e.key == mode,
            onSelect: () => onModeChanged(e.key),
          );
        }),
        const SizedBox(height: DT.s4),
        _SectionTitle('Hány hét?'),
        PlanGenerateWeeksSelector(weeks: weeks, onChanged: onWeeksChanged),
        const SizedBox(height: DT.s4),
        _SectionTitle('Tréningblokk (opcionális)'),
        PlanGenerateTrainingBlockPicker(
          athleteId: athleteId,
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
        BlocBuilder<AthleteProfileCubit, AthleteProfileState>(
          builder: (context, profileState) {
            final ready = profileState.visibleProfile != null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SubmitButton(onSubmit: ready ? onSubmit : null),
                if (profileState is AthleteProfileMissing) ...[
                  const SizedBox(height: DT.s2),
                  Text(
                    'A generáláshoz előbb töltsd ki a sportoló profilját '
                    'az adatlapján.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: DT.of(context).textSecondary, fontSize: 13),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: DT.s8),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final VoidCallback? onSubmit;
  const _SubmitButton({required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onSubmit,
        icon: const Icon(Icons.auto_awesome),
        label: const Text(
          'Generálás',
          style: TextStyle(fontSize: DT.s4, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accentPrimary,
          foregroundColor: c.textOnAccent,
          disabledBackgroundColor: c.borderGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DT.rCardSmall),
          ),
        ),
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
