class EvaluationQuestion {
  final String id;
  final String type; // star/text
  final String label;
  final int order;

  EvaluationQuestion({
    this.id = '',
    required this.type,
    required this.label,
    this.order = 0,
  });

  factory EvaluationQuestion.fromJson(Map<String, dynamic> json) {
    return EvaluationQuestion(
      id: json['id'] ?? '',
      type: json['type'] ?? 'text',
      label: json['label'] ?? '',
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'label': label,
    'order': order,
  };

  EvaluationQuestion copyWith({String? type, String? label}) {
    return EvaluationQuestion(
      id: id,
      type: type ?? this.type,
      label: label ?? this.label,
      order: order,
    );
  }
}

class EvaluationForm {
  final String id;
  final String activityId;
  final List<EvaluationQuestion> questions;

  EvaluationForm({
    this.id = '',
    this.activityId = '',
    this.questions = const [],
  });

  factory EvaluationForm.fromJson(Map<String, dynamic> json) {
    return EvaluationForm(
      id: json['id'] ?? '',
      activityId: json['activity_id']?.toString() ?? '',
      questions: (json['questions'] as List?)
              ?.map((q) => EvaluationQuestion.fromJson(q))
              .toList() ??
          [],
    );
  }
}

class EvaluationAnswer {
  final String questionId;
  final String type; // star/text
  final int? starValue;
  final String textValue;

  EvaluationAnswer({
    required this.questionId,
    required this.type,
    this.starValue,
    this.textValue = '',
  });

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'type': type,
    if (starValue != null) 'star_value': starValue,
    'text_value': textValue,
  };
}

enum EvaluationSubmitResult { success, alreadySubmitted, error }
