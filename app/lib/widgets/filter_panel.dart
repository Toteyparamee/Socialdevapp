import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/problem_report.dart';

class FilterPanel extends StatefulWidget {
  final Set<ProblemCategory> activeFilters;
  final ValueChanged<Set<ProblemCategory>> onChanged;

  const FilterPanel({
    super.key,
    required this.activeFilters,
    required this.onChanged,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late Set<ProblemCategory> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.activeFilters);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'กรองประเภทปัญหา',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_selected.length == ProblemCategory.values.length) {
                      _selected.clear();
                    } else {
                      _selected = ProblemCategory.values.toSet();
                    }
                  });
                },
                child: Text(
                  _selected.length == ProblemCategory.values.length
                      ? 'ยกเลิกทั้งหมด'
                      : 'เลือกทั้งหมด',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Filter chips
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ProblemCategory.values.map((cat) {
              final isActive = _selected.contains(cat);
              final label = switch (cat) {
                ProblemCategory.flood => 'น้ำท่วม',
                ProblemCategory.trash => 'ขยะ',
                ProblemCategory.traffic => 'การจราจร',
                ProblemCategory.infrastructure => 'โครงสร้างพื้นฐาน',
                ProblemCategory.other => 'อื่นๆ',
              };
              final icon = switch (cat) {
                ProblemCategory.flood => Icons.water_drop_outlined,
                ProblemCategory.trash => Icons.delete_outline,
                ProblemCategory.traffic => Icons.traffic_outlined,
                ProblemCategory.infrastructure => Icons.construction_outlined,
                ProblemCategory.other => Icons.more_horiz,
              };
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isActive) {
                      _selected.remove(cat);
                    } else {
                      _selected.add(cat);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primary.withValues(alpha: 0.1)
                        : AppTheme.inputBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isActive ? AppTheme.primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: isActive
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          // Apply button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => widget.onChanged(_selected),
              child: const Text('ใช้ตัวกรอง'),
            ),
          ),
        ],
      ),
    );
  }
}
