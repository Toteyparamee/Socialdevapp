import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/problem_report.dart';

class ProblemBottomSheet extends StatelessWidget {
  final ProblemReport problem;
  final VoidCallback onExpand;

  const ProblemBottomSheet({
    super.key,
    required this.problem,
    required this.onExpand,
  });

  Color get _statusColor {
    switch (problem.status) {
      case ProblemStatus.pending:
        return AppTheme.statusPending;
      case ProblemStatus.inProgress:
        return AppTheme.statusInProgress;
      case ProblemStatus.resolved:
        return AppTheme.statusResolved;
    }
  }

  Color get _sourceColor {
    switch (problem.source) {
      case ProblemSource.user:
        return AppTheme.markerUser;
      case ProblemSource.government:
        return AppTheme.markerGov;
      case ProblemSource.urgent:
        return AppTheme.markerUrgent;
    }
  }

  IconData get _categoryIcon {
    switch (problem.category) {
      case ProblemCategory.flood:
        return Icons.water_drop_outlined;
      case ProblemCategory.trash:
        return Icons.delete_outline;
      case ProblemCategory.traffic:
        return Icons.traffic_outlined;
      case ProblemCategory.infrastructure:
        return Icons.construction_outlined;
      case ProblemCategory.other:
        return Icons.report_outlined;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
    return '${diff.inDays} วันที่แล้ว';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onExpand,
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < -200) {
          onExpand();
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.radiusLg,
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      // Category icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _sourceColor.withValues(alpha: 0.1),
                          borderRadius: AppTheme.radiusMd,
                        ),
                        child: Icon(_categoryIcon, color: _sourceColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      // Title & address
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              problem.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              problem.address,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Description preview
                  Text(
                    problem.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  // Badges row
                  Row(
                    children: [
                      _buildBadge(problem.statusLabel, _statusColor),
                      const SizedBox(width: 8),
                      _buildBadge(problem.sourceLabel, _sourceColor),
                      const Spacer(),
                      Icon(Icons.access_time,
                          size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        _timeAgo(problem.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Expand hint
                  Center(
                    child: Text(
                      'เลื่อนขึ้นเพื่อดูรายละเอียด',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
