import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/coach/data/coach_mock_data.dart';
import 'package:flutter_application_1/features/coach/data/models/athlete_model.dart';
import 'package:go_router/go_router.dart';

class AthletesPage extends StatefulWidget {
  const AthletesPage({super.key});

  @override
  State<AthletesPage> createState() => _AthletesPageState();
}

class _AthletesPageState extends State<AthletesPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = CoachMockData.getAthletes();
    final filtered = _query.isEmpty
        ? all
        : all
            .where(
              (a) => a.fullName.toLowerCase().contains(_query.toLowerCase()),
            )
            .toList();

    return Scaffold(
      backgroundColor: DT.bg,
      appBar: AppBar(
        backgroundColor: DT.bg,
        elevation: 0,
        title: const Text(
          'Atlétáim',
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
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(DT.s5, 0, DT.s5, DT.s3),
            child: Container(
              decoration: BoxDecoration(
                color: DT.gbWhite,
                borderRadius: BorderRadius.circular(DT.rCardSmall),
                boxShadow: const [
                  BoxShadow(color: DT.shadowLight, blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Atléta keresése…',
                  prefixIcon: Icon(Icons.search, color: DT.iconLight),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: DT.s4),
                ),
              ),
            ),
          ),
          // List
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Nem található atléta.',
                      style: TextStyle(color: DT.textSecondary, fontSize: DT.s4),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(DT.s5, 0, DT.s5, DT.s8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: DT.s3),
                    itemBuilder: (context, index) => _AthleteCard(
                      athlete: filtered[index],
                      onTap: () => context.push('/athlete-detail/${filtered[index].id}'),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: DT.gbBlack,
        child: const Icon(Icons.person_add, color: DT.gbWhite),
      ),
    );
  }
}

// ─── Athlete Card ─────────────────────────────────────────────────────────────

class _AthleteCard extends StatelessWidget {
  final AthleteModel athlete;
  final VoidCallback onTap;
  const _AthleteCard({required this.athlete, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DT.gbWhite,
      borderRadius: BorderRadius.circular(DT.rCardSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        child: Padding(
          padding: const EdgeInsets.all(DT.s4),
          child: Row(
            children: [
              // Initials avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DT.metricBlue.withOpacity(0.12),
                ),
                child: Center(
                  child: Text(
                    athlete.initials,
                    style: const TextStyle(
                      fontSize: DT.s4,
                      fontWeight: FontWeight.w700,
                      color: DT.metricBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DT.s4),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      athlete.fullName,
                      style: const TextStyle(
                        fontSize: DT.s4,
                        fontWeight: FontWeight.w600,
                        color: DT.textPrimary,
                      ),
                    ),
                    if (athlete.goal != null) ...[
                      const SizedBox(height: DT.s1),
                      Text(
                        'Cél: ${athlete.goal}',
                        style: const TextStyle(
                          fontSize: DT.s3,
                          color: DT.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: DT.s2),
                    Row(
                      children: [
                        _Tag('${athlete.workoutCount} edzés'),
                        const SizedBox(width: DT.s2),
                        _Tag('${athlete.streakDays} nap 🔥'),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: DT.textGrey, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DT.s2, vertical: DT.s1),
      decoration: BoxDecoration(
        color: DT.bg,
        borderRadius: BorderRadius.circular(DT.s1),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: DT.s3, color: DT.textSecondary),
      ),
    );
  }
}
