import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/activity_service.dart';

class CalendarSection extends StatefulWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateSelected;
  // ถ้าส่ง eventDates มา จะใช้แทนการดึงจาก ActivityService
  final List<DateTime>? eventDates;

  const CalendarSection({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.eventDates,
  });

  @override
  State<CalendarSection> createState() => _CalendarSectionState();
}

class _CalendarSectionState extends State<CalendarSection> {
  DateTime _calendarMonth = DateTime.now();

  static const _thaiMonths = [
    '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
  ];
  static const _dayHeaders = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];

  Set<int> _eventDaysInMonth(DateTime month) {
    final dates = widget.eventDates ??
        context.read<ActivityService>().activities.map((a) => a.startAt).toList();
    return dates
        .where((d) => d.year == month.year && d.month == month.month)
        .map((d) => d.day)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final year = _calendarMonth.year;
    final month = _calendarMonth.month;
    final thaiYear = year + 543;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday;
    final eventDays = _eventDaysInMonth(_calendarMonth);
    final today = DateTime.now();
    final totalCells = ((firstWeekday - 1 + daysInMonth + 6) ~/ 7) * 7;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Month nav
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => setState(() {
                    _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1);
                  }),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE8ECF0)),
                    ),
                    child: const Icon(Icons.chevron_left_rounded, size: 20, color: Color(0xFF374151)),
                  ),
                ),
                Text(
                  '${_thaiMonths[month]} $thaiYear',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                GestureDetector(
                  onTap: () => setState(() {
                    _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1);
                  }),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE8ECF0)),
                    ),
                    child: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF374151)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Day headers
            Row(
              children: _dayHeaders.map((d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: d == 'ส' || d == 'อา' ? const Color(0xFFEF4444) : Colors.grey.shade500,
                    ),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 6),

            // Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                childAspectRatio: 1,
              ),
              itemCount: totalCells,
              itemBuilder: (context, index) {
                final dayOffset = index - (firstWeekday - 1);
                if (dayOffset < 0 || dayOffset >= daysInMonth) return const SizedBox();
                final day = dayOffset + 1;
                final hasEvent = eventDays.contains(day);
                final isToday = today.year == year && today.month == month && today.day == day;
                final isSelected = widget.selectedDate != null &&
                    widget.selectedDate!.year == year &&
                    widget.selectedDate!.month == month &&
                    widget.selectedDate!.day == day;

                return GestureDetector(
                  onTap: () => widget.onDateSelected(
                    isSelected ? null : DateTime(year, month, day),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : isToday
                          ? AppTheme.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: hasEvent || isToday ? FontWeight.w700 : FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                ? AppTheme.primary
                                : AppTheme.textPrimary,
                          ),
                        ),
                        if (hasEvent) ...[
                          const SizedBox(height: 1),
                          Container(
                            width: 5, height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? Colors.white : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
