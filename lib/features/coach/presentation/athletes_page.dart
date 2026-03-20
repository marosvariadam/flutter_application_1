import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/coach/data/models/athlete_model.dart';
import 'package:flutter_application_1/services/athlete_service.dart';
import 'package:go_router/go_router.dart';

class AthletesPage extends StatefulWidget {
  const AthletesPage({super.key});
  @override
  State<AthletesPage> createState() => _AthletesPageState();
}

class _AthletesPageState extends State<AthletesPage> {
  final _search = TextEditingController();
  String _query = '';
  List<AthleteModel> _athletes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAthletes();
  }

  Future<void> _loadAthletes() async {
    final athletes = await AthleteService().getMyAthletes();
    if (mounted) setState(() { _athletes = athletes; _isLoading = false; });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? _athletes
        : _athletes.where((a) => a.fullName.toLowerCase().contains(_query.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: DT.of(context).bg,
      appBar: AppBar(
        backgroundColor: DT.of(context).bg,
        elevation: 0,
        title: Text('Atlétáim', style: TextStyle(color: DT.of(context).textPrimary, fontSize: DT.s4, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(DT.s5, 0, DT.s5, DT.s3),
                  child: Container(
                    decoration: BoxDecoration(
                      color: DT.gbWhite,
                      borderRadius: BorderRadius.circular(DT.rCardSmall),
                      boxShadow: [BoxShadow(color: DT.of(context).shadowLight, blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: TextField(
                      controller: _search,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Atléta keresése…',
                        prefixIcon: Icon(Icons.search, color: DT.of(context).iconLight),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: DT.s4),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: DT.of(context).borderGrey),
                              const SizedBox(height: DT.s3),
                              Text('Nem található adat', style: TextStyle(color: DT.of(context).textSecondary, fontSize: DT.s4)),
                            ],
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
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(shape: BoxShape.circle, color: DT.metricBlue.withOpacity(0.12)),
                child: Center(
                  child: Text(athlete.initials, style: const TextStyle(fontSize: DT.s4, fontWeight: FontWeight.w700, color: DT.metricBlue)),
                ),
              ),
              const SizedBox(width: DT.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(athlete.fullName, style: TextStyle(fontSize: DT.s4, fontWeight: FontWeight.w600, color: DT.of(context).textPrimary)),
                    if (athlete.goal != null) ...[
                      const SizedBox(height: DT.s1),
                      Text('Cél: ${athlete.goal}', style: TextStyle(fontSize: DT.s3, color: DT.of(context).textSecondary)),
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
              Icon(Icons.arrow_forward_ios, color: DT.of(context).textGrey, size: 14),
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
      decoration: BoxDecoration(color: DT.of(context).bg, borderRadius: BorderRadius.circular(DT.s1)),
      child: Text(label, style: TextStyle(fontSize: DT.s3, color: DT.of(context).textSecondary)),
    );
  }
}
