import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/pet_model.dart';
import '../../../data/models/vaccine_model.dart';
import '../../../data/models/medication_model.dart';
import '../../../data/repositories/vaccine_repository.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../shared/widgets/pet_switcher.dart';
import '../../pets/cubit/active_pet_cubit.dart';

enum _EventKind { vaccine, medication }

class _CareEvent {
  final _EventKind kind;
  final DateTime at;
  final String title;
  final String subtitle;
  const _CareEvent({
    required this.kind,
    required this.at,
    required this.title,
    required this.subtitle,
  });

  Color get accent => switch (kind) {
        _EventKind.vaccine    => AppColors.clay500,
        _EventKind.medication => AppColors.rose500,
      };
  Color get tint => switch (kind) {
        _EventKind.vaccine    => AppColors.clay50,
        _EventKind.medication => AppColors.rose50,
      };
  IconData get icon => switch (kind) {
        _EventKind.vaccine    => LucideIcons.syringe,
        _EventKind.medication => LucideIcons.pill,
      };
}

class CareCalendarPage extends StatefulWidget {
  const CareCalendarPage({super.key});

  @override
  State<CareCalendarPage> createState() => _CareCalendarPageState();
}

class _CareCalendarPageState extends State<CareCalendarPage> {
  DateTime _displayedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selected = DateTime.now();

  String? _loadedPetId;
  bool _loading = true;
  final List<_CareEvent> _events = [];

  static const _weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _monthNames = ['January','February','March','April','May','June',
    'July','August','September','October','November','December'];

  Future<void> _loadEvents(Pet pet) async {
    if (_loadedPetId == pet.id && !_loading) return;
    setState(() {
      _loading = true;
      _loadedPetId = pet.id;
    });

    final all = <_CareEvent>[];
    try {
      final vaccines = await VaccineRepository(Supabase.instance.client).getVaccines(pet.id);
      for (final Vaccine v in vaccines) {
        all.add(_CareEvent(
          kind: _EventKind.vaccine, at: v.nextDue,
          title: '${v.name} booster',
          subtitle: 'Vaccine · ${v.dueLabelShort}',
        ));
      }
    } catch (_) {}
    try {
      final meds = await MedicationRepository(Supabase.instance.client).getMedications(pet.id);
      for (final Medication m in meds) {
        if (m.nextDoseAt != null) {
          all.add(_CareEvent(
            kind: _EventKind.medication, at: m.nextDoseAt!,
            title: m.name,
            subtitle: '${m.frequencyLabel} · ${m.dosage}',
          ));
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _events
          ..clear()
          ..addAll(all);
        _loading = false;
      });
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<_CareEvent> _eventsOn(DateTime d) =>
      _events.where((e) => _sameDay(e.at, d)).toList();

  /// Up to 3 unique-kind dots per day for the grid display.
  List<Color> _dotsFor(DateTime d) {
    final kinds = <_EventKind>{};
    final dots = <Color>[];
    for (final e in _eventsOn(d)) {
      if (kinds.add(e.kind) && dots.length < 3) dots.add(e.accent);
    }
    return dots;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ActivePetCubit, ActivePetState>(
      listenWhen: (a, b) => a.active?.id != b.active?.id,
      listener: (_, ap) {
        if (ap.active != null) _loadEvents(ap.active!);
      },
      builder: (context, ap) {
        // Initial load when the active pet first appears.
        if (ap.active != null && _loadedPetId != ap.active!.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _loadEvents(ap.active!));
        }
        return _buildScaffold(context, ap);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, ActivePetState ap) {
    final today = DateTime.now();
    final selectedEvents = _eventsOn(_selected);

    return Scaffold(
      backgroundColor: AppColors.bone,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // ── Top bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    const SizedBox(width: 36),
                    Expanded(
                      child: Center(
                        child: Text('Care',
                            style: GoogleFonts.bricolageGrotesque(
                                fontSize: 22, fontWeight: FontWeight.w600,
                                color: AppColors.ink, letterSpacing: -0.5)),
                      ),
                    ),
                    _IconBtn(child: const Icon(LucideIcons.plus, size: 18, color: AppColors.ink)),
                  ],
                ),
              ),
            ),

            // ── Pet switcher
            const SliverToBoxAdapter(child: PetSwitcher()),
            const SliverToBoxAdapter(child: SizedBox(height: 6)),

            // ── Month header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _IconBtn(
                      onTap: () => setState(() =>
                          _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1)),
                      child: const Icon(LucideIcons.chevronLeft, size: 20, color: AppColors.ink),
                    ),
                    Text('${_monthNames[_displayedMonth.month - 1]} ${_displayedMonth.year}',
                        style: GoogleFonts.bricolageGrotesque(
                            fontSize: 22, fontWeight: FontWeight.w600,
                            color: AppColors.ink, letterSpacing: -0.5)),
                    _IconBtn(
                      onTap: () => setState(() =>
                          _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1)),
                      child: const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.ink),
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
                      child: Text(d, textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              fontSize: 10, fontWeight: FontWeight.w600,
                              color: AppColors.stone2, letterSpacing: 0.08 * 10)),
                    ),
                  )).toList(),
                ),
              ),
            ),

            SliverToBoxAdapter(child: _buildDayGrid(today)),

            // ── Selected day summary
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: selectedEvents.isEmpty ? AppColors.sage50 : AppColors.clay50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          selectedEvents.isEmpty ? LucideIcons.check : LucideIcons.calendar,
                          color: selectedEvents.isEmpty ? AppColors.sage600 : AppColors.clay600,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _sameDay(_selected, today)
                                  ? 'TODAY · ${DateFormat('MMM d').format(_selected).toUpperCase()}'
                                  : DateFormat('EEE, MMM d').format(_selected).toUpperCase(),
                              style: GoogleFonts.inter(
                                  fontSize: 10, fontWeight: FontWeight.w700,
                                  letterSpacing: 0.06 * 10, color: AppColors.stone2),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selectedEvents.isEmpty
                                  ? 'Nothing scheduled'
                                  : '${selectedEvents.length} event${selectedEvents.length == 1 ? '' : 's'}',
                              style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 18, fontWeight: FontWeight.w600,
                                  color: AppColors.ink, letterSpacing: -0.5, height: 1),
                            ),
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
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Text('SCHEDULE',
                    style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        letterSpacing: 1.2, color: AppColors.stone2)),
              ),
            ),

            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 30, 20, 30),
                  child: Center(child: CircularProgressIndicator(
                      color: AppColors.clay500, strokeWidth: 2)),
                ),
              )
            else if (selectedEvents.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  child: _emptyState(),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _EventRow(event: selectedEvents[i]),
                    childCount: selectedEvents.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.clay50, borderRadius: BorderRadius.circular(10)),
            child: const Icon(LucideIcons.calendarPlus, size: 18, color: AppColors.clay600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No events on ${DateFormat('MMM d').format(_selected)}',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text('Vaccines and meds you add show up here.',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.stone, height: 1.4)),
              ],
            ),
          ),
        ],
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
      final isToday = _sameDay(date, today);
      final isSelected = _sameDay(date, _selected);
      final dots = _dotsFor(date);

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
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isToday || isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.bone : AppColors.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
              if (dots.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: dots.map((c) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Container(
                      width: 4, height: 4,
                      decoration: BoxDecoration(
                          color: isSelected ? AppColors.clay200 : c, shape: BoxShape.circle),
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
}

class _EventRow extends StatelessWidget {
  final _CareEvent event;
  const _EventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: event.tint, borderRadius: BorderRadius.circular(10)),
              child: Icon(event.icon, size: 18, color: event.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  Text(event.subtitle,
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.stone)),
                ],
              ),
            ),
            Text(DateFormat('h:mm a').format(event.at),
                style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.stone)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0);
  }
}

class _IconBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _IconBtn({required this.child, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
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
