import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';

class _Record {
  final String day, month, title, sub, kind, price;
  final IconData icon;
  final Color tint, fg;
  final int docs;
  const _Record(this.day, this.month, this.title, this.sub, this.kind, this.price,
      this.icon, this.tint, this.fg, this.docs);
}

class _MonthGroup {
  final String label;
  final List<_Record> records;
  const _MonthGroup(this.label, this.records);
}

class RecordsPage extends StatefulWidget {
  final String petId;
  const RecordsPage({super.key, required this.petId});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  String _filter = 'All';

  static final _groups = [
    _MonthGroup('MAY 2026', [
      _Record('02', 'MAY', 'Annual wellness exam', 'Happy Paws Vet · Dr. Nguyen',
          'Vet visit', r'$180', Icons.medical_services_outlined,
          AppColors.clay50, AppColors.clay600, 2),
      _Record('01', 'MAY', 'Heartgard Plus refill', 'Chewy · Auto-ship',
          'Medication', r'$48', Icons.medication_outlined,
          AppColors.rose50, AppColors.rose600, 1),
    ]),
    _MonthGroup('APRIL 2026', [
      _Record('02', 'APR', 'Bordetella vaccine', 'Happy Paws Vet',
          'Vaccine', r'$32', Icons.vaccines_outlined,
          AppColors.ochre50, AppColors.ochre600, 1),
      _Record('02', 'APR', 'DHPP combo vaccine', 'Happy Paws Vet',
          'Vaccine', r'$45', Icons.vaccines_outlined,
          AppColors.ochre50, AppColors.ochre600, 1),
      _Record('14', 'APR', 'Dental cleaning', 'Bright Bark Dental',
          'Procedure', r'$340', Icons.medical_services_outlined,
          AppColors.clay50, AppColors.clay600, 3),
    ]),
    _MonthGroup('JANUARY 2026', [
      _Record('14', 'JAN', 'Ear infection treatment', 'Happy Paws Vet',
          'Treatment', r'$95', Icons.healing_outlined,
          AppColors.rose50, AppColors.rose600, 1),
    ]),
  ];

  static const _filters = ['All', 'Vet', 'Vaccine', 'Medication', 'Procedure'];

  @override
  Widget build(BuildContext context) {
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
                          Text('BISCUIT · ALL-TIME',
                              style: GoogleFonts.notoSans(
                                  fontSize: 10, fontWeight: FontWeight.w600,
                                  color: AppColors.stone2, letterSpacing: 1.2)),
                          Text('Records',
                              style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 20, fontWeight: FontWeight.w600,
                                  color: AppColors.ink, letterSpacing: -0.5)),
                        ],
                      ),
                    ),
                    _IconBtn(child: const Icon(Icons.search_rounded, size: 18, color: AppColors.ink)),
                  ],
                ),
              ),
            ),

            // ── Spend hero card with donut ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SPENT THIS YEAR',
                                style: GoogleFonts.notoSans(
                                    fontSize: 10, fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2, color: AppColors.stone2)),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(children: [
                                TextSpan(
                                  text: r'$740',
                                  style: GoogleFonts.bricolageGrotesque(
                                      fontSize: 30, fontWeight: FontWeight.w700,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.ink, letterSpacing: -1),
                                ),
                                TextSpan(
                                  text: '.00',
                                  style: GoogleFonts.bricolageGrotesque(
                                      fontSize: 14, fontWeight: FontWeight.w500,
                                      color: AppColors.stone2),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 4),
                            Text('across 6 records',
                                style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.stone)),
                          ],
                        ),
                      ),
                      // Donut chart
                      SizedBox(
                        width: 80, height: 80,
                        child: CustomPaint(
                          painter: _DonutPainter(segments: const [
                            (0.46, AppColors.clay600),    // procedures
                            (0.30, AppColors.clay500),    // vet
                            (0.10, AppColors.ochre500),   // vaccines
                            (0.07, AppColors.rose500),    // meds
                            (0.07, AppColors.line),       // misc
                          ]),
                          child: Center(
                            child: Text('2026',
                                style: GoogleFonts.notoSans(
                                    fontSize: 11, fontWeight: FontWeight.w600,
                                    color: AppColors.stone)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 450.ms),
              ),
            ),

            // ── Filter chips ──
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                  children: _filters.map((f) {
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

            // ── Records timeline ──
            ..._groups.map((g) => SliverToBoxAdapter(child: _buildGroup(g))),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildGroup(_MonthGroup group) {
    final records = _filter == 'All'
        ? group.records
        : group.records.where((r) => r.kind == _filter || r.kind.startsWith(_filter)).toList();
    if (records.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(group.label,
              style: GoogleFonts.notoSans(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  letterSpacing: 1.2, color: AppColors.stone2)),
          const SizedBox(height: 8),
          ...records.map((r) => _RecordRow(record: r)),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  final _Record record;
  const _RecordRow({required this.record});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Text(record.day,
                    style: GoogleFonts.bricolageGrotesque(
                        fontSize: 22, fontWeight: FontWeight.w600,
                        color: AppColors.ink, height: 1)),
                const SizedBox(height: 2),
                Text(record.month,
                    style: GoogleFonts.notoSans(
                        fontSize: 9, fontWeight: FontWeight.w700,
                        letterSpacing: 0.5, color: AppColors.stone2)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
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
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: record.tint, borderRadius: BorderRadius.circular(10)),
                    child: Icon(record.icon, size: 16, color: record.fg),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(record.title,
                            style: GoogleFonts.notoSans(
                                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                        Text(record.sub,
                            style: GoogleFonts.notoSans(fontSize: 11, color: AppColors.stone)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.neutral100,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(record.kind,
                                  style: GoogleFonts.notoSans(
                                      fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.ink2)),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.description_outlined, size: 11, color: AppColors.stone2),
                            const SizedBox(width: 2),
                            Text('${record.docs}',
                                style: GoogleFonts.notoSans(
                                    fontSize: 10, color: AppColors.stone2, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(record.price,
                      style: GoogleFonts.notoSans(
                          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0);
  }
}

class _DonutPainter extends CustomPainter {
  final List<(double, Color)> segments;
  _DonutPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 9.0;
    final rect = Rect.fromCircle(
        center: size.center(Offset.zero), radius: (size.shortestSide - stroke) / 2);

    double start = -math.pi / 2;
    for (final (frac, color) in segments) {
      final sweep = frac * 2 * math.pi;
      final paint = Paint()
        ..color = color
        ..strokeWidth = stroke
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start + 0.02, sweep - 0.04, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) => false;
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
