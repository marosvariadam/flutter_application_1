import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/athlete_profile/bloc/athlete_profile_cubit.dart';
import 'package:flutter_application_1/features/athlete_profile/data/models/athlete_profile_model.dart';
import 'package:flutter_application_1/features/athlete_profile/data/repositories/athlete_profile_repository.dart';
import 'package:flutter_application_1/features/athlete_profile/presentation/widgets/athlete_profile_edit_sheet.dart';

/// Trainer-facing summary of an athlete's structured profile. The widget
/// owns its own `AthleteProfileCubit` so it can be dropped into any page
/// without having to lift state. The card also hosts the edit sheet with
/// the muscle-group priority sliders described in the AI plan generator
/// spec (0.5–1.5, default 1.0).
class TrainerAthleteProfileCard extends StatelessWidget {
  final String athleteId;
  const TrainerAthleteProfileCard({super.key, required this.athleteId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          AthleteProfileCubit(ctx.read<AthleteProfileRepository>())
            ..loadForAthlete(athleteId),
      child: _TrainerProfileCardView(athleteId: athleteId),
    );
  }
}

class _TrainerProfileCardView extends StatelessWidget {
  final String athleteId;
  const _TrainerProfileCardView({required this.athleteId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AthleteProfileCubit, AthleteProfileState>(
      builder: (context, state) {
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
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state is AthleteProfileForbidden) {
      return Text(
        'Nincs jogosultságod ehhez a profilhoz.',
        style: TextStyle(color: DT.of(context).textSecondary),
      );
    }
    if (state is AthleteProfileError) {
      return Row(
        children: [
          const Icon(Icons.error_outline, color: DT.cardRed),
          const SizedBox(width: DT.s2),
          Expanded(
            child: Text(state.message,
                style: TextStyle(color: DT.of(context).textSecondary)),
          ),
          TextButton(
            onPressed: () => context
                .read<AthleteProfileCubit>()
                .loadForAthlete(athleteId),
            child: const Text('Újra'),
          ),
        ],
      );
    }
    if (state is AthleteProfileMissing ||
        (state is AthleteProfileSaveFailed && state.profile == null)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            onEdit: () => _openEditor(context, _defaultProfile()),
            isMissing: true,
          ),
          const SizedBox(height: DT.s3),
          Text(
            'Ez a sportoló még nem töltötte ki a strukturált profilt. '
            'Vedd fel az adatokat, hogy az AI edzéstervet tudjon generálni.',
            style: TextStyle(
                color: DT.of(context).textSecondary, fontSize: DT.s3),
          ),
        ],
      );
    }

    final profile = state.visibleProfile;
    if (profile == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardHeader(
          onEdit: () => _openEditor(context, profile),
          isMissing: false,
        ),
        const SizedBox(height: DT.s3),
        _ProfileRow(
          label: 'Cél',
          value: AthleteProfileGoals.labels[profile.goal] ?? profile.goal,
        ),
        _ProfileRow(
          label: 'Szint',
          value: AthleteProfileExperienceLevels.labels[profile.experienceLevel] ??
              profile.experienceLevel,
        ),
        _ProfileRow(
          label: 'Hetente',
          value: '${profile.daysPerWeek}x · ${profile.sessionMinutes} perc',
        ),
        if (profile.weightKg != null)
          _ProfileRow(
            label: 'Testsúly',
            value: '${profile.weightKg!.toStringAsFixed(1)} kg',
          ),
        if (profile.availableEquipment.isNotEmpty) ...[
          const SizedBox(height: DT.s2),
          Text('Elérhető eszközök',
              style: TextStyle(
                  color: DT.of(context).textSecondary, fontSize: DT.s3)),
          const SizedBox(height: DT.s1),
          Wrap(
            spacing: DT.s2,
            runSpacing: DT.s1,
            children: profile.availableEquipment
                .map((e) => _MetaChip(
                    label: AthleteProfileEquipment.labels[e] ?? e))
                .toList(),
          ),
        ],
        if (profile.avoidStressTags.isNotEmpty) ...[
          const SizedBox(height: DT.s2),
          Text('Kerülendő terhelések',
              style: TextStyle(
                  color: DT.of(context).textSecondary, fontSize: DT.s3)),
          const SizedBox(height: DT.s1),
          Wrap(
            spacing: DT.s2,
            runSpacing: DT.s1,
            children: profile.avoidStressTags
                .map((t) => _MetaChip(
                      label: AthleteProfileStressTags.labels[t] ?? t,
                      color: DT.cardRed,
                    ))
                .toList(),
          ),
        ],
        if (profile.muscleGroupPriority.isNotEmpty) ...[
          const SizedBox(height: DT.s2),
          Text('Izomcsoport prioritás',
              style: TextStyle(
                  color: DT.of(context).textSecondary, fontSize: DT.s3)),
          const SizedBox(height: DT.s1),
          Wrap(
            spacing: DT.s2,
            runSpacing: DT.s1,
            children: profile.muscleGroupPriority.entries
                .map((e) => _MetaChip(
                      label: '${e.key} · ${e.value.toStringAsFixed(2)}×',
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  AthleteProfileModel _defaultProfile() => AthleteProfileModel(
        athleteId: athleteId,
        goal: AthleteProfileGoals.generalFitness,
        experienceLevel: AthleteProfileExperienceLevels.beginner,
        daysPerWeek: 3,
        sessionMinutes: 60,
      );

  void _openEditor(BuildContext context, AthleteProfileModel profile) {
    final cubit = context.read<AthleteProfileCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DT.of(context).cardSurfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DT.rCard)),
      ),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: AthleteProfileEditSheet(athleteId: athleteId, initial: profile),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final VoidCallback onEdit;
  final bool isMissing;
  const _CardHeader({required this.onEdit, required this.isMissing});

  @override
  Widget build(BuildContext context) {
    return Row(
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
        TextButton.icon(
          onPressed: onEdit,
          icon: Icon(isMissing ? Icons.add : Icons.edit,
              size: 16, color: DT.metricBlue),
          label: Text(
            isMissing ? 'Felvétel' : 'Szerkesztés',
            style: const TextStyle(color: DT.metricBlue),
          ),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DT.s1),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(
                    color: DT.of(context).textSecondary,
                    fontSize: DT.s3)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: DT.of(context).textPrimary, fontSize: DT.s3)),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color? color;
  const _MetaChip({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? DT.cardTeal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DT.s2, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DT.rChip),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c.withValues(alpha: 0.9))),
    );
  }
}
