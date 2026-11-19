import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/trainer/bloc/roster_bloc.dart';
import 'package:flutter_application_1/features/trainer/data/models/trainer_request_model.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/app/design/dt_text.dart';
import 'package:flutter_application_1/app/shared/reload_and_wait.dart';
import 'package:flutter_application_1/app/shared/widgets/empty_state.dart';
import 'package:flutter_application_1/app/shared/widgets/error_state.dart';
import 'package:flutter_application_1/app/shared/widgets/fade_switcher.dart';
import 'package:flutter_application_1/app/shared/widgets/refreshable_fill.dart';
import 'package:flutter_application_1/app/shared/widgets/skeleton.dart';
import 'package:flutter_application_1/app/shared/widgets/user_avatar.dart';

class AthletesPage extends StatefulWidget {
  const AthletesPage({super.key});
  @override
  State<AthletesPage> createState() => _AthletesPageState();
}

class _AthletesPageState extends State<AthletesPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RosterBloc>().add(LoadRoster());
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.of(context).bg,
      appBar: AppBar(
        backgroundColor: DT.of(context).bg,
        elevation: 0,
        title: Text('Atlétáim', style: DTText.of(context).title),
        centerTitle: true,
      ),
      body: BlocBuilder<RosterBloc, RosterState>(
        builder: (context, state) => FadeSwitcher(child: _body(context, state)),
      ),
    );
  }

  Future<void> _refresh() {
    final bloc = context.read<RosterBloc>();
    return reloadAndWait(bloc, () => bloc.add(LoadRoster()),
        (s) => s is! RosterLoading);
  }

  Widget _body(BuildContext context, RosterState state) {
    if (state is RosterInitial || state is RosterLoading) {
      return const SkeletonList(
          key: ValueKey('loading'), padding: EdgeInsets.all(DT.s5));
    }
    if (state is RosterError) {
      return ErrorState(
        key: const ValueKey('error'),
        message: state.message,
        title: 'Nem sikerült betölteni az atlétákat',
        onRetry: () => context.read<RosterBloc>().add(LoadRoster()),
      );
    }

    final athletes = state is RosterLoaded ? state.athletes : <AthleteModel>[];
    final filtered = _query.isEmpty
        ? athletes
        : athletes
            .where((a) =>
                a.fullName.toLowerCase().contains(_query.toLowerCase()))
            .toList();
    final c = DT.of(context);

    return Column(
      key: const ValueKey('content'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(DT.s5, 0, DT.s5, DT.s3),
          child: Container(
            decoration: BoxDecoration(
              color: c.cardSurface,
              borderRadius: BorderRadius.circular(DT.rCardSmall),
              boxShadow: DT.shadowCard(context),
            ),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Atléta keresése…',
                prefixIcon: Icon(Icons.search, color: c.iconLight),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: DT.s4),
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: filtered.isEmpty
                ? RefreshableFill(
                    child: athletes.isEmpty
                        ? const EmptyState(
                            icon: Icons.people_outline,
                            title: 'Még nincs atlétád',
                            message:
                                'Az elfogadott jelentkezők itt jelennek meg.',
                          )
                        : const EmptyState(
                            icon: Icons.search_off,
                            title: 'Nincs találat',
                            message: 'Próbálj másik nevet.',
                          ),
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.fromLTRB(DT.s5, 0, DT.s5, DT.s8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: DT.s3),
                    itemBuilder: (context, index) => _AthleteCard(
                      athlete: filtered[index],
                      onTap: () => context
                          .push('/athlete-detail/${filtered[index].id}'),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _AthleteCard extends StatelessWidget {
  final AthleteModel athlete;
  final VoidCallback onTap;
  const _AthleteCard({required this.athlete, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    final t = DTText.of(context);
    return Material(
      color: c.cardSurface,
      borderRadius: BorderRadius.circular(DT.rCardSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        child: Padding(
          padding: const EdgeInsets.all(DT.s4),
          child: Row(
            children: [
              UserAvatar(name: athlete.fullName, size: 52),
              const SizedBox(width: DT.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      athlete.fullName,
                      style: t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: DT.s1),
                    Text(
                      athlete.email,
                      style: t.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: c.textSecondary, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
