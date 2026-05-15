import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/vaccine_model.dart';
import '../../../data/repositories/vaccine_repository.dart';
import '../bloc/vaccines_bloc.dart';

class VaccineDetailPage extends StatefulWidget {
  final String petId;
  final String vaccineId;
  const VaccineDetailPage({super.key, required this.petId, required this.vaccineId});

  @override
  State<VaccineDetailPage> createState() => _VaccineDetailPageState();
}

class _VaccineDetailPageState extends State<VaccineDetailPage> {
  Vaccine? _vaccine;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = VaccineRepository(Supabase.instance.client);
      final list = await repo.getVaccines(widget.petId);
      final v = list.firstWhere((v) => v.id == widget.vaccineId);
      if (mounted) setState(() { _vaccine = v; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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
              Text('Delete this vaccine record?',
                  style: GoogleFonts.bricolageGrotesque(
                      fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.ink)),
              const SizedBox(height: 8),
              Text("This can't be undone.",
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.stone)),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    child: Text('Cancel',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.rose600,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    child: Text('Delete',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await VaccineRepository(Supabase.instance.client).deleteVaccine(widget.vaccineId);
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
    final v = _vaccine;
    if (v == null) {
      return Scaffold(
        backgroundColor: AppColors.bone,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.triangleAlert, size: 36, color: AppColors.rose600),
              const SizedBox(height: 12),
              Text('Vaccine not found',
                  style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextButton(onPressed: () => context.pop(), child: const Text('Go back')),
            ],
          ),
        ),
      );
    }

    final s = v.status;
    final (chipLabel, chipBg, chipFg) = switch (s) {
      VaccineStatus.dueSoon  => ('Due soon',   AppColors.clay50, AppColors.clay600),
      VaccineStatus.overdue  => ('Overdue',    AppColors.rose50, AppColors.rose600),
      VaccineStatus.upToDate => ('Up to date', AppColors.sage100, AppColors.sage600),
    };

    return Scaffold(
      backgroundColor: AppColors.bone,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  _IconBtn(
                    onTap: () => context.pop(),
                    child: const Icon(LucideIcons.chevronLeft, size: 18, color: AppColors.ink),
                  ),
                  const Spacer(),
                  _IconBtn(
                    onTap: () async {
                      final updated = await context.push<bool>(
                        '/pet/${widget.petId}/vaccines/${v.id}/edit',
                      );
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
                  // ── Hero card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [AppColors.clay500, AppColors.clay700],
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -10, top: -10,
                          child: Transform.rotate(
                            angle: 0.5,
                            child: Icon(LucideIcons.syringe, size: 130,
                                color: Colors.white.withValues(alpha: 0.18)),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(chipLabel,
                                  style: GoogleFonts.inter(
                                      fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                            ),
                            const SizedBox(height: 12),
                            Text(v.name,
                                style: GoogleFonts.bricolageGrotesque(
                                    fontSize: 32, fontWeight: FontWeight.w600,
                                    color: Colors.white, letterSpacing: -0.9, height: 1.05)),
                            if (v.description != null) ...[
                              const SizedBox(height: 4),
                              Text(v.description!,
                                  style: GoogleFonts.inter(
                                      fontSize: 13, color: Colors.white.withValues(alpha: 0.85))),
                            ],
                            const SizedBox(height: 16),
                            Text(v.dueLabelShort.toUpperCase(),
                                style: GoogleFonts.inter(
                                    fontSize: 11, fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    letterSpacing: 0.6)),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0),

                  const SizedBox(height: 16),
                  _SectionLabel('TIMELINE'),
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Last given',  value: DateFormat('EEEE, MMM d, yyyy').format(v.lastGiven), icon: LucideIcons.calendarCheck),
                  _InfoRow(label: 'Next due',    value: DateFormat('EEEE, MMM d, yyyy').format(v.nextDue),    icon: LucideIcons.calendar, last: v.clinic == null && v.vet == null && v.cost == null),

                  if (v.clinic != null || v.vet != null || v.cost != null) ...[
                    const SizedBox(height: 16),
                    _SectionLabel('CLINIC'),
                    const SizedBox(height: 8),
                    if (v.clinic != null) _InfoRow(label: 'Clinic', value: v.clinic!, icon: LucideIcons.stethoscope),
                    if (v.vet != null)    _InfoRow(label: 'Vet',    value: v.vet!,    icon: LucideIcons.user),
                    if (v.cost != null)   _InfoRow(label: 'Cost',   value: '\$${v.cost!.toStringAsFixed(2)}', icon: LucideIcons.dollarSign, last: true),
                  ],
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

class _InfoRow extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool last;
  const _InfoRow({required this.label, required this.value, required this.icon, this.last = false});

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
                        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
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
