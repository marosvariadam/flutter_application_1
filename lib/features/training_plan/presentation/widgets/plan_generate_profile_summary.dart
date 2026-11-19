import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/athlete_profile/bloc/athlete_profile_cubit.dart';
import 'package:flutter_application_1/features/athlete_profile/data/models/athlete_profile_model.dart';

/// Athlete profile card at the top of the plan generator form. Reads the
/// page's `AthleteProfileCubit`; a missing profile shows a back hint.
class PlanGenerateProfileSummary extends StatelessWidget {
  final String athleteId;
  const PlanGenerateProfileSummary({super.key, required this.athleteId});

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
      return Text('Nincs jogosultságod a sportoló profiljához.',
          style: TextStyle(color: DT.of(context).textSecondary));
    }
    if (state is AthleteProfileError) {
      final c = DT.of(context);
      return Row(
        children: [
          Icon(Icons.error_outline, color: c.accentDanger),
          const SizedBox(width: DT.s2),
          Expanded(
            child: Text(state.message,
                style: TextStyle(color: c.textPrimary)),
          ),
          TextButton(
            onPressed: () => context
                .read<AthleteProfileCubit>()
                .loadForAthlete(athleteId),
            child: Text('Újra', style: TextStyle(color: c.accentPrimary)),
          ),
        ],
      );
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
    final profile = state.visibleProfile;
    if (profile != null) {
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
