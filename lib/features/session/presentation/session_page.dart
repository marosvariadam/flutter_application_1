import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/session/bloc/session_bloc.dart';
import 'package:flutter_application_1/features/session/data/models/session_model.dart';

class SessionsPage extends StatelessWidget {
  const SessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SessionBloc()..add(LoadSessions()),
      child: Scaffold(
        backgroundColor: DT.bg,
        appBar: AppBar(
          backgroundColor: DT.bg,
          elevation: 0,
          title: const Text(
            'Edzés',
            style: TextStyle(
              color: DT.textPrimary,
              fontSize: DT.s4,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<SessionBloc, SessionState>(
          builder: (context, state) {
            if (state is SessionLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SessionError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: DT.cardRed),
                    const SizedBox(height: DT.s4),
                    Text(
                      state.message,
                      style: const TextStyle(
                        color: DT.textSecondary,
                        fontSize: DT.s4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DT.s4),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<SessionBloc>().add(LoadSessions()),
                      child: const Text('Újra'),
                    ),
                  ],
                ),
              );
            }

            if (state is SessionLoaded) {
              return ListView.separated(
                padding: const EdgeInsets.all(DT.s5),
                itemCount: state.sessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: DT.s4),
                itemBuilder: (context, index) {
                  final session = state.sessions[index];
                  return _SessionCard(
                    session: session,
                    onTap: () => context.go('/session-detail'),
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final SessionModel session;
  final VoidCallback onTap;

  const _SessionCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final difficultyColor = {
      'könnyű': DT.difficultyLight,
      'közepes': DT.difficultyMedium,
      'nehéz': DT.difficultyHard,
    }[session.difficulty.toLowerCase()] ??
        DT.difficultyMedium;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(DT.s5),
        decoration: BoxDecoration(
          color: DT.gbWhite,
          borderRadius: BorderRadius.circular(DT.s5),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 80,
              decoration: BoxDecoration(
                color: session.color,
                borderRadius: BorderRadius.circular(DT.s2),
              ),
            ),
            const SizedBox(width: DT.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        session.title,
                        style: const TextStyle(
                          color: DT.textPrimary,
                          fontSize: DT.s4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: DT.s2, vertical: DT.s1),
                        decoration: BoxDecoration(
                          color: difficultyColor,
                          borderRadius: BorderRadius.circular(DT.s2),
                        ),
                        child: Text(
                          session.difficulty,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: DT.s3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DT.s1),
                  Text(
                    'Edző: ${session.trainer}',
                    style: const TextStyle(
                      color: DT.textSecondary,
                      fontSize: DT.s3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: DT.s1),
                  Text(
                    'Leírás: ${session.description}',
                    style: const TextStyle(
                      color: DT.textSecondary,
                      fontSize: DT.s3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: DT.s1),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.access_time,
                        text: session.duration,
                      ),
                      const SizedBox(width: DT.s2),
                      _InfoChip(
                        icon: Icons.local_fire_department,
                        text: session.kcal,
                      ),
                    ],
                  ),
                  const SizedBox(height: DT.s2),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: session.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(DT.rChip),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: session.color,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: DT.s4, color: DT.iconLight),
        const SizedBox(width: DT.s1),
        Text(
          text,
          style: const TextStyle(
            color: DT.textSecondary,
            fontSize: DT.s3,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
