import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:flutter_application_1/features/onboarding/data/models/onboarding_models.dart';

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
        builder: (context, state) {
          if (state is OnboardingInitial) {
            context.read<OnboardingBloc>().add(LoadAllResponses());
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OnboardingLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OnboardingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: DT.cardRed),
                  const SizedBox(height: DT.s4),
                  Text(state.message,
                      style:
                          TextStyle(color: DT.of(context).textSecondary)),
                  const SizedBox(height: DT.s4),
                  ElevatedButton(
                    onPressed: () => context
                        .read<OnboardingBloc>()
                        .add(LoadAllResponses()),
                    child: const Text('Újra'),
                  ),
                ],
              ),
            );
          }
          if (state is OnboardingResponsesLoaded) {
            if (state.responses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined,
                        size: 64, color: DT.of(context).iconLightGrey),
                    const SizedBox(height: DT.s4),
                    Text('Még nincs beérkezett válasz.',
                        style: TextStyle(
                            color: DT.of(context).textSecondary, fontSize: DT.s4)),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(DT.s4),
              itemCount: state.responses.length,
              separatorBuilder: (_, __) => const SizedBox(height: DT.s3),
              itemBuilder: (context, i) {
                final response = state.responses[i];
                return _ResponseCard(response: response);
              },
            );
          }
          return const SizedBox.shrink();
        },
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
                  color: DT.metricBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline,
                    color: DT.metricBlue, size: 20),
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
              Icon(Icons.chevron_right, color: DT.of(context).textGrey),
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
