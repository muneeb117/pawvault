import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';

class CareCalendarPage extends StatefulWidget {
  const CareCalendarPage({super.key});

  @override
  State<CareCalendarPage> createState() => _CareCalendarPageState();
}

class _CareCalendarPageState extends State<CareCalendarPage> {
  DateTime _displayedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selected = DateTime.now();

  late final Map<int, List<Color>> _events = {
    1: [AppColors.rose500],
    8: [AppColors.sage500],
    12: [AppColors.rose500, AppColors.ochre500],
    DateTime.now().day: [AppColors.rose500, AppColors.sage500, AppColors.ochre500],
    18: [AppColors.sage500],
    22: [AppColors.clay500],
    27: [AppColors.clay500, AppColors.rose500],
    30: [AppColors.sage500],
  };

  static const _weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _monthNames = ['January','February','March','April','May','June',
    'July','August','September','October','November','December'];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isToday = _selected.year == today.year && _selected.month == today.month && _selected.day == today.day;

    return Scaffold(
      backgroundColor: AppColors.bone,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BISCUIT',
                            style: GoogleFonts.notoSans(
                                fontSize: 10, fontWeight: FontWeight.w600,
                                color: AppColors.stone2, letterSpacing: 0.08 * 10)),
                        Text('Care',
                            style: GoogleFonts.bricolageGrotesque(
                                fontSize: 22, fontWeight: FontWeight.w600,
                                color: AppColors.ink, letterSpacing: -0.5)),
                      ],
                    ),
                    const Spacer(),
                    _IconBtn(child: const Icon(Icons.add_rounded, size: 18, color: AppColors.ink)),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _IconBtn(
                      onTap: () => setState(() => _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1)),
                      child: const Icon(Icons.chevron_left_rounded, size: 20, color: AppColors.ink),
                    ),
                    Text('${_monthNames[_displayedMonth.month - 1]} ${_displayedMonth.year}',
                        style: GoogleFonts.bricolageGrotesque(
                            fontSize: 22, fontWeight: FontWeight.w600,
                            color: AppColors.ink, letterSpacing: -0.5)),
                    _IconBtn(
                      onTap: () => setState(() => _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1)),
                      child: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: _weekdayLabels.map((d) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(d,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSans(
                              fontSize: 10, fontWeight: FontWeight.w600,
                              color: AppColors.stone2, letterSpacing: 0.08 * 10)),
                    ),
                  )).toList(),
                ),
              ),
            ),

            SliverToBoxAdapter(child: _buildDayGrid(today)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isToday
                                  ? 'TODAY · ${_monthNames[_selected.month - 1].substring(0, 3).toUpperCase()} ${_selected.day}'
                                  : '${_monthNames[_selected.month - 1].substring(0, 3).toUpperCase()} ${_selected.day}',
                              style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 12, fontWeight: FontWeight.w500,
                                  letterSpacing: 0.06 * 12, color: AppColors.clay500),
                            ),
                            const SizedBox(height: 2),
                            Text('4 events · 2 done',
                                style: GoogleFonts.bricolageGrotesque(
                                    fontSize: 22, fontWeight: FontWeight.w600,
                                    color: AppColors.ink, letterSpacing: -0.6, height: 1)),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 52, height: 52,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const SizedBox(
                              width: 52, height: 52,
                              child: CircularProgressIndicator(
                                value: 0.5,
                                backgroundColor: AppColors.line,
                                valueColor: AlwaysStoppedAnimation(AppColors.clay500),
                                strokeWidth: 4,
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Text('50%',
                                style: GoogleFonts.notoSans(
                                    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text('SCHEDULE',
                    style: GoogleFonts.bricolageGrotesque(
                        fontSize: 12, fontWeight: FontWeight.w500,
                        letterSpacing: 0.06 * 12, color: AppColors.stone)),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _ScheduleRow(item: _schedule[i]),
                  childCount: _schedule.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayGrid(DateTime today) {
    final firstDay = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_displayedMonth.year, _displayedMonth.month);
    final leadingBlanks = firstDay.weekday % 7;

    final cells = <Widget>[];
    for (int i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_displayedMonth.year, _displayedMonth.month, d);
      final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
      final isSelected = date.year == _selected.year && date.month == _selected.month && date.day == _selected.day;
      final dayEvents = _events[d] ?? const <Color>[];

      cells.add(GestureDetector(
        onTap: () => setState(() => _selected = date),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.ink : (isToday ? AppColors.surface : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: !isSelected && isToday ? Border.all(color: AppColors.border) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$d',
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    fontWeight: isToday || isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.bone : AppColors.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
              if (dayEvents.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: dayEvents.take(3).map((c) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Container(
                      width: 4, height: 4,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.clay200 : c,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 4, mainAxisSpacing: 4,
        children: cells,
      ),
    );
  }

  static final _schedule = [
    _ScheduleItem('8:00 AM', 'Heartgard Plus', 'Medication',
        Icons.medication_outlined, AppColors.rose500, AppColors.rose50, true),
    _ScheduleItem('9:30 AM', 'Morning walk', 'Activity',
        Icons.directions_walk_rounded, AppColors.sage500, AppColors.sage50, true),
    _ScheduleItem('1:00 PM', 'Lunch', 'Meal',
        Icons.restaurant_outlined, AppColors.ochre500, AppColors.ochre50, false),
    _ScheduleItem('6:00 PM', 'Cosequin DS', 'Medication',
        Icons.medication_outlined, AppColors.rose500, AppColors.rose50, false),
  ];
}

class _ScheduleItem {
  final String time, title, kind;
  final IconData icon;
  final Color accent, tint;
  final bool done;
  _ScheduleItem(this.time, this.title, this.kind, this.icon, this.accent, this.tint, this.done);
}

class _ScheduleRow extends StatelessWidget {
  final _ScheduleItem item;
  const _ScheduleRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: IntrinsicHeight(
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.time.split(' ')[0],
                      style: GoogleFonts.notoSans(
                          fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.stone)),
                  Text(item.time.split(' ').length > 1 ? item.time.split(' ')[1] : '',
                      style: GoogleFonts.notoSans(fontSize: 10, color: AppColors.stone2)),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 2,
              decoration: BoxDecoration(
                color: item.done ? item.accent.withValues(alpha: 0.35) : item.accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: item.done ? AppColors.neutral100 : item.tint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, size: 16,
                          color: item.done ? AppColors.stone2 : item.accent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title,
                              style: GoogleFonts.notoSans(
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: item.done ? AppColors.stone : AppColors.ink,
                                decoration: item.done ? TextDecoration.lineThrough : null,
                                decorationColor: AppColors.stone,
                              )),
                          Text('${item.time} · ${item.kind}',
                              style: GoogleFonts.notoSans(fontSize: 11, color: AppColors.stone2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideX(begin: 0.05, end: 0);
  }
}

class _IconBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _IconBtn({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(child: child),
      ),
    );
  }
}
