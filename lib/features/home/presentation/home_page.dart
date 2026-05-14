import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/user_session.dart';
import 'package:flutter_application_1/features/coach/presentation/coach_home_page.dart';
import 'package:flutter_application_1/features/training_block/data/models/training_block_model.dart';
import 'package:flutter_application_1/features/training_block/data/repositories/training_block_repository.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:flutter_application_1/services/workout_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    final userId = UserSession.instance.userId ?? '';
    final workouts = await WorkoutService().getWorkoutsForAthlete(userId);
    if (mounted) setState(() { _workouts = workouts; _isLoading = false; });
  }

  WorkoutModel? get _workout {
    try {
      return _workouts.firstWhere(
        (w) => w.scheduledDate.year == _selected.year &&
               w.scheduledDate.month == _selected.month &&
               w.scheduledDate.day == _selected.day,
      );
    } catch (_) { return null; }
  }

  Set<String> get _workoutDateKeys => _workouts
      .map((w) => '${w.scheduledDate.year}-${w.scheduledDate.month}-${w.scheduledDate.day}')
      .toSet();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.of(context).bg,
      appBar: AppBar(
        backgroundColor: DT.of(context).bg,
        elevation: 0,
        toolbarHeight: 80,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => context.go('/profile'),
              child: Container(
                margin: const EdgeInsets.only(right: DT.s3),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: DT.of(context).bg, width: 2),
                  boxShadow: const [BoxShadow(color: DT.shadowMedium, blurRadius: 10, offset: Offset(0, 2))],
                ),
                child: ClipOval(
                  child: Container(
                    color: DT.metricBlue.withOpacity(0.15),
                    child: const Icon(Icons.person, color: DT.metricBlue),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Szia, ${UserSession.instance.firstName ?? ''}!',
                    style: TextStyle(fontSize: DT.s4, fontWeight: FontWeight.w600, color: DT.of(context).textPrimary),
                  ),
                  Text(
                    DateFormat('yyyy.MM.dd').format(DateTime.now()),
                    style: TextStyle(fontSize: DT.s3, color: DT.of(context).textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: DT.gbWhite,
                borderRadius: BorderRadius.circular(DT.rCardSmall),
                boxShadow: [BoxShadow(color: DT.of(context).shadowLight, blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Icon(Icons.search, color: DT.of(context).iconLight),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWorkouts,
              child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(DT.s5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CurrentBlockPill(),
                  _DailyChallengeCard(),
                  const SizedBox(height: DT.s5),
                  Text('Ezen a héten', style: TextStyle(fontSize: DT.s4, fontWeight: FontWeight.w700, color: DT.of(context).textPrimary)),
                  const SizedBox(height: DT.s3),
                  _WeeklyStrip(
                    selected: _selected,
                    workoutDateKeys: _workoutDateKeys,
                    onDateSelected: (date) => setState(() => _selected = date),
                  ),
                  const SizedBox(height: DT.s5),
                  Text('Edzéstervem', style: TextStyle(fontSize: DT.s4, fontWeight: FontWeight.w700, color: DT.of(context).textPrimary)),
                  const SizedBox(height: DT.s3),
                  _workout != null
                      ? _WorkoutCard(workout: _workout!, onTap: () => context.push('/workout-detail', extra: _workout))
                      : const _RestDayCard(),
                  const SizedBox(height: DT.s5),
                  _StatsEntryCard(),
                  const SizedBox(height: DT.s3),
                  _PredictionEntryCard(),
                  const SizedBox(height: DT.s5),
                  _SocialCard(),
                ],
              ),
            ),
          ),
    );
  }
}

class _WeeklyStrip extends StatelessWidget {
  final DateTime selected;
  final Set<String> workoutDateKeys;
  final ValueChanged<DateTime> onDateSelected;
  const _WeeklyStrip({required this.selected, required this.workoutDateKeys, required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return SizedBox(
      height: 76,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = monday.add(Duration(days: index));
          final isSelected = date.day == selected.day && date.month == selected.month && date.year == selected.year;
          final key = '${date.year}-${date.month}-${date.day}';
          final hasWorkout = workoutDateKeys.contains(key);
          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              margin: const EdgeInsets.only(right: DT.s3),
              decoration: BoxDecoration(
                color: isSelected ? DT.gbBlack : DT.gbWhite,
                borderRadius: BorderRadius.circular(DT.rCardSmall),
                boxShadow: [BoxShadow(color: DT.of(context).shadowLight, blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('E').format(date), style: TextStyle(fontSize: DT.s3, color: isSelected ? DT.gbWhite : DT.of(context).textSecondary, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(DateFormat('d').format(date), style: TextStyle(fontSize: DT.s4, color: isSelected ? DT.gbWhite : DT.of(context).textPrimary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasWorkout ? (isSelected ? DT.gbWhite : DT.metricBlue) : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final WorkoutModel workout;
  final VoidCallback onTap;
  const _WorkoutCard({required this.workout, required this.onTap});

  static Color _diffColor(WorkoutDifficulty d) {
    switch (d) {
      case WorkoutDifficulty.easy: return DT.difficultyLight;
      case WorkoutDifficulty.hard:
      case WorkoutDifficulty.intense: return DT.difficultyHard;
      default: return DT.difficultyMedium;
    }
  }

  @override
  Widget build(BuildContext context) {
    final diffColor = _diffColor(workout.difficulty);
    return Material(
      color: workout.color.withOpacity(0.25),
      borderRadius: BorderRadius.circular(DT.rCardSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        child: Container(
          padding: const EdgeInsets.all(DT.s5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DT.rCardSmall),
            border: Border(left: BorderSide(color: workout.color, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: DT.s2, vertical: DT.s1),
                    decoration: BoxDecoration(color: diffColor, borderRadius: BorderRadius.circular(DT.s1)),
                    child: Text(workout.difficulty.label, style: const TextStyle(color: Colors.white, fontSize: DT.s3, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 14, color: DT.of(context).textSecondary),
                ],
              ),
              const SizedBox(height: DT.s3),
              Text(workout.title, style: TextStyle(fontSize: DT.s5, fontWeight: FontWeight.w700, color: DT.of(context).textPrimary)),
              if (workout.description != null) ...[
                const SizedBox(height: DT.s1),
                Text(workout.description!, style: TextStyle(fontSize: DT.s3, color: DT.of(context).textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: DT.s4),
              Wrap(
                spacing: DT.s4,
                children: [
                  _InfoChip(icon: Icons.fitness_center_outlined, label: '${workout.exercises.length} gyakorlat'),
                  _InfoChip(icon: Icons.repeat, label: '${workout.totalSets} sorozat'),
                  _InfoChip(icon: Icons.access_time, label: workout.estimatedDuration),
                  _InfoChip(icon: Icons.local_fire_department, label: workout.kcal),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: DT.of(context).iconLight),
        const SizedBox(width: DT.s1),
        Text(label, style: TextStyle(color: DT.of(context).textSecondary, fontSize: DT.s3)),
      ],
    );
  }
}

class _RestDayCard extends StatelessWidget {
  const _RestDayCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DT.s5),
      decoration: BoxDecoration(
        color: DT.gbWhite,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        boxShadow: [BoxShadow(color: DT.of(context).shadowLight, blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(Icons.self_improvement, size: 48, color: DT.of(context).iconLightGrey),
          const SizedBox(height: DT.s3),
          Text('Pihenőnap', style: TextStyle(fontSize: DT.s4, fontWeight: FontWeight.w600, color: DT.of(context).textPrimary)),
          const SizedBox(height: DT.s1),
          Text('Erre a napra nincs ütemezett edzés.', style: TextStyle(fontSize: DT.s3, color: DT.of(context).textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DT.s5),
      decoration: BoxDecoration(
        color: DT.gbWhite,
        borderRadius: BorderRadius.circular(DT.rCard),
        boxShadow: [BoxShadow(color: DT.of(context).shadowLight, blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Napi kihívás', style: TextStyle(fontSize: DT.s5, fontWeight: FontWeight.w700, color: DT.of(context).textPrimary)),
          const SizedBox(height: DT.s2),
          Text('Csináld meg az edzést 9:00 előtt', style: TextStyle(fontSize: DT.s4, color: DT.of(context).textSecondary)),
          const SizedBox(height: DT.s3),
          Row(
            children: [
              _UserChip(),
              Transform.translate(offset: const Offset(-DT.s2, 0), child: _UserChip()),
              Transform.translate(offset: const Offset(-DT.s4, 0), child: _UserChip()),
              Transform.translate(
                offset: const Offset(-DT.s6, 0),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: DT.of(context).bg, border: Border.all(color: DT.gbWhite, width: 2)),
                  child: Center(child: Text('+12', style: TextStyle(fontSize: 9, color: DT.of(context).textSecondary, fontWeight: FontWeight.w600))),
                ),
              ),
            ],
          ),
          const SizedBox(height: DT.s4),
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(DT.rCardSmall),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: DT.s4, vertical: DT.s2),
              decoration: BoxDecoration(color: DT.gbBlack, borderRadius: BorderRadius.circular(DT.rCardSmall)),
              child: const Text('Csatlakozz →', style: TextStyle(color: DT.gbWhite, fontSize: DT.s3, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: DT.metricBlue.withOpacity(0.15),
        border: Border.all(color: DT.gbWhite, width: 2),
      ),
      child: const Icon(Icons.person, size: 18, color: DT.metricBlue),
    );
  }
}

class _StatsEntryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fejlődésem',
            style: TextStyle(
                fontSize: DT.s4,
                fontWeight: FontWeight.w700,
                color: DT.of(context).textPrimary)),
        const SizedBox(height: DT.s3),
        GestureDetector(
          onTap: () => context.push('/exercise-stats'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DT.s5),
            decoration: BoxDecoration(
              color: DT.metricBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(DT.rCardSmall),
              border: Border(
                  left: BorderSide(color: DT.metricBlue, width: 4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: DT.metricBlue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.show_chart,
                      color: DT.metricBlue),
                ),
                const SizedBox(width: DT.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gyakorlat statisztikák',
                          style: TextStyle(
                              fontSize: DT.s4,
                              fontWeight: FontWeight.w600,
                              color: DT.of(context).textPrimary)),
                      const SizedBox(height: DT.s1),
                      Text('Kövesd a súly- és ismétlés fejlődésed',
                          style: TextStyle(
                              fontSize: DT.s3,
                              color: DT.of(context).textSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 14, color: DT.of(context).textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Közösség', style: TextStyle(fontSize: DT.s4, fontWeight: FontWeight.w700, color: DT.of(context).textPrimary)),
        const SizedBox(height: DT.s3),
        Container(
          padding: const EdgeInsets.symmetric(vertical: DT.s4, horizontal: DT.s5),
          decoration: BoxDecoration(
            color: DT.gbWhite,
            borderRadius: BorderRadius.circular(DT.rCard),
            boxShadow: [BoxShadow(color: DT.of(context).shadowLight, blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SocialItem(icon: Icons.camera_alt, color: DT.socialPink, label: 'Kamera', onTap: () {}),
              _SocialItem(icon: Icons.play_circle_outline, color: DT.socialRed, label: 'Videó', onTap: () {}),
              _SocialItem(icon: Icons.chat_bubble_outline, color: DT.socialBlue, label: 'Üzenet', onTap: () => context.go('/messages')),
            ],
          ),
        ),
      ],
    );
  }
}

class _PredictionEntryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/prediction'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DT.s5),
        decoration: BoxDecoration(
          color: DT.cardTeal.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(DT.rCardSmall),
          border: Border(left: BorderSide(color: DT.cardTeal, width: 4)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: DT.cardTeal.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.timeline, color: DT.cardTeal),
            ),
            const SizedBox(width: DT.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fejlődés előrejelzés',
                      style: TextStyle(
                          fontSize: DT.s4,
                          fontWeight: FontWeight.w600,
                          color: DT.of(context).textPrimary)),
                  const SizedBox(height: DT.s1),
                  Text('Becsült 1RM trendje gyakorlatonként',
                      style: TextStyle(
                          fontSize: DT.s3,
                          color: DT.of(context).textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: DT.of(context).textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Read-only pill shown on the athlete dashboard when a training block covers
/// today. Renders nothing while loading, when there is no active block, or on
/// any error.
class _CurrentBlockPill extends StatefulWidget {
  @override
  State<_CurrentBlockPill> createState() => _CurrentBlockPillState();
}

class _CurrentBlockPillState extends State<_CurrentBlockPill> {
  TrainingBlockModel? _current;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = UserSession.instance.userId;
    if (userId == null) return;
    try {
      final repo = context.read<TrainingBlockRepository>();
      final blocks = await repo.getForAthlete(userId);
      final today = DateTime.now();
      final dayOnly = DateTime(today.year, today.month, today.day);
      TrainingBlockModel? hit;
      for (final b in blocks) {
        final s = DateTime(b.startDate.year, b.startDate.month, b.startDate.day);
        final e = DateTime(b.endDate.year, b.endDate.month, b.endDate.day);
        if (!dayOnly.isBefore(s) && !dayOnly.isAfter(e)) {
          hit = b;
          break;
        }
      }
      if (mounted) setState(() { _current = hit; _loaded = true; });
    } catch (_) {
      if (mounted) setState(() { _loaded = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _current == null) return const SizedBox.shrink();
    final b = _current!;
    final remaining = b.endDate
        .difference(DateTime.now())
        .inDays
        .clamp(0, 9999);
    return Container(
      margin: const EdgeInsets.only(bottom: DT.s4),
      padding:
          const EdgeInsets.symmetric(horizontal: DT.s4, vertical: DT.s2),
      decoration: BoxDecoration(
        color: DT.metricBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DT.rChip),
        border: Border.all(color: DT.metricBlue.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, size: 16, color: DT.metricBlue),
          const SizedBox(width: DT.s2),
          Expanded(
            child: Text(
              'Aktuális blokk: ${b.focus} · még $remaining nap',
              style: const TextStyle(
                color: DT.metricBlue,
                fontWeight: FontWeight.w600,
                fontSize: DT.s3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;
  const _SocialItem({required this.icon, required this.color, required this.label, this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DT.rCard),
      child: Padding(
        padding: const EdgeInsets.all(DT.s2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: DT.s5),
            ),
            const SizedBox(height: DT.s1),
            Text(label, style: TextStyle(fontSize: DT.s3, color: DT.of(context).textSecondary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
