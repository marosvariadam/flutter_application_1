import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/trainer/bloc/roster_bloc.dart';
import 'package:flutter_application_1/features/trainer/data/models/trainer_request_model.dart';
import 'package:flutter_application_1/features/trainer/data/repositories/roster_repository.dart';

class RosterPage extends StatelessWidget {
  const RosterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          RosterBloc(ctx.read<RosterRepository>())..add(LoadRoster()),
      child: const _RosterView(),
    );
  }
}

class _RosterView extends StatelessWidget {
  const _RosterView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.bg,
      appBar: AppBar(
        backgroundColor: DT.bg,
        elevation: 0,
        leading: BackButton(color: DT.textPrimary),
        title: const Text('Sportolók',
            style: TextStyle(
                color: DT.textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined,
                color: DT.textPrimary),
            onPressed: () =>
                context.push('/athletes/create').then((_) {
              context.read<RosterBloc>().add(LoadRoster());
            }),
          ),
        ],
      ),
      body: BlocBuilder<RosterBloc, RosterState>(
        builder: (context, state) {
          if (state is RosterLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is RosterError) {
            return _ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<RosterBloc>().add(LoadRoster()),
            );
          }
          if (state is RosterLoaded) {
            if (state.athletes.isEmpty) {
              return const _EmptyView();
            }
            return NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is ScrollEndNotification &&
                    n.metrics.pixels >=
                        n.metrics.maxScrollExtent - 200) {
                  context.read<RosterBloc>().add(LoadMoreRoster());
                }
                return false;
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(DT.s5),
                itemCount: state.athletes.length +
                    (state.hasMore ? 1 : 0),
                separatorBuilder: (_, __) =>
                    const SizedBox(height: DT.s3),
                itemBuilder: (context, i) {
                  if (i == state.athletes.length) {
                    return const Center(
                        child: Padding(
                      padding: EdgeInsets.all(DT.s4),
                      child: CircularProgressIndicator(),
                    ));
                  }
                  final athlete = state.athletes[i];
                  return _AthleteCard(athlete: athlete);
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _AthleteCard extends StatelessWidget {
  final AthleteModel athlete;
  const _AthleteCard({required this.athlete});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DT.gbWhite,
      borderRadius: BorderRadius.circular(DT.rCardSmall),
      child: InkWell(
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        onTap: () => context.push('/workout/review/${athlete.id}'),
        child: Padding(
          padding: const EdgeInsets.all(DT.s4),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: DT.metricBlue.withOpacity(0.15),
                child: Text(
                  athlete.firstName.isNotEmpty
                      ? athlete.firstName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: DT.metricBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: DT.s5),
                ),
              ),
              const SizedBox(width: DT.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(athlete.fullName,
                        style: const TextStyle(
                            color: DT.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: DT.s4)),
                    const SizedBox(height: 2),
                    Text(athlete.email,
                        style: const TextStyle(
                            color: DT.textSecondary,
                            fontSize: DT.s3)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (action) async {
                  if (action == 'edit') {
                    await context.push('/athletes/${athlete.id}/edit');
                    if (context.mounted) {
                      context.read<RosterBloc>().add(LoadRoster());
                    }
                  } else if (action == 'reset') {
                    _showResetPasswordDialog(context, athlete);
                  } else if (action == 'delete') {
                    _showDeleteDialog(context, athlete);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'edit', child: Text('Szerkesztés')),
                  const PopupMenuItem(
                      value: 'reset', child: Text('Jelszó visszaállítás')),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Text('Törlés',
                          style: TextStyle(color: DT.cardRed))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, AthleteModel athlete) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sportoló törlése'),
        content: Text(
            '${athlete.fullName} biztosan törölni szeretnéd a csapatodból?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Mégse')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<RosterBloc>().add(DeleteAthlete(athlete.id));
            },
            child: const Text('Törlés',
                style: TextStyle(color: DT.cardRed)),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, AthleteModel athlete) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Jelszó visszaállítása'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration:
              const InputDecoration(labelText: 'Új jelszó'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Mégse')),
          TextButton(
            onPressed: () {
              if (ctrl.text.length >= 6) {
                Navigator.pop(ctx);
                context.read<RosterBloc>().add(
                      ResetAthletePassword(athlete.id, ctrl.text),
                    );
              }
            },
            child: const Text('Beállít'),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline,
              size: 64, color: DT.iconLightGrey),
          const SizedBox(height: DT.s4),
          const Text('Még nincs sportoló a csapatodban.',
              style:
                  TextStyle(color: DT.textSecondary, fontSize: DT.s4)),
          const SizedBox(height: DT.s4),
          ElevatedButton.icon(
            onPressed: () => context.push('/athletes/create'),
            icon: const Icon(Icons.person_add),
            label: const Text('Sportoló hozzáadása'),
            style: ElevatedButton.styleFrom(
                backgroundColor: DT.metricBlue),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: DT.cardRed),
          const SizedBox(height: DT.s4),
          Text(message,
              style: const TextStyle(
                  color: DT.textSecondary, fontSize: DT.s4)),
          const SizedBox(height: DT.s4),
          ElevatedButton(
              onPressed: onRetry, child: const Text('Újra')),
        ],
      ),
    );
  }
}
