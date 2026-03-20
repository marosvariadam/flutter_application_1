import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/coach/data/models/athlete_model.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:flutter_application_1/services/athlete_service.dart';
import 'package:flutter_application_1/services/workout_service.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AthleteDetailPage extends StatefulWidget {
  final String athleteId;
  const AthleteDetailPage({super.key, required this.athleteId});
  @override
  State<AthleteDetailPage> createState() => _AthleteDetailPageState();
}

class _AthleteDetailPageState extends State<AthleteDetailPage> {
  AthleteModel? _athlete;
  List<WorkoutModel> _workouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      AthleteService().getAthleteById(widget.athleteId),
      WorkoutService().getWorkoutsForAthlete(widget.athleteId),
    ]);
    if (!mounted) return;
    setState(() {
      _athlete = results[0] as AthleteModel?;
      _workouts = results[1] as List<WorkoutModel>;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: DT.of(context).bg, elevation: 0, leading: IconButton(icon: Icon(Icons.arrow_back, color: DT.of(context).textPrimary), onPressed: () => Navigator.of(context).pop())),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_athlete == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: DT.of(context).bg, elevation: 0, leading: IconButton(icon: Icon(Icons.arrow_back, color: DT.of(context).textPrimary), onPressed: () => Navigator.of(context).pop())),
        body: const Center(child: _EmptyState('Atléta nem található.')),
      );
    }

    final athlete = _athlete!;
    return Scaffold(
      backgroundColor: DT.of(context).bg,
      appBar: AppBar(
        backgroundColor: DT.of(context).bg,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: DT.of(context).textPrimary), onPressed: () => Navigator.of(context).pop()),
        title: Text(athlete.fullName, style: TextStyle(color: DT.of(context).textPrimary, fontSize: DT.s4, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(Icons.more_vert, color: DT.of(context).textPrimary), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DT.s5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AthleteHeader(athlete: athlete),
            const SizedBox(height: DT.s5),
            _StatsRow(athlete: athlete),
            const SizedBox(height: DT.s5),
            Text('Ütemezett edzések', style: TextStyle(fontSize: DT.s4, fontWeight: FontWeight.w700, color: DT.of(context).textPrimary)),
            const SizedBox(height: DT.s3),
            if (_workouts.isEmpty)
              const _EmptyState()
            else
              ..._workouts.map((w) => _WorkoutRow(workout: w)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/workout-builder', extra: widget.athleteId),
        backgroundColor: DT.gbBlack,
        foregroundColor: DT.gbWhite,
        icon: const Icon(Icons.add),
        label: const Text('Edzés hozzáadása'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState([this.message = 'Nem található adat']);
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DT.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 56, color: DT.of(context).borderGrey),
            const SizedBox(height: DT.s3),
            Text(message, style: TextStyle(color: DT.of(context).textSecondary, fontSize: DT.s4)),
          ],
        ),
      ),
    );
  }
}

class _AthleteHeader extends StatelessWidget {
  final AthleteModel athlete;
  const _AthleteHeader({required this.athlete});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(shape: BoxShape.circle, color: DT.metricBlue.withOpacity(0.12)),
          child: Center(child: Text(athlete.initials, style: const TextStyle(fontSize: DT.s8, fontWeight: FontWeight.w700, color: DT.metricBlue))),
        ),
        const SizedBox(width: DT.s4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(athlete.fullName, style: TextStyle(fontSize: DT.s5, fontWeight: FontWeight.w700, color: DT.of(context).textPrimary)),
              if (athlete.goal != null) ...[const SizedBox(height: DT.s1), Text('Cél: ${athlete.goal}', style: TextStyle(fontSize: DT.s3, color: DT.of(context).textSecondary))],
              if (athlete.lastWorkoutDate != null) ...[const SizedBox(height: DT.s1), Text('Utolsó edzés: ${athlete.lastWorkoutDate}', style: TextStyle(fontSize: DT.s3, color: DT.of(context).textSecondary))],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final AthleteModel athlete;
  const _StatsRow({required this.athlete});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(color: DT.metricGreen, value: '${athlete.workoutCount}', label: 'Edzés')),
        const SizedBox(width: DT.s3),
        Expanded(child: _StatCard(color: DT.metricOrange, value: '${athlete.streakDays}', label: 'Nap streak 🔥')),
        const SizedBox(width: DT.s3),
        Expanded(child: _StatCard(color: DT.cardBlue.withOpacity(0.4), value: '—', label: 'Edzés / hét')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final Color color;
  final String value;
  final String label;
  const _StatCard({required this.color, required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DT.s3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(DT.rCardSmall)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: DT.s5, fontWeight: FontWeight.w700, color: DT.of(context).textPrimary)),
          Text(label, style: TextStyle(fontSize: 11, color: DT.of(context).textSecondary)),
        ],
      ),
    );
  }
}

class _WorkoutRow extends StatelessWidget {
  final WorkoutModel workout;
  const _WorkoutRow({required this.workout});
  @override
  Widget build(BuildContext context) {
    final isPast = workout.scheduledDate.isBefore(DateTime.now());
    return GestureDetector(
      onTap: () => context.push('/workout-detail', extra: workout),
      child: Container(
        margin: const EdgeInsets.only(bottom: DT.s3),
        padding: const EdgeInsets.all(DT.s4),
        decoration: BoxDecoration(
          color: DT.gbWhite,
          borderRadius: BorderRadius.circular(DT.rCardSmall),
          border: Border(left: BorderSide(color: workout.color, width: 3)),
          boxShadow: [BoxShadow(color: DT.of(context).shadowLight, blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('yyyy.MM.dd').format(workout.scheduledDate), style: TextStyle(fontSize: DT.s3, color: DT.of(context).textSecondary)),
                  const SizedBox(height: DT.s1),
                  Text(workout.title, style: TextStyle(fontSize: DT.s4, fontWeight: FontWeight.w600, color: DT.of(context).textPrimary)),
                  const SizedBox(height: DT.s1),
                  Text('${workout.exercises.length} gyakorlat \u2022 ${workout.estimatedDuration}', style: TextStyle(fontSize: DT.s3, color: DT.of(context).textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: DT.s2, vertical: DT.s1),
                  decoration: BoxDecoration(
                    color: isPast ? DT.difficultyLight.withOpacity(0.15) : DT.metricBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(DT.s1),
                  ),
                  child: Text(isPast ? 'Elvégezve' : 'Tervezett', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isPast ? DT.difficultyLight : DT.metricBlue)),
                ),
                const SizedBox(height: DT.s2),
                Icon(Icons.arrow_forward_ios, size: 12, color: DT.of(context).textGrey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
