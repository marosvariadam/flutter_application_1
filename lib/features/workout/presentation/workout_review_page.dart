import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:flutter_application_1/features/workout/data/repositories/workout_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Trainer sees completed workouts for a specific athlete.
class WorkoutReviewPage extends StatefulWidget {
  final String? athleteId;
  const WorkoutReviewPage({super.key, this.athleteId});

  @override
  State<WorkoutReviewPage> createState() => _WorkoutReviewPageState();
}

class _WorkoutReviewPageState extends State<WorkoutReviewPage> {
  List<WorkoutModel> _workouts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final workouts = await context
          .read<WorkoutRepository>()
          .getTrainerReview(widget.athleteId ?? '');
      setState(() => _workouts = workouts);
    } catch (_) {
      setState(() => _error = 'Nem sikerült betölteni az adatokat.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.bg,
      appBar: AppBar(
        backgroundColor: DT.bg,
        elevation: 0,
        leading: BackButton(color: DT.textPrimary),
        title: const Text('Befejezett edzések',
            style: TextStyle(
                color: DT.textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: DT.cardRed),
                      const SizedBox(height: DT.s4),
                      Text(_error!,
                          style: const TextStyle(
                              color: DT.textSecondary)),
                      const SizedBox(height: DT.s4),
                      ElevatedButton(
                          onPressed: _load, child: const Text('Újra')),
                    ],
                  ),
                )
              : _workouts.isEmpty
                  ? const Center(
                      child: Text('Még nincs befejezett edzés.',
                          style: TextStyle(
                              color: DT.textSecondary,
                              fontSize: DT.s4)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(DT.s5),
                      itemCount: _workouts.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: DT.s3),
                      itemBuilder: (context, i) {
                        final w = _workouts[i];
                        return _ReviewCard(workout: w);
                      },
                    ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final WorkoutModel workout;
  const _ReviewCard({required this.workout});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DT.gbWhite,
      borderRadius: BorderRadius.circular(DT.rCardSmall),
      child: InkWell(
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        onTap: () => context.push('/workout/${workout.id}'),
        child: Padding(
          padding: const EdgeInsets.all(DT.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(workout.title,
                        style: const TextStyle(
                            color: DT.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: DT.s4)),
                  ),
                  Text(
                    DateFormat('yyyy.MM.dd')
                        .format(workout.scheduledDate),
                    style: const TextStyle(
                        color: DT.textSecondary, fontSize: DT.s3),
                  ),
                ],
              ),
              if (workout.athleteFeedback != null &&
                  workout.athleteFeedback!.isNotEmpty) ...[
                const SizedBox(height: DT.s3),
                Container(
                  padding: const EdgeInsets.all(DT.s3),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(DT.rCardSmall),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.format_quote,
                          color: Colors.green, size: 16),
                      const SizedBox(width: DT.s2),
                      Expanded(
                        child: Text(workout.athleteFeedback!,
                            style: const TextStyle(
                                color: DT.textPrimary,
                                fontSize: DT.s3)),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: DT.s2),
                const Text('Nincs visszajelzés',
                    style: TextStyle(
                        color: DT.textSecondary, fontSize: DT.s3)),
              ],
              const SizedBox(height: DT.s2),
              Text(
                '${workout.exercises.length} gyakorlat',
                style: const TextStyle(
                    color: DT.textSecondary, fontSize: DT.s3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
