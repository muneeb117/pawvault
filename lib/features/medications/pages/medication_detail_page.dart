import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/medication_model.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../core/utils/paw_snackbar.dart';

class MedicationDetailPage extends StatefulWidget {
  final String petId;
  final String medId;
  const MedicationDetailPage({super.key, required this.petId, required this.medId});

  @override
  State<MedicationDetailPage> createState() => _MedicationDetailPageState();
}

class _MedicationDetailPageState extends State<MedicationDetailPage> {
  Medication? _med;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = MedicationRepository(Supabase.instance.client);
      final list = await repo.getMedications(widget.petId);
      final m = list.firstWhere((m) => m.id == widget.medId);
      if (mounted) setState(() { _med = m; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markDoseGiven() async {
    if (_med == null) return;
    setState(() => _busy = true);
    try {
      final repo = MedicationRepository(Supabase.instance.client);
      await repo.markDoseGiven(_med!.id);
      if (mounted) showPawSuccess(context, 'Dose recorded 🐾');
    } catch (e) {
      if (mounted) showPawError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.bone,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Remove this medication?',
                  style: GoogleFonts.bricolageGrotesque(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text("We'll archive it — dose history stays put.",
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.stone)),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: Text('Cancel',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.rose600,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: Text('Remove',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await MedicationRepository(Supabase.instance.client).deleteMedication(widget.medId);
      if (mounted) context.pop(true);
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bone,
        body: Center(child: CircularProgressIndicator(color: AppColors.clay500, strokeWidth: 2)),
      );
    }
    final m = _med;
    if (m == null) {
      return Scaffold(
        backgroundColor: AppColors.bone,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.triangleAlert, size: 36, color: AppColors.rose600),
              const SizedBox(height: 12),
              Text('Medication not found',
                  style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextButton(onPressed: () => context.pop(), child: const Text('Go back')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bone,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  _IconBtn(onTap: () => context.pop(),
                      child: const Icon(LucideIcons.chevronLeft, size: 18, color: AppColors.ink)),
                  const Spacer(),
                  _IconBtn(
                    onTap: () async {
                      final updated = await context.push<bool>(
                          '/pet/${widget.petId}/medications/${m.id}/edit');
                      if (updated == true) _load();
                    },
                    child: const Icon(LucideIcons.pencil, size: 16, color: AppColors.ink),
                  ),
                  const SizedBox(width: 8),
                  _IconBtn(
                    onTap: _busy ? null : _delete,
                    child: const Icon(LucideIcons.trash2, size: 16, color: AppColors.rose600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 60),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [AppColors.clay50, AppColors.bone, AppColors.ochre50],
                        stops: [0, 0.6, 1],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border)),
                              child: const Icon(LucideIcons.pill, size: 26, color: AppColors.clay600),
                            ),
                            const Spacer(),
                            if (m.isLowRefill)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.rose50, borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text('Low refill',
                                    style: GoogleFonts.inter(
                                        fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.rose600)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(m.name,
                            style: GoogleFonts.bricolageGrotesque(
                                fontSize: 30, fontWeight: FontWeight.w600,
                                color: AppColors.ink, letterSpacing: -0.9)),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (m.category != null) m.category!,
                            m.frequencyLabel,
                            m.dosage,
                          ].join(' · '),
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.stone),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: 16),
                  if (m.nextDoseAt != null)
                    GestureDetector(
                      onTap: _busy ? null : _markDoseGiven,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.ink, AppColors.ink2],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(LucideIcons.check, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Mark this dose as given',
                                      style: GoogleFonts.inter(
                                          fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                                  Text(DateFormat('EEE, MMM d · h:mm a').format(m.nextDoseAt!),
                                      style: GoogleFonts.inter(
                                          fontSize: 11, color: Colors.white.withValues(alpha: 0.75))),
                                ],
                              ),
                            ),
                            if (_busy)
                              const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                              ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                  _SectionLabel('SCHEDULE'),
                  const SizedBox(height: 8),
                  _Info(icon: LucideIcons.calendarPlus, label: 'Started',
                      value: DateFormat('MMM d, yyyy').format(m.startDate)),
                  if (m.nextDoseAt != null)
                    _Info(icon: LucideIcons.bell, label: 'Next dose',
                        value: DateFormat('MMM d, yyyy · h:mm a').format(m.nextDoseAt!)),
                  if (m.remainingCount != null)
                    _Info(icon: LucideIcons.boxes, label: 'Remaining',
                        value: '${m.remainingCount} doses',
                        valueColor: m.isLowRefill ? AppColors.rose600 : null,
                        last: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w700,
          letterSpacing: 1.2, color: AppColors.stone2));
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  final bool last;
  const _Info({required this.icon, required this.label, required this.value, this.valueColor, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.clay50, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: AppColors.clay600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.stone)),
                const SizedBox(height: 1),
                Text(value,
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: valueColor ?? AppColors.ink)),
              ],
            ),
          ),
        ],
      ),
    );
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
