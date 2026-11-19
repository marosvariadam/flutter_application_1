import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/shared/widgets/error_state.dart';
import 'package:flutter_application_1/app/shared/widgets/section_header.dart';
import 'package:flutter_application_1/app/user_session.dart';
import 'package:flutter_application_1/features/coach/presentation/coach_home_page.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/current_block_pill.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/home_entry_card.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/home_header.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/home_skeleton.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/today_workout_card.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/weekly_strip.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:flutter_application_1/features/workout/data/repositories/workout_repository.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return UserSession.instance.isCoach ? const CoachHomePage() : const AthleteHomePage();
  }
}

class AthleteHomePage extends StatefulWidget {
  const AthleteHomePage({super.key});
  @override
  State<AthleteHomePage> createState() => _AthleteHomePageState();
}

class _AthleteHomePageState extends State<AthleteHomePage> {
  DateTime _selected = DateTime.now();
  List<WorkoutModel> _workouts = [];
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  /// Loads this week's workouts (the strip only shows this week). A retry
  /// after an error shows the skeleton again; a pull-to-refresh keeps the
  /// current content until the new data arrives.
  Future<void> _loadWorkouts() async {
    final repo = context.read<WorkoutRepository>();
    if (_error != null) {
      setState(() {
        _error = null;
        _isLoading = true;
      });
    }
    final from = WeeklyStrip.weekStart(DateTime.now());
    final to = DateTime(from.year, from.month, from.day + 7);
    try {
      final workouts = await repo.getAthleteCalendar(from, to);
      if (!mounted) return;
      setState(() {
        _workouts = workouts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  WorkoutModel? get _workout {
    final key = WeeklyStrip.dayKey(_selected);
    for (final w in _workouts) {
      if (WeeklyStrip.dayKey(w.scheduledDate) == key) return w;
    }
    return null;
  }

  Set<String> get _workoutDateKeys =>
      _workouts.map((w) => WeeklyStrip.dayKey(w.scheduledDate)).toSet();

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        toolbarHeight: 80,
        title: const HomeHeader(),
      ),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (_isLoading) return const HomeSkeleton();
    final error = _error;
    if (error != null) {
      return ErrorState(
        error: error,
        title: 'Nem sikerült betölteni az edzéseidet',
        onRetry: _loadWorkouts,
      );
    }
    final c = DT.of(context);
    final workout = _workout;
    return RefreshIndicator(
      onRefresh: _loadWorkouts,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(DT.s5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CurrentBlockPill(),
            const SectionHeader(title: 'Ezen a héten'),
            WeeklyStrip(
              selected: _selected,
              workoutDateKeys: _workoutDateKeys,
              onDateSelected: (date) => setState(() => _selected = date),
            ),
            const SizedBox(height: DT.s5),
            const SectionHeader(title: 'Edzéstervem'),
            workout != null
                ? TodayWorkoutCard(
                    workout: workout,
                    onTap: () => context.push('/workout-detail', extra: workout),
                  )
                : const RestDayCard(),
            const SizedBox(height: DT.s5),
            const SectionHeader(title: 'Fejlődésem'),
            HomeEntryCard(
              icon: Icons.show_chart,
              color: c.accentPrimary,
              title: 'Gyakorlat statisztikák',
              subtitle: 'Kövesd a súly- és ismétlés fejlődésed',
              onTap: () => context.push('/exercise-stats'),
            ),
            const SizedBox(height: DT.s3),
            HomeEntryCard(
              icon: Icons.timeline,
              color: c.accentTeal,
              title: 'Fejlődés előrejelzés',
              subtitle: 'Becsült 1RM trendje gyakorlatonként',
              onTap: () => context.push('/prediction'),
            ),
          ],
        ),
      ),
    );
  }
}
