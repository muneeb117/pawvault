import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';

class _Med {
  final String name, kind, next, leftLabel;
  final IconData icon;
  final Color tint, fg;
  final bool lowRefill;
  const _Med(this.name, this.kind, this.next, this.leftLabel, this.icon, this.tint, this.fg, {this.lowRefill = false});
}

class _DoseSlot {
  final String time;
  final bool given;
  final bool isNow;
  const _DoseSlot(this.time, this.given, {this.isNow = false});
}

class MedicationsPage extends StatelessWidget {
  final String petId;
  const MedicationsPage({super.key, required this.petId});

  static const _slots = [
    _DoseSlot('8 AM', true),
    _DoseSlot('12 PM', true),
    _DoseSlot('6 PM', false, isNow: true),
    _DoseSlot('10 PM', false),
  ];

  static const _meds = [
    _Med('Heartgard Plus', 'Heartworm · Monthly · 1 chewable', 'Jun 1', '3 left',
        Icons.medication_outlined, AppColors.rose50, AppColors.rose600),
    _Med('Apoquel 16mg', 'Allergy · 1× daily · 1 tablet', 'Today, 8 AM', '12 left',
        Icons.medication_outlined, AppColors.ochre50, AppColors.ochre600),
    _Med('Fish oil', 'Supplement · 1× daily · 1 capsule', 'Today, 8 AM', '24 left',
        Icons.water_drop_outlined, AppColors.clay50, AppColors.clay500),
    _Med('Cosequin DS', 'Joint · 2× daily · 2 chewables', 'Today, 6 PM', 'Low · 4 left',
        Icons.medication_outlined, AppColors.rose50, AppColors.rose600, lowRefill: true),
  ];

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
                          Text('BISCUIT',
                              style: GoogleFonts.inter(
                                  fontSize: 10, fontWeight: FontWeight.w600,
                                  color: AppColors.stone2, letterSpacing: 1.2)),
                          Text('Medications',
                              style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 20, fontWeight: FontWeight.w600,
                                  color: AppColors.ink, letterSpacing: -0.5)),
                        ],
                      ),
                    ),
                    _IconBtn(child: const Icon(Icons.add_rounded, size: 18, color: AppColors.ink)),
                  ],
                ),
              ),
            ),

            // ── Today progress card ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('TODAY · MAY 15',
                                    style: GoogleFonts.inter(
                                        fontSize: 10, fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2, color: AppColors.stone2)),
                                const SizedBox(height: 4),
                                Text('3 doses · 2 given',
                                    style: GoogleFonts.bricolageGrotesque(
                                        fontSize: 24, fontWeight: FontWeight.w600,
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.ink, letterSpacing: -0.5)),
                              ],
                            ),
                          ),
                          // Progress ring
                          SizedBox(
                            width: 56, height: 56,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const SizedBox(
                                  width: 56, height: 56,
                                  child: CircularProgressIndicator(
                                    value: 0.67,
                                    backgroundColor: AppColors.line,
                                    valueColor: AlwaysStoppedAnimation(AppColors.ink),
                                    strokeWidth: 5,
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                Text('67%',
                                    style: GoogleFonts.inter(
                                        fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Day timeline with dots
                      _DayTimeline(slots: _slots),
                    ],
                  ),
                ).animate().fadeIn(duration: 450.ms),
              ),
            ),

            // ── Active label ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ACTIVE',
                        style: GoogleFonts.inter(
                            fontSize: 10, fontWeight: FontWeight.w700,
                            letterSpacing: 1.2, color: AppColors.stone2)),
                    Text('${_meds.length} medications',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.stone)),
                  ],
                ),
              ),
            ),

            // ── Medications list ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _MedTile(med: _meds[i]),
                  childCount: _meds.length,
                ),
              ),
            ),

            // ── Low refill banner ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.rose50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.rose100),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                            color: AppColors.rose100, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.warning_amber_rounded, color: AppColors.rose600, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cosequin running low',
                                style: GoogleFonts.inter(
                                    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.rose600)),
                            Text('4 chewables left · auto-refill ready',
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.rose600.withValues(alpha: 0.85))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.rose600,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('Refill',
                            style: GoogleFonts.inter(
                                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayTimeline extends StatelessWidget {
  final List<_DoseSlot> slots;
  const _DayTimeline({required this.slots});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return SizedBox(
          height: 50,
          child: Stack(
            children: [
              // Background line
              Positioned(
                top: 14, left: 11, right: 11,
                child: Container(height: 2, color: AppColors.line),
              ),
              // Progress line (up to last given dose)
              Positioned(
                top: 14, left: 11,
                child: Container(
                  width: (w - 22) * 0.42,
                  height: 2,
                  color: AppColors.ink,
                ),
              ),
              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: slots.map((s) {
                  return Column(
                    children: [
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: s.given
                              ? AppColors.ink
                              : (s.isNow ? AppColors.surface : AppColors.surface),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: s.given
                                ? AppColors.ink
                                : (s.isNow ? AppColors.clay500 : AppColors.stone3),
                            width: s.isNow ? 2 : 1.5,
                          ),
                        ),
                        child: s.given
                            ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(s.time,
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: s.isNow ? FontWeight.w700 : FontWeight.w500,
                              color: s.isNow ? AppColors.clay500 : AppColors.stone)),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MedTile extends StatelessWidget {
  final _Med med;
  const _MedTile({required this.med});

  @override
  Widget build(BuildContext context) {
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
            decoration: BoxDecoration(color: med.tint, borderRadius: BorderRadius.circular(12)),
            child: Icon(med.icon, size: 18, color: med.fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med.name,
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                Text(med.kind,
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.stone)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.notifications_outlined, size: 13, color: AppColors.stone2),
                    const SizedBox(width: 4),
                    Text('Next: ${med.next}',
                        style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.stone)),
                    const Spacer(),
                    Text(med.leftLabel,
                        style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: med.lowRefill ? AppColors.rose600 : AppColors.stone)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0);
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
