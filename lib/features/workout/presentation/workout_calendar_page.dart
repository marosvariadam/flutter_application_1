import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/auth/bloc/auth_bloc.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:flutter_application_1/features/workout/data/repositories/workout_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WorkoutCalendarPage extends StatefulWidget {
  const WorkoutCalendarPage({super.key});

  @override
  State<WorkoutCalendarPage> createState() => _WorkoutCalendarPageState();
}

class _WorkoutCalendarPageState extends State<WorkoutCalendarPage> {
  late DateTime _focusedMonth;
  List<WorkoutModel> _workouts = [];
  DateTime? _selectedDay;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _loadMonth(_focusedMonth);
  }

  Future<void> _loadMonth(DateTime month) async {
    setState(() => _loading = true);
    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    try {
      final auth = context.read<AuthBloc>().state;
      final isTrainer =
          auth is AuthAuthenticated && auth.user.isTrainer;
      final repo = context.read<WorkoutRepository>();
      final workouts = isTrainer
          ? await repo.getTrainerCalendar(from, to)
          : await repo.getAthleteCalendar(from, to);
      setState(() => _workouts = workouts);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _prevMonth() {
    final prev = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    setState(() {
      _focusedMonth = prev;
      _selectedDay = null;
    });
    _loadMonth(prev);
  }

  void _nextMonth() {
    final next = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    setState(() {
      _focusedMonth = next;
      _selectedDay = null;
    });
    _loadMonth(next);
  }

  List<WorkoutModel> _workoutsForDay(DateTime day) {
    return _workouts.where((w) {
      final d = w.scheduledDate;
      return d.year == day.year &&
          d.month == day.month &&
          d.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.of(context).bg,
      appBar: AppBar(
        backgroundColor: DT.of(context).bg,
        elevation: 0,
        leading: BackButton(color: DT.of(context).textPrimary),
        title: Text('Naptár',
            style: TextStyle(
                color: DT.of(context).textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _CalendarHeader(
            month: _focusedMonth,
            onPrev: _prevMonth,
            onNext: _nextMonth,
          ),
          if (_loading)
            const LinearProgressIndicator()
          else
            _CalendarGrid(
              month: _focusedMonth,
              workouts: _workouts,
              selectedDay: _selectedDay,
              onDayTap: (day) => setState(() => _selectedDay = day),
            ),
          if (_selectedDay != null) ...[
            const Divider(),
            Expanded(
              child: _DayWorkoutList(
                workouts: _workoutsForDay(_selectedDay!),
                day: _selectedDay!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _CalendarHeader(
      {required this.month, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: DT.s4, vertical: DT.s2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left)),
          Text(
            DateFormat('yyyy. MMMM', 'hu').format(month),
            style: TextStyle(
                color: DT.of(context).textPrimary,
                fontSize: DT.s4,
                fontWeight: FontWeight.w700),
          ),
          IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final List<WorkoutModel> workouts;
  final DateTime? selectedDay;
  final void Function(DateTime) onDayTap;

  const _CalendarGrid({
    required this.month,
    required this.workouts,
    required this.selectedDay,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    // Monday = 0
    final startOffset = (firstDay.weekday - 1) % 7;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DT.s3),
      child: Column(
        children: [
          // Weekday headers
          Row(
            children: ['H', 'K', 'Sze', 'Cs', 'P', 'Szo', 'V']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: TextStyle(
                                color: DT.of(context).textSecondary,
                                fontSize: DT.s3,
                                fontWeight: FontWeight.w600)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: DT.s2),
          // Day grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (context, i) {
              if (i < startOffset) return const SizedBox.shrink();
              final day = i - startOffset + 1;
              final date = DateTime(month.year, month.month, day);
              final hasWorkout = workouts.any((w) {
                final d = w.scheduledDate;
                return d.year == date.year &&
                    d.month == date.month &&
                    d.day == date.day;
              });
              final isSelected = selectedDay?.year == date.year &&
                  selectedDay?.month == date.month &&
                  selectedDay?.day == date.day;
              final isToday = DateUtils.isSameDay(date, DateTime.now());

              return GestureDetector(
                onTap: () => onDayTap(date),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? DT.metricBlue
                        : isToday
                            ? DT.metricBlue.withOpacity(0.15)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : DT.of(context).textPrimary,
                          fontWeight: isToday
                              ? FontWeight.w700
                              : FontWeight.normal,
                          fontSize: DT.s3,
                        ),
                      ),
                      if (hasWorkout)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : DT.metricBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DayWorkoutList extends StatelessWidget {
  final List<WorkoutModel> workouts;
  final DateTime day;

  const _DayWorkoutList(
      {required this.workouts, required this.day});

  @override
  Widget build(BuildContext context) {
    if (workouts.isEmpty) {
      return Center(
        child: Text(
          'Nincs edzés ${day.month}. ${day.day}.-én.',
          style: TextStyle(
              color: DT.of(context).textSecondary, fontSize: DT.s4),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(DT.s4),
      itemCount: workouts.length,
      separatorBuilder: (_, __) => const SizedBox(height: DT.s3),
      itemBuilder: (context, i) {
        final w = workouts[i];
        return Material(
          color: DT.gbWhite,
          borderRadius: BorderRadius.circular(DT.rCardSmall),
          child: InkWell(
            borderRadius: BorderRadius.circular(DT.rCardSmall),
            onTap: () => context.push('/workout/${w.id}'),
            child: Padding(
              padding: const EdgeInsets.all(DT.s4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(w.title,
                        style: TextStyle(
                            color: DT.of(context).textPrimary,
                            fontWeight: FontWeight.w600)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DT.s2, vertical: DT.s1),
                    decoration: BoxDecoration(
                      color: DT.metricBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(DT.rChip),
                    ),
                    child: Text(w.status.label,
                        style: const TextStyle(
                            color: DT.metricBlue,
                            fontSize: DT.s3,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
