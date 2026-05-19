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
      backgroundColor: DT.of(context).bg,
      appBar: AppBar(
        backgroundColor: DT.of(context).bg,
        elevation: 0,
        leading: BackButton(color: DT.of(context).textPrimary),
        title: Text('Sportolók',
            style: TextStyle(
                color: DT.of(context).textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
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
      color: DT.of(context).cardSurface,
      borderRadius: BorderRadius.circular(DT.rCardSmall),
      child: InkWell(
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        onTap: () => context.push('/athlete-detail/${athlete.id}'),
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
                        style: TextStyle(
                            color: DT.of(context).textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: DT.s4)),
                    const SizedBox(height: 2),
                    Text(athlete.email,
                        style: TextStyle(
                            color: DT.of(context).textSecondary,
                            fontSize: DT.s3)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.person_remove_outlined,
                    color: DT.cardRed),
                tooltip: 'Eltávolítás',
                onPressed: () => _showDeleteDialog(context, athlete),
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
        title: const Text('Sportoló eltávolítása'),
        content: Text(
            'Biztosan eltávolítod ${athlete.fullName} sportolót a csapatodból? Újra csatlakozhat, ha kérést küld.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Mégse')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<RosterBloc>().add(DeleteAthlete(athlete.id));
            },
            child: const Text('Eltávolítás',
                style: TextStyle(color: DT.cardRed)),
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
          Icon(Icons.people_outline,
              size: 64, color: DT.of(context).iconLightGrey),
          const SizedBox(height: DT.s4),
          Text('Még nincs sportoló a csapatodban.',
              style:
                  TextStyle(color: DT.of(context).textSecondary, fontSize: DT.s4)),
          const SizedBox(height: DT.s4),
          Text(
            'A sportolók csatlakozási kéréssel tudnak csatlakozni.',
            style: TextStyle(
                color: DT.of(context).textSecondary,
                fontSize: DT.s3),
            textAlign: TextAlign.center,
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
              style: TextStyle(
                  color: DT.of(context).textSecondary, fontSize: DT.s4)),
          const SizedBox(height: DT.s4),
          ElevatedButton(
              onPressed: onRetry, child: const Text('Újra')),
        ],
      ),
    );
  }
}
