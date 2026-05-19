import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:flutter_application_1/features/onboarding/data/models/onboarding_models.dart';

class TrainerFormBuilderPage extends StatefulWidget {
  const TrainerFormBuilderPage({super.key});

  @override
  State<TrainerFormBuilderPage> createState() => _TrainerFormBuilderPageState();
}

class _TrainerFormBuilderPageState extends State<TrainerFormBuilderPage> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final List<_QuestionDraft> _questions = [];
  bool _loaded = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _populateFromForm(OnboardingFormModel form) {
    _titleCtrl.text = form.title;
    _descCtrl.text = form.description ?? '';
    _questions.clear();
    for (final q in form.questions) {
      _questions.add(_QuestionDraft.fromModel(q));
    }
    _loaded = true;
  }

  void _addQuestion() {
    setState(() {
      _questions.add(_QuestionDraft());
    });
  }

  void _removeQuestion(int index) {
    setState(() => _questions.removeAt(index));
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add meg az űrlap nevét!')),
      );
      return;
    }
    final questions = _questions
        .where((q) => q.textCtrl.text.trim().isNotEmpty)
        .map((q) => OnboardingQuestion(
              id: q.id ?? '',
              text: q.textCtrl.text.trim(),
              type: q.type,
              options: q.type == QuestionType.multipleChoice
                  ? q.optionCtrls
                      .map((c) => c.text.trim())
                      .where((s) => s.isNotEmpty)
                      .toList()
                  : null,
            ))
        .toList();

    context.read<OnboardingBloc>().add(SaveOnboardingForm(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          questions: questions,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingFormLoaded && !_loaded) {
          if (state.form != null) {
            setState(() => _populateFromForm(state.form!));
          } else {
            _loaded = true;
          }
        }
        if (state is OnboardingFormLoaded && _loaded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Űrlap mentve!')),
          );
        }
        if (state is OnboardingError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        if (state is OnboardingInitial) {
          context.read<OnboardingBloc>().add(LoadMyOnboardingForm());
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is OnboardingLoading && !_loaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: DT.of(context).bg,
          appBar: AppBar(
            backgroundColor: DT.of(context).bg,
            elevation: 0,
            leading: BackButton(color: DT.of(context).textPrimary),
            title: Text('Felmérő szerkesztő',
                style: TextStyle(
                    color: DT.of(context).textPrimary, fontWeight: FontWeight.w600)),
            centerTitle: true,
            actions: [
              if (state is OnboardingLoading)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                TextButton(
                  onPressed: _save,
                  child: const Text('Mentés',
                      style: TextStyle(color: DT.metricBlue)),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(DT.s4),
            children: [
              _SectionLabel('Általános adatok'),
              const SizedBox(height: DT.s2),
              _Field(controller: _titleCtrl, label: 'Cím *'),
              const SizedBox(height: DT.s3),
              _Field(
                  controller: _descCtrl,
                  label: 'Leírás',
                  maxLines: 3),
              const SizedBox(height: DT.s5),
              _SectionLabel('Kérdések'),
              const SizedBox(height: DT.s2),
              ..._questions.asMap().entries.map((e) {
                return _QuestionCard(
                  key: ValueKey(e.key),
                  index: e.key,
                  draft: e.value,
                  onRemove: () => _removeQuestion(e.key),
                  onChanged: () => setState(() {}),
                );
              }),
              const SizedBox(height: DT.s3),
              OutlinedButton.icon(
                onPressed: _addQuestion,
                icon: const Icon(Icons.add),
                label: const Text('Új kérdés'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DT.metricBlue,
                  side: const BorderSide(color: DT.metricBlue),
                  padding: const EdgeInsets.symmetric(vertical: DT.s3),
                ),
              ),
              const SizedBox(height: DT.s8),
            ],
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
            color: DT.of(context).textSecondary,
            fontSize: DT.s3,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5),
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  const _Field(
      {required this.controller, required this.label, this.maxLines = 1});
  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: DT.of(context).textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: DT.of(context).textSecondary),
          filled: true,
          fillColor: DT.of(context).cardSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.rCardSmall),
            borderSide: BorderSide.none,
          ),
        ),
      );
}

// Question card

class _QuestionDraft {
  String? id;
  final TextEditingController textCtrl;
  QuestionType type;
  List<TextEditingController> optionCtrls;

  _QuestionDraft()
      : textCtrl = TextEditingController(),
        type = QuestionType.text,
        optionCtrls = [TextEditingController(), TextEditingController()];

  factory _QuestionDraft.fromModel(OnboardingQuestion q) {
    final d = _QuestionDraft();
    d.id = q.id;
    d.textCtrl.text = q.text;
    d.type = q.type;
    if (q.options != null && q.options!.isNotEmpty) {
      d.optionCtrls =
          q.options!.map((o) => TextEditingController(text: o)).toList();
    }
    return d;
  }

  void dispose() {
    textCtrl.dispose();
    for (final c in optionCtrls) {
      c.dispose();
    }
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final _QuestionDraft draft;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _QuestionCard({
    super.key,
    required this.index,
    required this.draft,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DT.s3),
      padding: const EdgeInsets.all(DT.s4),
      decoration: BoxDecoration(
        color: DT.of(context).cardSurface,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${index + 1}. kérdés',
                  style: TextStyle(
                      color: DT.of(context).textSecondary, fontSize: DT.s3)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: DT.cardRed),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: DT.s2),
          TextField(
            controller: draft.textCtrl,
            style: TextStyle(color: DT.of(context).textPrimary),
            decoration: InputDecoration(
              hintText: 'Kérdés szövege',
              hintStyle: TextStyle(color: DT.of(context).textSecondary),
              filled: true,
              fillColor: DT.of(context).bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DT.rCardSmall),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: DT.s3),
          Row(
            children: [
              Text('Típus:',
                  style: TextStyle(color: DT.of(context).textSecondary, fontSize: DT.s3)),
              const SizedBox(width: DT.s2),
              _TypeChip(
                label: 'Szöveg',
                selected: draft.type == QuestionType.text,
                onTap: () {
                  draft.type = QuestionType.text;
                  onChanged();
                },
              ),
              const SizedBox(width: DT.s1),
              _TypeChip(
                label: 'Választós',
                selected: draft.type == QuestionType.multipleChoice,
                onTap: () {
                  draft.type = QuestionType.multipleChoice;
                  onChanged();
                },
              ),
              const SizedBox(width: DT.s1),
              _TypeChip(
                label: 'Skála',
                selected: draft.type == QuestionType.scale,
                onTap: () {
                  draft.type = QuestionType.scale;
                  onChanged();
                },
              ),
            ],
          ),
          if (draft.type == QuestionType.multipleChoice) ...[
            const SizedBox(height: DT.s3),
            Text('Lehetőségek:',
                style: TextStyle(color: DT.of(context).textSecondary, fontSize: DT.s3)),
            const SizedBox(height: DT.s2),
            ...draft.optionCtrls.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: DT.s2),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: e.value,
                        style: TextStyle(color: DT.of(context).textPrimary),
                        decoration: InputDecoration(
                          hintText: '${e.key + 1}. lehetőség',
                          hintStyle:
                              TextStyle(color: DT.of(context).textSecondary),
                          filled: true,
                          fillColor: DT.of(context).bg,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(DT.rCardSmall),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    if (draft.optionCtrls.length > 2)
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline,
                            color: DT.of(context).textSecondary, size: 18),
                        onPressed: () {
                          draft.optionCtrls.removeAt(e.key);
                          onChanged();
                        },
                      ),
                  ],
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                draft.optionCtrls.add(TextEditingController());
                onChanged();
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Lehetőség hozzáadása'),
              style: TextButton.styleFrom(
                foregroundColor: DT.metricBlue,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
          if (draft.type == QuestionType.scale) ...[
            const SizedBox(height: DT.s2),
            Text('1–10 skálán kell értékelni.',
                style: TextStyle(color: DT.of(context).textSecondary, fontSize: DT.s3)),
          ],
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: DT.s2, vertical: DT.s1),
        decoration: BoxDecoration(
          color: selected ? DT.metricBlue : DT.of(context).bg,
          borderRadius: BorderRadius.circular(DT.rCardSmall),
          border:
              Border.all(color: selected ? DT.metricBlue : DT.of(context).borderGrey),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: selected ? Colors.white : DT.of(context).textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
