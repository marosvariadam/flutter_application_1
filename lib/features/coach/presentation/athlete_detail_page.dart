import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/trainer/bloc/roster_bloc.dart';
import 'package:flutter_application_1/features/trainer/data/models/trainer_request_model.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:flutter_application_1/features/workout/data/repositories/workout_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AthleteDetailPage extends StatefulWidget {
  final String athleteId;
  const AthleteDetailPage({super.key, required this.athleteId});

  @override
  State<AthleteDetailPage> createState() => _AthleteDetailPageState();
}

class _AthleteDetailPageState extends State<AthleteDetailPage> {
  List<WorkoutModel> _workouts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final workouts = await context
          .read<WorkoutRepository>()
          .getTrainerReview(widget.athleteId);
      if (mounted) {
        setState(() {
          _workouts = workouts;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Nem sikerült betölteni az adatokat.';
          _isLoading = false;
        });
      }
    }
  }

  AthleteModel? _findAthlete() {
    final state = context.read<RosterBloc>().state;
    if (state is RosterLoaded) {
      try {
        return state.athletes.firstWhere((a) => a.id == widget.athleteId);
      } catch (_) {}
    }
    return null;
  }

  int _computeStreak(List<WorkoutModel> completed) {
    if (completed.isEmpty) return 0;
    final days = completed
        .map((w) {
          final d = w.scheduledDate;
          return DateTime(d.year, d.month, d.day);
        })
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    final today = DateTime.now();
    var check = DateTime(today.year, today.month, today.day);
    for (final day in days) {
      if (day.isAtSameMomentAs(check) ||
          day.isAtSameMomentAs(check.subtract(const Duration(days: 1)))) {
        streak++;
        check = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  AppBar _buildAppBar(String title) => AppBar(
        backgroundColor: DT.of(context).bg,
        elevation: 0,
        leading: BackButton(color: DT.of(context).textPrimary),
        title: Text(
          title,
          style: TextStyle(
            color: DT.of(context).textPrimary,
            fontSize: DT.s4,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      );

  @override
  Widget build(BuildContext context) {
    final athlete = _findAthlete();
    final name = athlete?.fullName ?? 'Atléta';

    if (_isLoading) {
      return Scaffold(
        backgroundColor: DT.of(context).bg,
        appBar: _buildAppBar(name),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: DT.of(context).bg,
        appBar: _buildAppBar(name),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: DT.cardRed),
              const SizedBox(height: DT.s3),
              Text(_error!,
                  style: TextStyle(color: DT.of(context).textSecondary)),
              const SizedBox(height: DT.s4),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _load();
                },
                child: const Text('Újra'),
              ),
            ],
          ),
        ),
      );
    }

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final completed =
        _workouts.where((w) => w.status == WorkoutStatus.completed).toList();
    final thisWeek = _workouts.where((w) {
      final d = w.scheduledDate;
      return !d.isBefore(DateTime(weekStart.year, weekStart.month, weekStart.day)) &&
          d.isBefore(weekStart.add(const Duration(days: 7)));
    }).length;
    final streak = _computeStreak(completed);

    final sortedWorkouts = List<WorkoutModel>.from(_workouts)
      ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

    return Scaffold(
      backgroundColor: DT.of(context).bg,
      appBar: _buildAppBar(name),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DT.s5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderCard(athlete: athlete),
            const SizedBox(height: DT.s4),
            _StatsRow(
              total: _workouts.length,
              completed: completed.length,
              thisWeek: thisWeek,
              streak: streak,
            ),
            const SizedBox(height: DT.s5),
            Text(
              'Aktivitás (elmúlt 8 hét)',
              style: TextStyle(
                fontSize: DT.s4,
                fontWeight: FontWeight.w700,
                color: DT.of(context).textPrimary,
              ),
            ),
            const SizedBox(height: DT.s3),
            _ActivityHeatmap(workouts: _workouts),
            const SizedBox(height: DT.s5),
            Text(
              'Edzések',
              style: TextStyle(
                fontSize: DT.s4,
                fontWeight: FontWeight.w700,
                color: DT.of(context).textPrimary,
              ),
            ),
            const SizedBox(height: DT.s3),
            if (_workouts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: DT.s8),
                child: Center(
                  child: Text(
                    'Nincs rögzített edzés',
                    style:
                        TextStyle(color: DT.of(context).textSecondary),
                  ),
                ),
              )
            else
              ...sortedWorkouts.map((w) => _WorkoutRow(workout: w)),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push('/workout-builder', extra: widget.athleteId),
        backgroundColor: DT.gbBlack,
        foregroundColor: DT.gbWhite,
        icon: const Icon(Icons.add),
        label: const Text('Edzés hozzáadása'),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final AthleteModel? athlete;
  const _HeaderCard({required this.athlete});

  @override
  Widget build(BuildContext context) {
    final name = athlete?.fullName ?? '—';
    final email = athlete?.email ?? '';
    final initials = athlete != null
        ? '${athlete!.firstName.isNotEmpty ? athlete!.firstName[0] : ''}${athlete!.lastName.isNotEmpty ? athlete!.lastName[0] : ''}'
            .toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(DT.s5),
      decoration: BoxDecoration(
        color: DT.gbWhite,
        borderRadius: BorderRadius.circular(DT.rCard),
        boxShadow: [
          BoxShadow(
              color: DT.of(context).shadowLight,
              blurRadius: 12,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [DT.metricBlue, Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: DT.s6,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: DT.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: DT.s5,
                    fontWeight: FontWeight.w700,
                    color: DT.of(context).textPrimary,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: DT.s1),
                  Row(
                    children: [
                      Icon(Icons.email_outlined,
                          size: 14, color: DT.of(context).iconLight),
                      const SizedBox(width: DT.s1),
                      Flexible(
                        child: Text(
                          email,
                          style: TextStyle(
                            fontSize: DT.s3,
                            color: DT.of(context).textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats ─────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int total;
  final int completed;
  final int thisWeek;
  final int streak;

  const _StatsRow({
    required this.total,
    required this.completed,
    required this.thisWeek,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _StatCard(
          icon: Icons.fitness_center,
          value: '$total',
          label: 'Összes',
          color: DT.metricBlue,
        )),
        const SizedBox(width: DT.s3),
        Expanded(
            child: _StatCard(
          icon: Icons.check_circle_outline,
          value: '$completed',
          label: 'Teljesített',
          color: Colors.green,
        )),
        const SizedBox(width: DT.s3),
        Expanded(
            child: _StatCard(
          icon: Icons.calendar_today_outlined,
          value: '$thisWeek',
          label: 'Ezen a héten',
          color: DT.cardOrange,
        )),
        const SizedBox(width: DT.s3),
        Expanded(
            child: _StatCard(
          icon: Icons.local_fire_department,
          value: '$streak',
          label: 'Sorozat',
          color: Colors.deepOrange,
        )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: DT.s3, horizontal: DT.s2),
      decoration: BoxDecoration(
        color: DT.gbWhite,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        boxShadow: [
          BoxShadow(
              color: DT.of(context).shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: DT.s1),
          Text(
            value,
            style: TextStyle(
              fontSize: DT.s5,
              fontWeight: FontWeight.w800,
              color: DT.of(context).textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: DT.of(context).textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Activity Heatmap ──────────────────────────────────────────────────────────

class _ActivityHeatmap extends StatelessWidget {
  final List<WorkoutModel> workouts;

  const _ActivityHeatmap({required this.workouts});

  static const _dayLabels = ['H', 'K', 'Sz', 'Cs', 'P', 'Szo', 'V'];
  static const _weeks = 8;

  @override
  Widget build(BuildContext context) {
    // Build a date → status map
    final Map<String, WorkoutStatus> dateMap = {};
    for (final w in workouts) {
      final key = _dateKey(w.scheduledDate);
      // prefer completed over planned if multiple workouts on same day
      if (!dateMap.containsKey(key) ||
          w.status == WorkoutStatus.completed) {
        dateMap[key] = w.status;
      }
    }

    // Start from Monday _weeks weeks ago
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Find the Monday of the current week
    final currentMonday = today.subtract(Duration(days: today.weekday - 1));
    final gridStart =
        currentMonday.subtract(Duration(days: (_weeks - 1) * 7));

    return Container(
      padding: const EdgeInsets.all(DT.s4),
      decoration: BoxDecoration(
        color: DT.gbWhite,
        borderRadius: BorderRadius.circular(DT.rCard),
        boxShadow: [
          BoxShadow(
              color: DT.of(context).shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day-of-week header
          Row(
            children: [
              // left label column spacer
              const SizedBox(width: 34),
              ...List.generate(7, (i) {
                return Expanded(
                  child: Text(
                    _dayLabels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: DT.of(context).textSecondary,
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: DT.s2),
          // Week rows
          ...List.generate(_weeks, (weekIdx) {
            final monday =
                gridStart.add(Duration(days: weekIdx * 7));
            final monthLabel =
                DateFormat('MMM', 'hu').format(monday);

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  // Week label (month abbreviation when week starts a new month)
                  SizedBox(
                    width: 34,
                    child: Text(
                      weekIdx == 0 ||
                              monday.month !=
                                  gridStart
                                      .add(Duration(
                                          days: (weekIdx - 1) * 7))
                                      .month
                          ? monthLabel
                          : '',
                      style: TextStyle(
                        fontSize: 9,
                        color: DT.of(context).textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ...List.generate(7, (dayIdx) {
                    final day = monday.add(Duration(days: dayIdx));
                    final key = _dateKey(day);
                    final status = dateMap[key];
                    final isFuture = day.isAfter(today);
                    final isPast = day.isBefore(today);

                    return Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 2),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _HeatCell(
                            status: status,
                            isFuture: isFuture,
                            isPast: isPast,
                            isToday: day.isAtSameMomentAs(today),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
          const SizedBox(height: DT.s3),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _LegendDot(color: Colors.green.shade500, label: 'Teljesített'),
              const SizedBox(width: DT.s3),
              _LegendDot(color: DT.cardOrange, label: 'Folyamatban'),
              const SizedBox(width: DT.s3),
              _LegendDot(
                  color: DT.metricBlue.withValues(alpha: 0.4),
                  label: 'Tervezett'),
            ],
          ),
        ],
      ),
    );
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _HeatCell extends StatelessWidget {
  final WorkoutStatus? status;
  final bool isFuture;
  final bool isPast;
  final bool isToday;

  const _HeatCell({
    required this.status,
    required this.isFuture,
    required this.isPast,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    Color fill;
    if (status == WorkoutStatus.completed) {
      fill = Colors.green.shade500;
    } else if (status == WorkoutStatus.inProgress) {
      fill = DT.cardOrange;
    } else if (status == WorkoutStatus.planned && isFuture) {
      fill = DT.metricBlue.withValues(alpha: 0.35);
    } else if (status == WorkoutStatus.planned && isPast) {
      // Planned but never started — missed
      fill = DT.cardRed.withValues(alpha: 0.25);
    } else {
      // Rest day
      fill = DT.of(context).bg;
    }

    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(4),
        border: isToday
            ? Border.all(color: DT.metricBlue, width: 1.5)
            : null,
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style:
              TextStyle(fontSize: 10, color: DT.of(context).textSecondary),
        ),
      ],
    );
  }
}

// ── Workout row ───────────────────────────────────────────────────────────────

class _WorkoutRow extends StatelessWidget {
  final WorkoutModel workout;
  const _WorkoutRow({required this.workout});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (workout.status) {
      WorkoutStatus.completed => Colors.green,
      WorkoutStatus.inProgress => DT.cardOrange,
      WorkoutStatus.planned => DT.metricBlue,
    };
    final statusLabel = switch (workout.status) {
      WorkoutStatus.completed => 'Teljesítve',
      WorkoutStatus.inProgress => 'Folyamatban',
      WorkoutStatus.planned => 'Tervezett',
    };

    return GestureDetector(
      onTap: () => context.push('/workout-detail', extra: workout.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: DT.s3),
        padding: const EdgeInsets.all(DT.s4),
        decoration: BoxDecoration(
          color: DT.gbWhite,
          borderRadius: BorderRadius.circular(DT.rCardSmall),
          border: Border(left: BorderSide(color: workout.color, width: 3)),
          boxShadow: [
            BoxShadow(
                color: DT.of(context).shadowLight,
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('yyyy. MM. dd.').format(workout.scheduledDate),
                    style: TextStyle(
                        fontSize: DT.s3,
                        color: DT.of(context).textSecondary),
                  ),
                  const SizedBox(height: DT.s1),
                  Text(
                    workout.title,
                    style: TextStyle(
                      fontSize: DT.s4,
                      fontWeight: FontWeight.w600,
                      color: DT.of(context).textPrimary,
                    ),
                  ),
                  const SizedBox(height: DT.s1),
                  Text(
                    '${workout.exercises.length} gyakorlat · ${workout.estimatedDuration}',
                    style: TextStyle(
                        fontSize: DT.s3,
                        color: DT.of(context).textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DT.s2, vertical: DT.s1),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(DT.s1),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: DT.s2),
                Icon(Icons.arrow_forward_ios,
                    size: 12, color: DT.of(context).textGrey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
