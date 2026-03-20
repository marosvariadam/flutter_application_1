import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/coach/data/models/athlete_model.dart';
import 'package:flutter_application_1/services/athlete_service.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class CoachHomePage extends StatefulWidget {
  const CoachHomePage({super.key});
  @override
  State<CoachHomePage> createState() => _CoachHomePageState();
}

class _CoachHomePageState extends State<CoachHomePage> {
  List<AthleteModel> _athletes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final athletes = await AthleteService().getMyAthletes();
    if (mounted) setState(() { _athletes = athletes; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return Scaffold(
      backgroundColor: DT.of(context).bg,
      appBar: AppBar(
        backgroundColor: DT.of(context).bg,
        elevation: 0,
        toolbarHeight: 80,
        title: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(shape: BoxShape.circle, color: DT.metricBlue.withOpacity(0.15), border: Border.all(color: DT.gbWhite, width: 2)),
              child: const Icon(Icons.person, color: DT.metricBlue),
            ),
            const SizedBox(width: DT.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Szia, Edző!', style: TextStyle(fontSize: DT.s4, fontWeight: FontWeight.w600, color: DT.of(context).textPrimary)),
                  Text(DateFormat('yyyy.MM.dd').format(now), style: TextStyle(fontSize: DT.s3, color: DT.of(context).textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(DT.s5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatsRow(athletes: _athletes),
                  const SizedBox(height: DT.s5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Atlétáim', style: TextStyle(fontSize: DT.s4, fontWeight: FontWeight.w700, color: DT.of(context).textPrimary)),
                      TextButton(onPressed: () => context.go('/session'), child: const Text('Összes')),
                    ],
                  ),
                  const SizedBox(height: DT.s3),
                  if (_athletes.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: DT.s5),
                        child: Text('Nem található adat', style: TextStyle(color: DT.of(context).textSecondary, fontSize: DT.s4)),
                      ),
                    )
                  else
                    SizedBox(
                      height: 130,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _athletes.length,
                        separatorBuilder: (_, __) => const SizedBox(width: DT.s3),
                        itemBuilder: (context, index) => _AthleteChip(
                          athlete: _athletes[index],
                          onTap: () => context.push('/athlete-detail/${_athletes[index].id}'),
                        ),
                      ),
                    ),
                  const SizedBox(height: DT.s5),
                  if (_athletes.isNotEmpty) ...[
                    Text('Ezen a héten', style: TextStyle(fontSize: DT.s4, fontWeight: FontWeight.w700, color: DT.of(context).textPrimary)),
                    const SizedBox(height: DT.s3),
                    ..._athletes.map((a) => _AthleteWeekRow(athlete: a, weekStart: monday)),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/workout-builder'),
        backgroundColor: DT.gbBlack,
        foregroundColor: DT.gbWhite,
        icon: const Icon(Icons.add),
        label: const Text('Új edzés'),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<AthleteModel> athletes;
  const _StatsRow({required this.athletes});
  @override
  Widget build(BuildContext context) {
    final activeStreaks = athletes.where((a) => a.streakDays >= 7).length;
    return Row(
      children: [
        Expanded(child: _StatCard(color: DT.cardBlue.withOpacity(0.35), value: '${athletes.length}', label: 'Atléta', icon: Icons.people_outline)),
        const SizedBox(width: DT.s3),
        Expanded(child: _StatCard(color: DT.cardTeal.withOpacity(0.35), value: '${athletes.length * 3}', label: 'Edzés / hét', icon: Icons.fitness_center_outlined)),
        const SizedBox(width: DT.s3),
        Expanded(child: _StatCard(color: DT.cardYellow.withOpacity(0.5), value: '$activeStreaks', label: 'Aktív streak', icon: Icons.local_fire_department_outlined)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final Color color;
  final String value;
  final String label;
  final IconData icon;
  const _StatCard({required this.color, required this.value, required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DT.s3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(DT.rCardSmall)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: DT.of(context).textPrimary),
          const SizedBox(height: DT.s2),
          Text(value, style: TextStyle(fontSize: DT.s5, fontWeight: FontWeight.w700, color: DT.of(context).textPrimary)),
          Text(label, style: TextStyle(fontSize: 10, color: DT.of(context).textSecondary)),
        ],
      ),
    );
  }
}

class _AthleteChip extends StatelessWidget {
  final AthleteModel athlete;
  final VoidCallback onTap;
  const _AthleteChip({required this.athlete, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(DT.s3),
        decoration: BoxDecoration(
          color: DT.gbWhite,
          borderRadius: BorderRadius.circular(DT.rCardSmall),
          boxShadow: [BoxShadow(color: DT.of(context).shadowLight, blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(shape: BoxShape.circle, color: DT.metricBlue.withOpacity(0.12)),
              child: Center(child: Text(athlete.initials, style: const TextStyle(fontSize: DT.s4, fontWeight: FontWeight.w700, color: DT.metricBlue))),
            ),
            const SizedBox(height: DT.s2),
            Text(athlete.firstName, style: TextStyle(fontSize: DT.s3, fontWeight: FontWeight.w600, color: DT.of(context).textPrimary), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
            Text('${athlete.streakDays} nap 🔥', style: TextStyle(fontSize: 10, color: DT.of(context).textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _AthleteWeekRow extends StatelessWidget {
  final AthleteModel athlete;
  final DateTime weekStart;
  const _AthleteWeekRow({required this.athlete, required this.weekStart});
  static const _dayLabels = ['H', 'K', 'Sz', 'Cs', 'P', 'Szo', 'V'];
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DT.s3),
      padding: const EdgeInsets.all(DT.s4),
      decoration: BoxDecoration(
        color: DT.gbWhite,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        boxShadow: [BoxShadow(color: DT.of(context).shadowLight, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(shape: BoxShape.circle, color: DT.metricBlue.withOpacity(0.12)),
            child: Center(child: Text(athlete.initials, style: const TextStyle(fontSize: DT.s3, fontWeight: FontWeight.w700, color: DT.metricBlue))),
          ),
          const SizedBox(width: DT.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(athlete.fullName, style: TextStyle(fontWeight: FontWeight.w600, color: DT.of(context).textPrimary, fontSize: DT.s3)),
                const SizedBox(height: DT.s2),
                Row(
                  children: List.generate(7, (i) {
                    return Container(
                      margin: const EdgeInsets.only(right: DT.s1),
                      width: 26, height: 26,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: DT.of(context).bg),
                      child: Center(child: Text(_dayLabels[i], style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: DT.of(context).textSecondary))),
                    );
                  }),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/athlete-detail/${athlete.id}'),
            child: Icon(Icons.arrow_forward_ios, size: 14, color: DT.of(context).textGrey),
          ),
        ],
      ),
    );
  }
}
