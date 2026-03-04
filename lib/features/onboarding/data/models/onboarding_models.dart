enum QuestionType { text, multipleChoice, scale }

extension QuestionTypeX on QuestionType {
  String get apiValue {
    switch (this) {
      case QuestionType.text:
        return 'Text';
      case QuestionType.multipleChoice:
        return 'MultipleChoice';
      case QuestionType.scale:
        return 'Scale';
    }
  }

  static QuestionType fromString(String s) {
    switch (s.toLowerCase()) {
      case 'multiplechoice':
        return QuestionType.multipleChoice;
      case 'scale':
        return QuestionType.scale;
      default:
        return QuestionType.text;
    }
  }
}

class OnboardingQuestion {
  final String id;
  final String text;
  final QuestionType type;
  final List<String>? options; // Only for multipleChoice

  const OnboardingQuestion({
    required this.id,
    required this.text,
    required this.type,
    this.options,
  });

  factory OnboardingQuestion.fromJson(Map<String, dynamic> j) =>
      OnboardingQuestion(
        id: j['id'] as String,
        text: j['text'] as String,
        type: QuestionTypeX.fromString(j['type'] as String),
        options: (j['options'] as List?)?.cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'type': type.apiValue,
        if (options != null) 'options': options,
      };
}

class OnboardingFormModel {
  final String id;
  final String title;
  final String? description;
  final List<OnboardingQuestion> questions;

  const OnboardingFormModel({
    required this.id,
    required this.title,
    this.description,
    required this.questions,
  });

  factory OnboardingFormModel.fromJson(Map<String, dynamic> j) =>
      OnboardingFormModel(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        questions: (j['questions'] as List)
            .map((e) =>
                OnboardingQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class OnboardingAnswer {
  final String questionId;
  final String answer;

  const OnboardingAnswer({required this.questionId, required this.answer});

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'answer': answer,
      };
}

class OnboardingResponse {
  final String athleteId;
  final String? athleteName;
  final List<OnboardingAnswer> answers;
  final DateTime submittedAt;

  const OnboardingResponse({
    required this.athleteId,
    this.athleteName,
    required this.answers,
    required this.submittedAt,
  });

  factory OnboardingResponse.fromJson(Map<String, dynamic> j) =>
      OnboardingResponse(
        athleteId: j['athleteId'] as String,
        athleteName: j['athleteName'] as String?,
        answers: (j['answers'] as List)
            .map((e) {
              final m = e as Map<String, dynamic>;
              return OnboardingAnswer(
                questionId: m['questionId'] as String,
                answer: m['answer'] as String,
              );
            })
            .toList(),
        submittedAt: DateTime.parse(j['submittedAt'] as String),
      );
}
