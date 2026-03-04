import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/user_session.dart';
import 'package:flutter_application_1/features/coach/data/coach_mock_data.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:flutter_application_1/features/workout/data/workout_mock_data.dart';
import 'package:flutter_application_1/services/auth_service.dart';

// ─── Entry point ─────────────────────────────────────────────────────────────

class ProfilesPage extends StatelessWidget {
  const ProfilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return UserSession.instance.isCoach
        ? const _CoachProfile()
        : const _AthleteProfile();
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

Future<void> _logout(BuildContext context) async {
  await AuthService().logout();
  UserSession.instance.clear();
  if (context.mounted) context.go('/login');
}

Widget _initialsAvatar({double radius = 32}) {
  final initials = UserSession.instance.initials;
  return CircleAvatar(
    radius: radius,
    backgroundColor: DT.metricBlue.withOpacity(0.15),
    child: Text(
      initials.isNotEmpty ? initials : '?',
      style: TextStyle(
        color: DT.metricBlue,
        fontSize: radius * 0.6,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

// ─── Athlete Profile ──────────────────────────────────────────────────────────

class _AthleteProfile extends StatefulWidget {
  const _AthleteProfile();

  @override
  State<_AthleteProfile> createState() => _AthleteProfileState();
}

class _AthleteProfileState extends State<_AthleteProfile>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = UserSession.instance;
    return Scaffold(
      backgroundColor: DT.bg,
      appBar: AppBar(
        backgroundColor: DT.bg,
        elevation: 0,
        title: const Text(
          'Profil',
          style: TextStyle(
            color: DT.textPrimary,
            fontSize: DT.s4,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            color: DT.bg,
            padding: const EdgeInsets.fromLTRB(DT.s5, DT.s3, DT.s5, DT.s4),
            child: Column(
              children: [
                _initialsAvatar(radius: 36),
                const SizedBox(height: DT.s2),
                Text(
                  session.displayName.isNotEmpty
                      ? session.displayName
                      : 'Sportoló',
                  style: const TextStyle(
                    color: DT.textPrimary,
                    fontSize: DT.s5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if ((session.email ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    session.email!,
                    style: const TextStyle(
                        color: DT.textSecondary, fontSize: DT.s3),
                  ),
                ],
                const SizedBox(height: DT.s2),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DT.s3, vertical: 4),
                  decoration: BoxDecoration(
                    color: DT.metricBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(DT.rChip),
                  ),
                  child: const Text(
                    'Sportoló',
                    style: TextStyle(
                      color: DT.metricBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: DT.s3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Tab bar ─────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tab,
              labelColor: DT.metricBlue,
              unselectedLabelColor: DT.textSecondary,
              indicatorColor: DT.metricBlue,
              tabs: const [
                Tab(text: 'Profil'),
                Tab(text: 'Fejlődés'),
                Tab(text: 'Edzések'),
              ],
            ),
          ),

          // ── Tab content ─────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                _AthleteProfileTab(),
                _AthleteProgressTab(),
                _AthleteTrainingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 0: Profil ─────────────────────────────────────────────────────────────

class _AthleteProfileTab extends StatefulWidget {
  const _AthleteProfileTab();

  @override
  State<_AthleteProfileTab> createState() => _AthleteProfileTabState();
}

class _AthleteProfileTabState extends State<_AthleteProfileTab>
    with AutomaticKeepAliveClientMixin {
  bool _notificationsOn = true;
  Map<String, dynamic>? _survey;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSurvey();
  }

  Future<void> _loadSurvey() async {
    const storage = FlutterSecureStorage();
    final raw = await storage.read(key: 'athlete_survey');
    if (raw != null && mounted) {
      setState(() => _survey = jsonDecode(raw) as Map<String, dynamic>);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final goal = _survey?['goal'] as String?;
    final freq = _survey?['gymFrequency'] as int?;
    final injuries = (_survey?['injuries'] as List?)?.cast<String>();

    return ListView(
      padding: const EdgeInsets.all(DT.s5),
      children: [
        // ── Survey data ────────────────────────────────────────────────
        const _SectionTitle('Adataim'),
        const SizedBox(height: DT.s3),
        Row(
          children: [
            Expanded(
              child: _InfoCard(
                color: DT.metricGreen,
                label: 'Cél',
                value: goal ?? '—',
              ),
            ),
            const SizedBox(width: DT.s3),
            Expanded(
              child: _InfoCard(
                color: DT.metricOrange,
                label: 'Heti edzések',
                value: freq != null ? '${freq}x' : '—',
              ),
            ),
          ],
        ),
        if (injuries != null && injuries.isNotEmpty) ...[
          const SizedBox(height: DT.s3),
          _InfoCard(
            color: DT.cardBlue,
            label: 'Sérülések',
            value: injuries.join(', '),
          ),
        ],

        const SizedBox(height: DT.s6),

        // ── Settings ────────────────────────────────────────────────────
        const _SectionTitle('Beállítások'),
        const SizedBox(height: DT.s3),
        _SettingsTile(
          icon: Icons.notifications_outlined,
          title: 'Értesítések',
          trailing: Switch(
            value: _notificationsOn,
            onChanged: (v) => setState(() => _notificationsOn = v),
            activeColor: DT.metricBlue,
          ),
        ),
        _SettingsTile(
          icon: Icons.lock_outline,
          title: 'Adatvédelem',
          trailing: const Icon(Icons.chevron_right, color: DT.textGrey),
          onTap: () {},
        ),
        _SettingsTile(
          icon: Icons.help_outline,
          title: 'Súgó',
          trailing: const Icon(Icons.chevron_right, color: DT.textGrey),
          onTap: () {},
        ),
        _SettingsTile(
          icon: Icons.info_outline,
          title: 'Az alkalmazásról',
          trailing: const Icon(Icons.chevron_right, color: DT.textGrey),
          onTap: () {},
        ),

        const SizedBox(height: DT.s6),
        _LogoutButton(),
        const SizedBox(height: DT.s6),
      ],
    );
  }
}

// ── Tab 1: Fejlődés ───────────────────────────────────────────────────────────

class _AthleteProgressTab extends StatelessWidget {
  const _AthleteProgressTab();

  static const _weekLabels = ['H', 'K', 'Sze', 'Cs', 'P', 'Szo', 'V'];
  static const _weightData = <double>[
    82.2, 81.5, 80.8, 80.1, 79.6, 78.8, 78.0, 77.4, 76.8, 76.2,
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final workouts = WorkoutMockData.getAthleteWorkouts('a1');
    final workoutWeekdays =
        workouts.map((w) => w.scheduledDate.weekday).toSet();

    return ListView(
      padding: const EdgeInsets.all(DT.s5),
      children: [
        // ── Summary stats ──────────────────────────────────────────────
        const _SectionTitle('Összesítő'),
        const SizedBox(height: DT.s3),
        Row(
          children: [
            Expanded(child: _StatCard(label: 'Összes edzés', value: '42')),
            const SizedBox(width: DT.s3),
            Expanded(child: _StatCard(label: 'Streak', value: '7 nap')),
            const SizedBox(width: DT.s3),
            Expanded(
              child: _StatCard(
                label: 'Ez a hét',
                value: '${workoutWeekdays.length}/7',
              ),
            ),
          ],
        ),

        const SizedBox(height: DT.s6),

        // ── Weekly activity bars ───────────────────────────────────────
        const _SectionTitle('Heti aktivitás'),
        const SizedBox(height: DT.s3),
        Container(
          padding: const EdgeInsets.all(DT.s4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DT.rCardSmall),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final weekday = i + 1; // 1=Mon … 7=Sun
              final hasWorkout = workoutWeekdays.contains(weekday);
              final isToday = now.weekday == weekday;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: hasWorkout ? 56 : 18,
                    decoration: BoxDecoration(
                      color: hasWorkout
                          ? (isToday
                              ? DT.metricBlue
                              : DT.metricBlue.withOpacity(0.45))
                          : DT.borderGrey,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: DT.s2),
                  Text(
                    _weekLabels[i],
                    style: TextStyle(
                      fontSize: DT.s3,
                      color: isToday ? DT.metricBlue : DT.textSecondary,
                      fontWeight:
                          isToday ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),

        const SizedBox(height: DT.s6),

        // ── Weight progress ────────────────────────────────────────────
        const _SectionTitle('Súlymenete'),
        const SizedBox(height: DT.s3),
        Container(
          padding: const EdgeInsets.all(DT.s4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DT.rCardSmall),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_weightData.first} kg → ${_weightData.last} kg',
                    style: const TextStyle(
                      color: DT.textPrimary,
                      fontSize: DT.s3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DT.s2, vertical: 3),
                    decoration: BoxDecoration(
                      color: DT.metricGreen,
                      borderRadius: BorderRadius.circular(DT.rChip),
                    ),
                    child: Text(
                      '-${(_weightData.first - _weightData.last).toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: DT.s3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DT.s4),
              SizedBox(
                height: 100,
                child: _WeightLineChart(data: _weightData),
              ),
            ],
          ),
        ),

        const SizedBox(height: DT.s5),
      ],
    );
  }
}

class _WeightLineChart extends StatelessWidget {
  final List<double> data;
  const _WeightLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final minV = data.reduce((a, b) => a < b ? a : b) - 0.5;
        final maxV = data.reduce((a, b) => a > b ? a : b) + 0.5;
        final range = maxV - minV;

        final points = List.generate(data.length, (i) {
          final x = w * i / (data.length - 1);
          final y = h - (h * (data[i] - minV) / range);
          return Offset(x, y);
        });

        return CustomPaint(
          painter: _LinePainter(points: points),
          size: Size(w, h),
        );
      },
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<Offset> points;
  _LinePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final fill = Paint()
      ..color = DT.metricBlue.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    final line = Paint()
      ..color = DT.metricBlue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dot = Paint()
      ..color = DT.metricBlue
      ..style = PaintingStyle.fill;

    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) fillPath.lineTo(p.dx, p.dy);
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fill);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, line);

    for (final p in points) canvas.drawCircle(p, 3.5, dot);
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => true;
}

// ── Tab 2: Edzések ────────────────────────────────────────────────────────────

class _AthleteTrainingsTab extends StatelessWidget {
  const _AthleteTrainingsTab();

  List<WorkoutModel> _buildHistory() {
    final now = DateTime.now();
    final templates = WorkoutMockData.getAthleteWorkouts('a1');
    final history = <WorkoutModel>[];

    for (int week = 1; week <= 4; week++) {
      final weekMonday =
          now.subtract(Duration(days: now.weekday - 1 + week * 7));
      for (int di = 0; di < 3; di++) {
        final date = weekMonday.add(Duration(days: [0, 2, 4][di]));
        if (date.isBefore(now)) {
          final t = templates[di];
          history.add(WorkoutModel(
            id: '${t.id}-hist-w$week-d$di',
            title: t.title,
            scheduledDate: date,
            athleteId: t.athleteId,
            coachId: t.coachId,
            difficulty: t.difficulty,
            color: t.color,
            estimatedDuration: t.estimatedDuration,
            kcal: t.kcal,
            exercises: t.exercises,
          ));
        }
      }
    }
    history.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
    return history;
  }

  String _fmt(DateTime d) =>
      '${d.year}. ${d.month.toString().padLeft(2, '0')}. '
      '${d.day.toString().padLeft(2, '0')}.';

  @override
  Widget build(BuildContext context) {
    final history = _buildHistory();

    if (history.isEmpty) {
      return const Center(
        child: Text(
          'Még nincs befejezett edzés.',
          style: TextStyle(color: DT.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(DT.s5),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: DT.s3),
      itemBuilder: (context, i) {
        final w = history[i];
        return Container(
          padding: const EdgeInsets.all(DT.s4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DT.rCardSmall),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: w.color,
                  borderRadius: BorderRadius.circular(DT.s2),
                ),
                child: const Icon(Icons.fitness_center,
                    color: DT.textPrimary, size: 22),
              ),
              const SizedBox(width: DT.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w.title,
                      style: const TextStyle(
                        fontSize: DT.s4,
                        fontWeight: FontWeight.w600,
                        color: DT.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _fmt(w.scheduledDate),
                      style: const TextStyle(
                          fontSize: DT.s3, color: DT.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(w.kcal,
                      style: const TextStyle(
                          fontSize: DT.s3,
                          color: DT.textSecondary,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(w.estimatedDuration,
                      style: const TextStyle(
                          fontSize: DT.s3, color: DT.textSecondary)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Coach Profile ────────────────────────────────────────────────────────────

class _CoachProfile extends StatefulWidget {
  const _CoachProfile();

  @override
  State<_CoachProfile> createState() => _CoachProfileState();
}

class _CoachProfileState extends State<_CoachProfile> {
  bool _notificationsOn = true;

  @override
  Widget build(BuildContext context) {
    final session = UserSession.instance;
    final athletes = CoachMockData.getAthletes();
    final totalWorkouts =
        athletes.fold<int>(0, (sum, a) => sum + a.workoutCount);

    return Scaffold(
      backgroundColor: DT.bg,
      appBar: AppBar(
        backgroundColor: DT.bg,
        elevation: 0,
        title: const Text(
          'Profil',
          style: TextStyle(
            color: DT.textPrimary,
            fontSize: DT.s4,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(DT.s5),
        children: [
          // ── Avatar + name ──────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                _initialsAvatar(radius: 40),
                const SizedBox(height: DT.s3),
                Text(
                  session.displayName.isNotEmpty ? session.displayName : 'Edző',
                  style: const TextStyle(
                    color: DT.textPrimary,
                    fontSize: DT.s5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if ((session.email ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    session.email!,
                    style: const TextStyle(
                        color: DT.textSecondary, fontSize: DT.s3),
                  ),
                ],
                const SizedBox(height: DT.s2),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DT.s3, vertical: 4),
                  decoration: BoxDecoration(
                    color: DT.metricBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(DT.rChip),
                  ),
                  child: const Text(
                    'Edző',
                    style: TextStyle(
                      color: DT.metricBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: DT.s3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: DT.s6),

          // ── Stats ──────────────────────────────────────────────────────
          const _SectionTitle('Statisztikák'),
          const SizedBox(height: DT.s3),
          Row(
            children: [
              Expanded(
                child:
                    _StatCard(label: 'Aktív sportolók', value: '${athletes.length}'),
              ),
              const SizedBox(width: DT.s3),
              Expanded(
                child: _StatCard(label: 'Összes edzés', value: '$totalWorkouts'),
              ),
            ],
          ),

          const SizedBox(height: DT.s6),

          // ── Settings ───────────────────────────────────────────────────
          const _SectionTitle('Beállítások'),
          const SizedBox(height: DT.s3),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Értesítések',
            trailing: Switch(
              value: _notificationsOn,
              onChanged: (v) => setState(() => _notificationsOn = v),
              activeColor: DT.metricBlue,
            ),
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Adatvédelem',
            trailing: const Icon(Icons.chevron_right, color: DT.textGrey),
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.help_outline,
            title: 'Súgó',
            trailing: const Icon(Icons.chevron_right, color: DT.textGrey),
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Az alkalmazásról',
            trailing: const Icon(Icons.chevron_right, color: DT.textGrey),
            onTap: () {},
          ),

          const SizedBox(height: DT.s6),
          _LogoutButton(),
          const SizedBox(height: DT.s6),
        ],
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: DT.textPrimary,
        fontSize: DT.s4,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DT.s3),
      constraints: const BoxConstraints(minHeight: 72),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: DT.s3, color: DT.textSecondary)),
          const SizedBox(height: DT.s2),
          Text(
            value,
            style: const TextStyle(
              fontSize: DT.s4,
              fontWeight: FontWeight.w700,
              color: DT.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DT.s4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: DT.metricBlue,
              fontSize: DT.s8,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style:
                const TextStyle(color: DT.textSecondary, fontSize: DT.s3),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DT.s2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: DT.borderGrey,
            borderRadius: BorderRadius.circular(DT.s2),
          ),
          child: Icon(icon, color: DT.iconLight, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: DT.s4,
            fontWeight: FontWeight.w500,
            color: DT.textPrimary,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DT.rCardSmall),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => _logout(context),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DT.rCardSmall),
          ),
        ),
        icon: const Icon(Icons.logout, color: Colors.red, size: 20),
        label: const Text(
          'Kijelentkezés',
          style: TextStyle(
            color: Colors.red,
            fontSize: DT.s4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
