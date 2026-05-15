import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/record_model.dart';
import '../../../data/repositories/records_repository.dart';

class RecordDetailPage extends StatefulWidget {
  final String petId;
  final String recordId;
  const RecordDetailPage({super.key, required this.petId, required this.recordId});

  @override
  State<RecordDetailPage> createState() => _RecordDetailPageState();
}

class _RecordDetailPageState extends State<RecordDetailPage> {
  HealthRecord? _record;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await RecordsRepository(Supabase.instance.client).getRecords(widget.petId);
      final r = list.firstWhere((r) => r.id == widget.recordId);
      if (mounted) setState(() { _record = r; _loading = false; });
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
              Text('Delete this record?',
                  style: GoogleFonts.bricolageGrotesque(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text("Attached documents stay in your vault.",
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
                  child: Text('Delete',
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
      await RecordsRepository(Supabase.instance.client).deleteRecord(widget.recordId);
      if (mounted) context.pop(true);
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  IconData _icon(RecordType t) => switch (t) {
    RecordType.vet        => LucideIcons.stethoscope,
    RecordType.vaccine    => LucideIcons.syringe,
    RecordType.medication => LucideIcons.pill,
    RecordType.procedure  => LucideIcons.heartPulse,
    RecordType.other      => LucideIcons.folder,
  };

  (Color, Color) _colors(RecordType t) => switch (t) {
    RecordType.vet        => (AppColors.clay500, AppColors.clay700),
    RecordType.vaccine    => (AppColors.ochre500, AppColors.ochre600),
    RecordType.medication => (AppColors.rose500, AppColors.rose600),
    RecordType.procedure  => (AppColors.clay500, AppColors.clay700),
    RecordType.other      => (AppColors.sage500, AppColors.sage600),
  };

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bone,
        body: Center(child: CircularProgressIndicator(color: AppColors.clay500, strokeWidth: 2)),
      );
    }
    final r = _record;
    if (r == null) {
      return Scaffold(
        backgroundColor: AppColors.bone,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.triangleAlert, size: 36, color: AppColors.rose600),
              const SizedBox(height: 12),
              Text('Record not found',
                  style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextButton(onPressed: () => context.pop(), child: const Text('Go back')),
            ],
          ),
        ),
      );
    }

    final (c1, c2) = _colors(r.type);

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
                          '/pet/${widget.petId}/records/${r.id}/edit');
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
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [c1, c2],
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -10, top: -10,
                          child: Icon(_icon(r.type), size: 130,
                              color: Colors.white.withValues(alpha: 0.18)),
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
                              child: Text(r.type.name.toUpperCase(),
                                  style: GoogleFonts.inter(
                                      fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                            ),
                            const SizedBox(height: 12),
                            Text(r.title,
                                style: GoogleFonts.bricolageGrotesque(
                                    fontSize: 28, fontWeight: FontWeight.w600,
                                    color: Colors.white, letterSpacing: -0.8, height: 1.05)),
                            const SizedBox(height: 6),
                            Text(DateFormat('EEEE, MMM d, yyyy').format(r.date),
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: Colors.white.withValues(alpha: 0.85))),
                            if (r.cost != null) ...[
                              const SizedBox(height: 12),
                              Text('\$${r.cost!.toStringAsFixed(2)}',
                                  style: GoogleFonts.bricolageGrotesque(
                                      fontSize: 32, fontWeight: FontWeight.w700,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.white, letterSpacing: -0.8)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),

                  if (r.clinic != null || r.vet != null) ...[
                    const SizedBox(height: 16),
                    _Section('CLINIC'),
                    const SizedBox(height: 8),
                    if (r.clinic != null) _Info(icon: LucideIcons.stethoscope, label: 'Clinic', value: r.clinic!),
                    if (r.vet != null) _Info(icon: LucideIcons.user, label: 'Vet', value: r.vet!, last: true),
                  ],

                  if (r.notes != null && r.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _Section('NOTES'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(r.notes!,
                          style: GoogleFonts.inter(
                              fontSize: 14, color: AppColors.ink2, height: 1.6)),
                    ),
                  ],

                  if (r.documentUrls.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _Section('${r.documentUrls.length} DOCUMENT${r.documentUrls.length == 1 ? '' : 'S'}'),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 8, mainAxisSpacing: 8,
                      childAspectRatio: 1,
                      children: r.documentUrls.map((url) => _DocTile(url: url)).toList(),
                    ),
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

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w700,
          letterSpacing: 1.2, color: AppColors.stone2));
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool last;
  const _Info({required this.icon, required this.label, required this.value, this.last = false});

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

class _DocTile extends StatelessWidget {
  final String url;
  const _DocTile({required this.url});

  bool get _isImage =>
      url.toLowerCase().endsWith('.png') ||
      url.toLowerCase().endsWith('.jpg') ||
      url.toLowerCase().endsWith('.jpeg') ||
      url.toLowerCase().endsWith('.webp') ||
      url.toLowerCase().endsWith('.heic');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _isImage
            ? CachedNetworkImage(
                imageUrl: url, fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.line2,
                  child: const Center(child: SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 1.5))),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.neutral100,
                  child: const Icon(LucideIcons.image, color: AppColors.stone2),
                ),
              )
            : Container(
                color: AppColors.clay50,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.fileText, color: AppColors.clay600, size: 28),
                    SizedBox(height: 4),
                    Text('Tap to view',
                        style: TextStyle(fontSize: 10, color: AppColors.clay600)),
                  ],
                ),
              ),
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
