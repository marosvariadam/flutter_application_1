import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:flutter_application_1/features/onboarding/data/models/onboarding_models.dart';

class AthleteSurveyPage extends StatefulWidget {
  const AthleteSurveyPage({super.key});

  @override
  State<AthleteSurveyPage> createState() => _AthleteSurveyPageState();
}

class _AthleteSurveyPageState extends State<AthleteSurveyPage> {
  // answers keyed by questionId
  final Map<String, String> _answers = {};
  bool _loaded = false;
  bool _submitted = false;

  void _submit(OnboardingFormModel form) {
    // Check all questions answered
    for (final q in form.questions) {
      if (!_answers.containsKey(q.id) || _answers[q.id]!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Kérjük, válaszolj minden kérdésre!')),
        );
        return;
      }
    }
    final answers = _answers.entries
        .map((e) => OnboardingAnswer(questionId: e.key, answer: e.value))
        .toList();
    context.read<OnboardingBloc>().add(SubmitSurveyAnswers(answers));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingSuccess) {
          setState(() => _submitted = true);
        }
        if (state is OnboardingError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        if (state is OnboardingInitial) {
          context.read<OnboardingBloc>().add(LoadMyTrainerForm());
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is OnboardingLoading && !_loaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is OnboardingError && !_loaded) {
          return Scaffold(
            backgroundColor: DT.bg,
            appBar: AppBar(
              backgroundColor: DT.bg,
              elevation: 0,
              leading: BackButton(color: DT.textPrimary),
              title: const Text('Felmérő',
                  style: TextStyle(
                      color: DT.textPrimary,
                      fontWeight: FontWeight.w600)),
              centerTitle: true,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment_outlined,
                      size: 64, color: DT.iconLightGrey),
                  const SizedBox(height: DT.s4),
                  Text(state.message,
                      style: const TextStyle(
                          color: DT.textSecondary, fontSize: DT.s4),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }

        OnboardingFormModel? form;
        if (state is OnboardingFormLoaded) {
          form = state.form;
          _loaded = true;
        }
        // Keep form in view even after submit triggers Loading
        if (form == null && !_submitted) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (_submitted) {
          return Scaffold(
            backgroundColor: DT.bg,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(DT.s6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: DT.s5),
                    const Text(
                      'Felmérő elküldve!',
                      style: TextStyle(
                          color: DT.textPrimary,
                          fontSize: DT.s5,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: DT.s3),
                    const Text(
                      'Köszönjük, hogy kitöltötted az edzői felmérőt. Hamarosan felvesszük veled a kapcsolatot.',
                      style: TextStyle(
                          color: DT.textSecondary, fontSize: DT.s3),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DT.s6),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Vissza'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: DT.bg,
          appBar: AppBar(
            backgroundColor: DT.bg,
            elevation: 0,
            leading: BackButton(color: DT.textPrimary),
            title: Text(
              form!.title,
              style: const TextStyle(
                  color: DT.textPrimary, fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.all(DT.s4),
            children: [
              if (form.description != null && form.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: DT.s5),
                  child: Text(
                    form.description!,
                    style: const TextStyle(
                        color: DT.textSecondary, fontSize: DT.s3),
                  ),
                ),
              ...form.questions.asMap().entries.map((e) {
                final q = e.value;
                return _QuestionWidget(
                  key: ValueKey(q.id),
                  index: e.key,
                  question: q,
                  currentAnswer: _answers[q.id],
                  onAnswered: (answer) =>
                      setState(() => _answers[q.id] = answer),
                );
              }),
              const SizedBox(height: DT.s5),
              ElevatedButton(
                onPressed: state is OnboardingLoading
                    ? null
                    : () => _submit(form!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DT.metricBlue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: DT.s4),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(DT.rCardSmall),
                  ),
                ),
                child: state is OnboardingLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Felmérő beküldése',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: DT.s8),
            ],
          ),
        );
      },
    );
  }
}

// ── Question widgets ──────────────────────────────────────────────────────────

class _QuestionWidget extends StatelessWidget {
  final int index;
  final OnboardingQuestion question;
  final String? currentAnswer;
  final ValueChanged<String> onAnswered;

  const _QuestionWidget({
    super.key,
    required this.index,
    required this.question,
    required this.currentAnswer,
    required this.onAnswered,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DT.s4),
      padding: const EdgeInsets.all(DT.s4),
      decoration: BoxDecoration(
        color: DT.gbWhite,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}. ${question.text}',
            style: const TextStyle(
                color: DT.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: DT.s3),
          ),
          const SizedBox(height: DT.s3),
          switch (question.type) {
            QuestionType.text => _TextAnswer(
                current: currentAnswer,
                onChanged: onAnswered,
              ),
            QuestionType.multipleChoice => _MultipleChoiceAnswer(
                options: question.options ?? [],
                current: currentAnswer,
                onChanged: onAnswered,
              ),
            QuestionType.scale => _ScaleAnswer(
                current: currentAnswer,
                onChanged: onAnswered,
              ),
          },
        ],
      ),
    );
  }
}

class _TextAnswer extends StatelessWidget {
  final String? current;
  final ValueChanged<String> onChanged;
  const _TextAnswer({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController(text: current);
    return TextField(
      controller: ctrl,
      maxLines: 3,
      onChanged: onChanged,
      style: const TextStyle(color: DT.textPrimary),
      decoration: InputDecoration(
        hintText: 'Írd be a válaszod...',
        hintStyle: const TextStyle(color: DT.textSecondary),
        filled: true,
        fillColor: DT.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DT.rCardSmall),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _MultipleChoiceAnswer extends StatelessWidget {
  final List<String> options;
  final String? current;
  final ValueChanged<String> onChanged;
  const _MultipleChoiceAnswer(
      {required this.options,
      required this.current,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options
          .map(
            (o) => RadioListTile<String>(
              value: o,
              groupValue: current,
              onChanged: (v) => onChanged(v ?? o),
              title: Text(o,
                  style: const TextStyle(color: DT.textPrimary, fontSize: DT.s3)),
              activeColor: DT.metricBlue,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          )
          .toList(),
    );
  }
}

class _ScaleAnswer extends StatelessWidget {
  final String? current;
  final ValueChanged<String> onChanged;
  const _ScaleAnswer({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final selected = current != null ? int.tryParse(current!) : null;
    return Wrap(
      spacing: DT.s2,
      runSpacing: DT.s2,
      children: List.generate(10, (i) {
        final value = i + 1;
        final isSelected = selected == value;
        return GestureDetector(
          onTap: () => onChanged(value.toString()),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected ? DT.metricBlue : DT.bg,
              borderRadius: BorderRadius.circular(DT.rCardSmall),
              border: Border.all(
                  color: isSelected ? DT.metricBlue : DT.borderGrey),
            ),
            child: Center(
              child: Text(
                value.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : DT.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
