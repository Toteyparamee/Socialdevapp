import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/problem_report.dart';

class ProblemDetailScreen extends StatelessWidget {
  final ProblemReport problem;

  const ProblemDetailScreen({super.key, required this.problem});

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
        return Icons.water_drop;
      case ProblemCategory.trash:
        return Icons.delete;
      case ProblemCategory.traffic:
        return Icons.traffic;
      case ProblemCategory.infrastructure:
        return Icons.construction;
      case ProblemCategory.other:
        return Icons.report;
    }
  }

  String _formatDate(DateTime dt) {
    final months = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year + 543} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} น.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Hero image
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppTheme.primary,
            leading: _buildBackButton(context),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Placeholder image
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _sourceColor.withValues(alpha: 0.3),
                          _sourceColor.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: Icon(
                      _categoryIcon,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  // Bottom gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Row(
                    children: [
                      _buildBadge(problem.categoryLabel, _sourceColor),
                      const SizedBox(width: 8),
                      _buildBadge(problem.statusLabel, _statusColor),
                      const SizedBox(width: 8),
                      _buildBadge(problem.sourceLabel, _sourceColor),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    problem.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Address
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          problem.address,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Divider
                  const Divider(color: AppTheme.border),
                  const SizedBox(height: 16),

                  // Description header
                  const Text(
                    'รายละเอียด',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    problem.description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info cards
                  _buildInfoCard(
                    icon: Icons.person_outline,
                    label: 'แจ้งโดย',
                    value: problem.reportedBy,
                  ),
                  const SizedBox(height: 10),
                  _buildInfoCard(
                    icon: Icons.access_time,
                    label: 'วันที่แจ้ง',
                    value: _formatDate(problem.createdAt),
                  ),
                  const SizedBox(height: 10),
                  _buildInfoCard(
                    icon: Icons.gps_fixed,
                    label: 'พิกัด',
                    value:
                        '${problem.location.latitude.toStringAsFixed(4)}, ${problem.location.longitude.toStringAsFixed(4)}',
                  ),
                  const SizedBox(height: 32),

                  // Status timeline
                  _buildStatusTimeline(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.inputBg,
        borderRadius: AppTheme.radiusMd,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final steps = [
      _TimelineStep('แจ้งปัญหา', true),
      _TimelineStep('รับเรื่อง', problem.status != ProblemStatus.pending),
      _TimelineStep(
          'กำลังดำเนินการ', problem.status == ProblemStatus.inProgress || problem.status == ProblemStatus.resolved),
      _TimelineStep('แก้ไขแล้ว', problem.status == ProblemStatus.resolved),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'สถานะการดำเนินการ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(steps.length, (i) {
          final step = steps[i];
          final isLast = i == steps.length - 1;
          return IntrinsicHeight(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: step.completed
                            ? AppTheme.statusResolved
                            : AppTheme.border,
                        shape: BoxShape.circle,
                      ),
                      child: step.completed
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: step.completed
                              ? AppTheme.statusResolved
                              : AppTheme.border,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    step.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          step.completed ? FontWeight.w600 : FontWeight.w400,
                      color: step.completed
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _TimelineStep {
  final String label;
  final bool completed;
  _TimelineStep(this.label, this.completed);
}
