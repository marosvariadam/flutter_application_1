import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:flutter_application_1/features/onboarding/data/models/onboarding_models.dart';
import 'package:flutter_application_1/app/shared/reload_and_wait.dart';
import 'package:flutter_application_1/app/shared/widgets/empty_state.dart';
import 'package:flutter_application_1/app/shared/widgets/error_state.dart';
import 'package:flutter_application_1/app/shared/widgets/fade_switcher.dart';
import 'package:flutter_application_1/app/shared/widgets/refreshable_fill.dart';
import 'package:flutter_application_1/app/shared/widgets/skeleton.dart';

class TrainerResponsesPage extends StatelessWidget {
  const TrainerResponsesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.of(context).bg,
      appBar: AppBar(
        backgroundColor: DT.of(context).bg,
        elevation: 0,
        leading: BackButton(color: DT.of(context).textPrimary),
        title: Text('Felmérő válaszok',
            style: TextStyle(
                color: DT.of(context).textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: BlocBuilder<OnboardingBloc, OnboardingState>(
        builder: (context, state) =>
            FadeSwitcher(child: _body(context, state)),
      ),
    );
  }

  Widget _body(BuildContext context, OnboardingState state) {
    final bloc = context.read<OnboardingBloc>();
    if (state is OnboardingInitial) {
      bloc.add(LoadAllResponses());
    }
    if (state is OnboardingError) {
      return ErrorState(
        key: const ValueKey('error'),
        message: state.message,
        onRetry: () => bloc.add(LoadAllResponses()),
      );
    }
    if (state is! OnboardingResponsesLoaded) {
      return const SkeletonList(
          key: ValueKey('loading'), padding: EdgeInsets.all(DT.s4));
    }
    Future<void> refresh() => reloadAndWait(
        bloc,
        () => bloc.add(LoadAllResponses()),
        (s) => s is OnboardingResponsesLoaded || s is OnboardingError);
    if (state.responses.isEmpty) {
      return RefreshIndicator(
        key: const ValueKey('empty'),
        onRefresh: refresh,
        child: const RefreshableFill(
          child: EmptyState(
            icon: Icons.assignment_outlined,
            title: 'Még nincs beérkezett válasz',
            message: 'Az atléták kérdőív-válaszai itt jelennek meg.',
          ),
        ),
      );
    }
    return RefreshIndicator(
      key: const ValueKey('content'),
      onRefresh: refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(DT.s4),
        itemCount: state.responses.length,
        separatorBuilder: (_, __) => const SizedBox(height: DT.s3),
        itemBuilder: (context, i) =>
            _ResponseCard(response: state.responses[i]),
      ),
    );
  }
}

class _ResponseCard extends StatelessWidget {
  final OnboardingResponse response;
  const _ResponseCard({required this.response});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DT.of(context).cardSurface,
      borderRadius: BorderRadius.circular(DT.rCardSmall),
      child: InkWell(
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        onTap: () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(DT.s4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DT.of(context).accentPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_outline,
                    color: DT.of(context).accentPrimary, size: 20),
              ),
              const SizedBox(width: DT.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      response.athleteName ?? response.athleteId,
                      style: TextStyle(
                          color: DT.of(context).textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: DT.s3),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${response.answers.length} válasz · ${DateFormat('yyyy.MM.dd').format(response.submittedAt)}',
                      style: TextStyle(
                          color: DT.of(context).textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: DT.of(context).textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DT.of(context).bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(DT.s5),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: DT.s4),
                decoration: BoxDecoration(
                  color: DT.of(context).borderGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              response.athleteName ?? 'Sportoló',
              style: TextStyle(
                  color: DT.of(context).textPrimary,
                  fontSize: DT.s5,
                  fontWeight: FontWeight.w700),
            ),
            Text(
              'Beküldve: ${DateFormat('yyyy.MM.dd HH:mm').format(response.submittedAt)}',
              style: TextStyle(color: DT.of(context).textSecondary, fontSize: DT.s3),
            ),
            const SizedBox(height: DT.s5),
            ...response.answers.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: DT.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${e.key + 1}. kérdés',
                          style: TextStyle(
                              color: DT.of(context).textSecondary, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(e.value.answer,
                          style: TextStyle(
                              color: DT.of(context).textPrimary, fontSize: DT.s3)),
                      Divider(color: DT.of(context).borderLight, height: DT.s5),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
