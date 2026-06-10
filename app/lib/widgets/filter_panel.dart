import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MapFilter {
  final bool showProblems;
  final bool showActivities;

  const MapFilter({
    this.showProblems = true,
    this.showActivities = true,
  });

  MapFilter copyWith({bool? showProblems, bool? showActivities}) {
    return MapFilter(
      showProblems: showProblems ?? this.showProblems,
      showActivities: showActivities ?? this.showActivities,
    );
  }
}

class FilterPanel extends StatefulWidget {
  final MapFilter current;
  final ValueChanged<MapFilter> onChanged;

  const FilterPanel({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late MapFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'แสดงบนแผนที่',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildToggleTile(
            icon: Icons.report_problem_outlined,
            color: Colors.red.shade600,
            label: 'ปัญหาในชุมชน',
            subtitle: 'แสดง marker ปัญหาทั่วไป',
            value: _filter.showProblems,
            onChanged: (v) => setState(() => _filter = _filter.copyWith(showProblems: v)),
          ),
          const SizedBox(height: 12),
          _buildToggleTile(
            icon: Icons.school_rounded,
            color: const Color(0xFF6C63FF),
            label: 'กิจกรรมโรงเรียน',
            subtitle: 'แสดง marker กิจกรรมของโรงเรียน',
            value: _filter.showActivities,
            onChanged: (v) => setState(() => _filter = _filter.copyWith(showActivities: v)),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => widget.onChanged(_filter),
              child: const Text('ใช้ตัวกรอง'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required Color color,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: value ? color.withValues(alpha: 0.06) : AppTheme.inputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? color.withValues(alpha: 0.4) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: color,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: value ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
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
}
