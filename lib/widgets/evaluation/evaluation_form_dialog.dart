import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/evaluation.dart';
import '../../services/activity_service.dart';
import 'star_rating_input.dart';

class EvaluationFormDialog extends StatefulWidget {
  final String activityId;
  final String registrationId;
  final List<EvaluationQuestion> questions;

  const EvaluationFormDialog({
    super.key,
    required this.activityId,
    required this.registrationId,
    required this.questions,
  });

  @override
  State<EvaluationFormDialog> createState() => _EvaluationFormDialogState();
}

class _EvaluationFormDialogState extends State<EvaluationFormDialog> {
  final Map<String, int> _starValues = {};
  final Map<String, TextEditingController> _textControllers = {};
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    for (final q in widget.questions) {
      if (q.type == 'text') {
        _textControllers[q.id] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSending = true);
    final answers = widget.questions.map((q) {
      if (q.type == 'star') {
        return EvaluationAnswer(
          questionId: q.id,
          type: 'star',
          starValue: _starValues[q.id] ?? 0,
        );
      }
      return EvaluationAnswer(
        questionId: q.id,
        type: 'text',
        textValue: _textControllers[q.id]?.text.trim() ?? '',
      );
    }).toList();

    final result = await context
        .read<ActivityService>()
        .submitEvaluationResponse(
          widget.activityId,
          registrationId: widget.registrationId,
          answers: answers,
        );

    if (!mounted) return;
    if (result == EvaluationSubmitResult.error) {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ส่งแบบประเมินไม่สำเร็จ')),
      );
      return;
    }
    Navigator.pop(context);
    if (result == EvaluationSubmitResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ขอบคุณสำหรับการประเมิน'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const Text(
                  'แบบประเมินผลกิจกรรม',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ช่วยประเมินกิจกรรมนี้เพื่อการพัฒนาที่ดีขึ้น (ไม่บังคับ)',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 20),
                ...widget.questions.map((q) => _buildQuestion(q)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSending
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('ข้าม'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSending ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'ส่ง',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion(EvaluationQuestion q) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (q.type == 'star')
            StarRatingInput(
              value: _starValues[q.id] ?? 0,
              onChanged: (v) => setState(() => _starValues[q.id] = v),
            )
          else
            TextField(
              controller: _textControllers[q.id],
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'พิมพ์ความคิดเห็น...',
                filled: true,
                fillColor: AppTheme.inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
