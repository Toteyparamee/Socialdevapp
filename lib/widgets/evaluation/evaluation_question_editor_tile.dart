import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/evaluation.dart';

class EvaluationQuestionEditorTile extends StatelessWidget {
  final EvaluationQuestion question;
  final ValueChanged<String> onLabelChanged;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const EvaluationQuestionEditorTile({
    super.key,
    required this.question,
    required this.onLabelChanged,
    required this.onTypeChanged,
    required this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: question.label,
                  onChanged: onLabelChanged,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'พิมพ์คำถาม...',
                    filled: true,
                    fillColor: AppTheme.inputBg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 20),
                color: const Color(0xFFEF4444),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildTypeChip(
                label: 'ให้คะแนนดาว',
                icon: Icons.star_rounded,
                selected: question.type == 'star',
                onTap: () => onTypeChanged('star'),
              ),
              const SizedBox(width: 8),
              _buildTypeChip(
                label: 'ข้อความ',
                icon: Icons.short_text_rounded,
                selected: question.type == 'text',
                onTap: () => onTypeChanged('text'),
              ),
              const Spacer(),
              if (onMoveUp != null)
                IconButton(
                  onPressed: onMoveUp,
                  icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 20),
                  color: AppTheme.textSecondary,
                  visualDensity: VisualDensity.compact,
                ),
              if (onMoveDown != null)
                IconButton(
                  onPressed: onMoveDown,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                  ),
                  color: AppTheme.textSecondary,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : AppTheme.inputBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? AppTheme.primary : AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
