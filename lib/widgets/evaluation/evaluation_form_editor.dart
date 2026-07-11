import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/evaluation.dart';
import 'evaluation_question_editor_tile.dart';

/// Inline widget (usable by both ครู and หน่วยงาน) that lets the creator
/// turn the "แบบประเมินกิจกรรม" on/off and edit its questions in place,
/// without navigating to a separate screen.
class EvaluationFormEditor extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;
  final List<EvaluationQuestion> questions;
  final ValueChanged<List<EvaluationQuestion>> onQuestionsChanged;

  const EvaluationFormEditor({
    super.key,
    required this.enabled,
    required this.onEnabledChanged,
    required this.questions,
    required this.onQuestionsChanged,
  });

  void _addQuestion() {
    onQuestionsChanged([
      ...questions,
      EvaluationQuestion(type: 'star', label: ''),
    ]);
  }

  void _updateLabel(int index, String label) {
    final list = List.of(questions);
    list[index] = list[index].copyWith(label: label);
    onQuestionsChanged(list);
  }

  void _updateType(int index, String type) {
    final list = List.of(questions);
    list[index] = list[index].copyWith(type: type);
    onQuestionsChanged(list);
  }

  void _deleteQuestion(int index) {
    final list = List.of(questions)..removeAt(index);
    onQuestionsChanged(list);
  }

  void _moveQuestion(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= questions.length) return;
    final list = List.of(questions);
    final item = list.removeAt(index);
    list.insert(target, item);
    onQuestionsChanged(list);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'แบบประเมินกิจกรรม',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: enabled,
                activeThumbColor: AppTheme.primary,
                onChanged: onEnabledChanged,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 8),
            Text(
              'กำหนดคำถามสำหรับให้นักเรียนประเมินหลังส่งงาน (ไม่บังคับตอบ)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 12),
            if (questions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'ยังไม่มีคำถาม กดเพิ่มคำถามด้านล่าง',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
            else
              ...List.generate(questions.length, (i) {
                return EvaluationQuestionEditorTile(
                  question: questions[i],
                  onLabelChanged: (v) => _updateLabel(i, v),
                  onTypeChanged: (v) => _updateType(i, v),
                  onDelete: () => _deleteQuestion(i),
                  onMoveUp: i > 0 ? () => _moveQuestion(i, -1) : null,
                  onMoveDown: i < questions.length - 1
                      ? () => _moveQuestion(i, 1)
                      : null,
                );
              }),
            OutlinedButton.icon(
              onPressed: _addQuestion,
              icon: const Icon(Icons.add_rounded),
              label: const Text('เพิ่มคำถาม'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
