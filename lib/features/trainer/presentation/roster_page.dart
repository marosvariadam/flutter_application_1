import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/trainer/bloc/roster_bloc.dart';
import 'package:flutter_application_1/features/trainer/data/models/trainer_request_model.dart';
import 'package:flutter_application_1/features/trainer/data/repositories/roster_repository.dart';
import 'package:flutter_application_1/app/design/dt_text.dart';
import 'package:flutter_application_1/app/shared/reload_and_wait.dart';
import 'package:flutter_application_1/app/shared/widgets/empty_state.dart';
import 'package:flutter_application_1/app/shared/widgets/error_state.dart';
import 'package:flutter_application_1/app/shared/widgets/fade_switcher.dart';
import 'package:flutter_application_1/app/shared/widgets/refreshable_fill.dart';
import 'package:flutter_application_1/app/shared/widgets/skeleton.dart';
import 'package:flutter_application_1/app/shared/widgets/user_avatar.dart';

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
        title: Text('Sportolók', style: DTText.of(context).title),
        centerTitle: true,
      ),
      body: BlocBuilder<RosterBloc, RosterState>(
        builder: (context, state) =>
            FadeSwitcher(child: _body(context, state)),
      ),
    );
  }

  Widget _body(BuildContext context, RosterState state) {
    final bloc = context.read<RosterBloc>();
    Future<void> refresh() => reloadAndWait(
        bloc, () => bloc.add(LoadRoster()), (s) => s is! RosterLoading);

    if (state is RosterError) {
      return ErrorState(
        key: const ValueKey('error'),
        message: state.message,
        title: 'Nem sikerült betölteni a sportolókat',
        onRetry: () => bloc.add(LoadRoster()),
      );
    }
    if (state is! RosterLoaded) {
      return const SkeletonList(
          key: ValueKey('loading'), padding: EdgeInsets.all(DT.s5));
    }
    if (state.athletes.isEmpty) {
      return RefreshIndicator(
        key: const ValueKey('empty'),
        onRefresh: refresh,
        child: const RefreshableFill(
          child: EmptyState(
            icon: Icons.people_outline,
            title: 'Még nincs sportoló a csapatodban',
            message: 'A sportolók csatlakozási kéréssel tudnak csatlakozni.',
          ),
        ),
      );
    }
    return RefreshIndicator(
      key: const ValueKey('content'),
      onRefresh: refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is ScrollEndNotification &&
              n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
            bloc.add(LoadMoreRoster());
          }
          return false;
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(DT.s5),
          itemCount: state.athletes.length + (state.hasMore ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: DT.s3),
          itemBuilder: (context, i) {
            if (i == state.athletes.length) {
              return const SkeletonList(itemCount: 1);
            }
            return _AthleteCard(athlete: state.athletes[i]);
          },
        ),
      ),
    );
  }
}

class _AthleteCard extends StatelessWidget {
  final AthleteModel athlete;
  const _AthleteCard({required this.athlete});

  @override
  Widget build(BuildContext context) {
    final t = DTText.of(context);
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
              UserAvatar(name: athlete.fullName, size: 48),
              const SizedBox(width: DT.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(athlete.fullName,
                        style: t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(athlete.email,
                        style: t.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.person_remove_outlined,
                    color: DT.of(context).accentDanger),
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
            child: Text('Eltávolítás',
                style: TextStyle(color: DT.of(context).accentDanger)),
          ),
        ],
      ),
    );
  }

}
