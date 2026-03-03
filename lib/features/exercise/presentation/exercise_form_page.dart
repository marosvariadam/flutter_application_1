import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/exercise/data/repositories/exercise_repository.dart';

class ExerciseFormPage extends StatefulWidget {
  final String? exerciseId;
  final String? initialName;
  final String? initialMuscleGroup;
  final String? initialDescription;

  const ExerciseFormPage({
    super.key,
    this.exerciseId,
    this.initialName,
    this.initialMuscleGroup,
    this.initialDescription,
  });

  @override
  State<ExerciseFormPage> createState() => _ExerciseFormPageState();
}

class _ExerciseFormPageState extends State<ExerciseFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  String _muscleGroup = 'Mellkas';
  bool _loading = false;
  String? _error;

  static const _muscleGroups = [
    'Mellkas', 'Hát', 'Váll', 'Bicepsz', 'Tricepsz',
    'Láb', 'Has', 'Comb', 'Fenék', 'Vádli',
  ];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName ?? '');
    _description =
        TextEditingController(text: widget.initialDescription ?? '');
    _muscleGroup = widget.initialMuscleGroup ?? 'Mellkas';
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<ExerciseRepository>();
      if (widget.exerciseId != null) {
        await repo.updateExercise(
          widget.exerciseId!,
          name: _name.text.trim(),
          muscleGroup: _muscleGroup,
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
        );
      } else {
        await repo.createExercise(
          name: _name.text.trim(),
          muscleGroup: _muscleGroup,
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.exerciseId != null
                  ? 'Gyakorlat frissítve!'
                  : 'Gyakorlat létrehozva!')),
        );
        context.pop();
      }
    } catch (_) {
      setState(() => _error = 'Nem sikerült menteni.');
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
        title: Text(
            widget.exerciseId != null
                ? 'Gyakorlat szerkesztése'
                : 'Új gyakorlat',
            style: const TextStyle(
                color: DT.textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DT.s5),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: DT.s4),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Neve',
                  prefixIcon: Icon(Icons.fitness_center_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Kötelező' : null,
              ),
              const SizedBox(height: DT.s4),
              const Text('Izomcsoport',
                  style: TextStyle(
                      color: DT.textSecondary,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: DT.s2),
              DropdownButtonFormField<String>(
                value: _muscleGroup,
                items: _muscleGroups
                    .map((mg) => DropdownMenuItem(
                        value: mg, child: Text(mg)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _muscleGroup = v ?? _muscleGroup),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: DT.s3),
              TextFormField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Leírás (opcionális)',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: DT.s3),
                Text(_error!,
                    style: const TextStyle(
                        color: DT.cardRed, fontSize: DT.s3)),
              ],
              const SizedBox(height: DT.s6),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DT.metricBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(DT.rCardSmall)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Mentés',
                          style: TextStyle(
                              color: DT.textWhite,
                              fontSize: DT.s4,
                              fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
