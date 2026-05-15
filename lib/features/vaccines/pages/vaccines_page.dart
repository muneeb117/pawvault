import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';

enum _VaxStatus { dueSoon, overdue, upToDate }

class _Vaccine {
  final String name, notes, last, next, remaining;
  final _VaxStatus status;
  const _Vaccine(this.name, this.notes, this.last, this.next, this.remaining, this.status);
}

class VaccinesPage extends StatefulWidget {
  final String petId;
  const VaccinesPage({super.key, required this.petId});

  @override
  State<VaccinesPage> createState() => _VaccinesPageState();
}

class _VaccinesPageState extends State<VaccinesPage> {
  String _filter = 'All';

  static const _vaccines = [
    _Vaccine('Rabies',         '3-year booster',                 'May 27, 2022', 'May 27, 2025', '12 days',      _VaxStatus.dueSoon),
    _Vaccine('Leptospirosis',  'Annual',                          'Feb 14, 2024', 'Feb 14, 2025', '90 days late', _VaxStatus.overdue),
    _Vaccine('DHPP (combo)',   'Distemper · parvo · hepatitis',  'Apr 02, 2025', 'Apr 02, 2026', '11 mo left',   _VaxStatus.upToDate),
    _Vaccine('Bordetella',     'Kennel cough · oral',             'Apr 02, 2025', 'Apr 02, 2026', '11 mo left',   _VaxStatus.upToDate),
    _Vaccine('Canine influenza', 'Bivalent H3N2/H3N8',           'Sep 18, 2024', 'Sep 18, 2025', '4 mo left',    _VaxStatus.upToDate),
    _Vaccine('Lyme disease',   'High-tick area',                  'Jun 12, 2024', 'Jun 12, 2025', '1 mo left',    _VaxStatus.upToDate),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'All'
        ? _vaccines
        : _vaccines.where((v) {
            switch (_filter) {
              case 'Due':        return v.status == _VaxStatus.dueSoon;
              case 'Up to date': return v.status == _VaxStatus.upToDate;
              case 'Overdue':    return v.status == _VaxStatus.overdue;
            }
            return true;
          }).toList();

    final upCount   = _vaccines.where((v) => v.status == _VaxStatus.upToDate).length;
    final dueCount  = _vaccines.where((v) => v.status == _VaxStatus.dueSoon).length;
    final overCount = _vaccines.where((v) => v.status == _VaxStatus.overdue).length;

    return Scaffold(
      backgroundColor: AppColors.bone,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // ── Top bar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    _IconBtn(
                      onTap: () => context.pop(),
                      child: const Icon(Icons.chevron_left_rounded, size: 20, color: AppColors.ink),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text('BISCUIT',
                              style: GoogleFonts.notoSans(
                                  fontSize: 10, fontWeight: FontWeight.w600,
                                  color: AppColors.stone2, letterSpacing: 1.2)),
                          Text('Vaccines',
                              style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 20, fontWeight: FontWeight.w600,
                                  color: AppColors.ink, letterSpacing: -0.5)),
                        ],
                      ),
                    ),
                    _IconBtn(child: const Icon(Icons.filter_list_rounded, size: 18, color: AppColors.ink)),
                  ],
                ),
              ),
            ),

            // ── Hero next-booster card ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [AppColors.clay500, AppColors.clay700],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Stack(
                    children: [
                      // syringe watermark
                      Positioned(
                        right: -12, top: -10,
                        child: Transform.rotate(
                          angle: 0.5,
                          child: Icon(Icons.vaccines_rounded, size: 130,
                              color: Colors.white.withValues(alpha: 0.18)),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NEXT BOOSTER',
                              style: GoogleFonts.notoSans(
                                  fontSize: 11, fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  letterSpacing: 0.06 * 11)),
                          const SizedBox(height: 4),
                          Text('Rabies — in 12 days',
                              style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 26, fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white,
                                  letterSpacing: -0.5, height: 1.05)),
                          const SizedBox(height: 4),
                          Text('Tue, May 27 · Happy Paws Vet',
                              style: GoogleFonts.notoSans(
                                  fontSize: 13, color: Colors.white.withValues(alpha: 0.85))),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _PillBtn(
                                icon: Icons.calendar_today_outlined,
                                label: 'Book appt',
                                bg: Colors.white, fg: AppColors.clay600,
                              ),
                              const SizedBox(width: 8),
                              _PillBtn(
                                icon: Icons.notifications_outlined,
                                label: 'Remind me',
                                bg: Colors.white.withValues(alpha: 0.2), fg: Colors.white,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.05, end: 0),
            ),

            // ── Status summary ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: Row(
                  children: [
                    Expanded(child: _SummaryTile(count: upCount, label: 'Up to date', dotColor: AppColors.sage500)),
                    const SizedBox(width: 8),
                    Expanded(child: _SummaryTile(count: dueCount, label: 'Due soon',   dotColor: AppColors.clay500)),
                    const SizedBox(width: 8),
                    Expanded(child: _SummaryTile(count: overCount, label: 'Overdue',   dotColor: AppColors.rose500)),
                  ],
                ),
              ),
            ),

            // ── Filter chips ──
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                  children: ['All', 'Due', 'Up to date', 'Overdue'].map((f) {
                    final active = f == _filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: AnimatedContainer(
                          duration: 180.ms,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: active ? AppColors.ink : AppColors.ink.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Center(
                            child: Text(f,
                                style: GoogleFonts.notoSans(
                                    fontSize: 12, fontWeight: FontWeight.w600,
                                    color: active ? Colors.white : AppColors.ink2)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // ── List ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _VaccineTile(vaccine: filtered[i]),
                  childCount: filtered.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg, fg;
  const _PillBtn({required this.icon, required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.notoSans(
                  fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final int count;
  final String label;
  final Color dotColor;
  const _SummaryTile({required this.count, required this.label, required this.dotColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(height: 6),
          Text('$count',
              style: GoogleFonts.bricolageGrotesque(
                  fontSize: 24, fontWeight: FontWeight.w600,
                  color: AppColors.ink, height: 1, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.notoSans(
                  fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.stone)),
        ],
      ),
    );
  }
}

class _VaccineTile extends StatelessWidget {
  final _Vaccine vaccine;
  const _VaccineTile({required this.vaccine});

  @override
  Widget build(BuildContext context) {
    final (chipLabel, chipBg, chipFg, iconBg, iconFg) = _statusStyle(vaccine.status);
    final remColor = vaccine.status == _VaxStatus.overdue
        ? AppColors.rose600
        : (vaccine.status == _VaxStatus.dueSoon ? AppColors.clay600 : AppColors.stone);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Transform.rotate(
              angle: 0.5,
              child: Icon(Icons.vaccines_rounded, size: 18, color: iconFg),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(vaccine.name,
                          style: GoogleFonts.notoSans(
                              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: chipBg, borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 5, height: 5,
                              decoration: BoxDecoration(color: chipFg, shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Text(chipLabel,
                              style: GoogleFonts.notoSans(
                                  fontSize: 10, fontWeight: FontWeight.w600, color: chipFg)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(vaccine.notes,
                    style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.stone)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Last', style: GoogleFonts.notoSans(fontSize: 10, color: AppColors.stone2)),
                          Text(vaccine.last,
                              style: GoogleFonts.notoSans(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Next', style: GoogleFonts.notoSans(fontSize: 10, color: AppColors.stone2)),
                          Text(vaccine.next,
                              style: GoogleFonts.notoSans(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
                        ],
                      ),
                    ),
                    Text(vaccine.remaining,
                        style: GoogleFonts.notoSans(
                            fontSize: 12, fontWeight: FontWeight.w600, color: remColor)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0);
  }

  (String, Color, Color, Color, Color) _statusStyle(_VaxStatus s) {
    switch (s) {
      case _VaxStatus.dueSoon:
        return ('Due soon', AppColors.clay50, AppColors.clay600, AppColors.clay100, AppColors.clay600);
      case _VaxStatus.overdue:
        return ('Overdue', AppColors.rose50, AppColors.rose600, AppColors.rose100, AppColors.rose600);
      case _VaxStatus.upToDate:
        return ('Up to date', AppColors.sage100, AppColors.sage600, AppColors.sage100, AppColors.sage600);
    }
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
