import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/document_model.dart';
import '../../../data/repositories/documents_repository.dart';

class DocumentDetailPage extends StatefulWidget {
  final String petId;
  final String documentId;
  const DocumentDetailPage({super.key, required this.petId, required this.documentId});

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  PetDocument? _doc;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await DocumentsRepository(Supabase.instance.client).getDocuments(widget.petId);
      final d = list.firstWhere((d) => d.id == widget.documentId);
      if (mounted) setState(() { _doc = d; _loading = false; });
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
              Text('Delete this document?',
                  style: GoogleFonts.bricolageGrotesque(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text("Records or vaccines you already saved from it stay put.",
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
      await DocumentsRepository(Supabase.instance.client).deleteDocument(widget.documentId);
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
    final d = _doc;
    if (d == null) {
      return Scaffold(
        backgroundColor: AppColors.bone,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.triangleAlert, size: 36, color: AppColors.rose600),
              const SizedBox(height: 12),
              Text('Document not found',
                  style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextButton(onPressed: () => context.pop(), child: const Text('Go back')),
            ],
          ),
        ),
      );
    }

    final e = d.captured;

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
                    onTap: () => launchUrl(Uri.parse(d.documentUrl), mode: LaunchMode.externalApplication),
                    child: const Icon(LucideIcons.externalLink, size: 16, color: AppColors.ink),
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
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AspectRatio(
                      aspectRatio: 1.3,
                      child: d.isImage && d.documentUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: d.documentUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: AppColors.line2),
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.clay50,
                                child: const Icon(LucideIcons.fileText, size: 40, color: AppColors.clay600),
                              ),
                            )
                          : Container(
                              color: AppColors.clay50,
                              child: const Icon(LucideIcons.fileText, size: 40, color: AppColors.clay600),
                            ),
                    ),
                  ).animate().fadeIn(duration: 350.ms),

                  const SizedBox(height: 14),
                  // Title
                  Text(d.title,
                      style: GoogleFonts.bricolageGrotesque(
                          fontSize: 24, fontWeight: FontWeight.w600,
                          color: AppColors.ink, letterSpacing: -0.7)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.neutral100,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(d.type.label,
                            style: GoogleFonts.inter(
                                fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ink2)),
                      ),
                      const SizedBox(width: 8),
                      Text(DateFormat('MMM d, yyyy').format(d.createdAt),
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.stone)),
                    ],
                  ),

                  if (!e.isEmpty) ...[
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.ink, borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.sparkles, size: 11, color: AppColors.bone),
                              const SizedBox(width: 4),
                              Text('AI EXTRACTED',
                                  style: GoogleFonts.inter(
                                      fontSize: 9, fontWeight: FontWeight.w700,
                                      color: AppColors.bone, letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (e.clinic != null) _kv('Clinic', e.clinic!, LucideIcons.stethoscope),
                    if (e.vet != null) _kv('Vet', e.vet!, LucideIcons.user),
                    if (e.visitDate != null) _kv('Visit date', DateFormat('MMM d, yyyy').format(e.visitDate!), LucideIcons.calendar),
                    if (e.nextVisit != null) _kv('Next visit', DateFormat('MMM d, yyyy').format(e.nextVisit!), LucideIcons.calendarClock),
                    if (e.diagnosis != null) _kv('Notes', e.diagnosis!, LucideIcons.alignLeft),
                    if (e.cost != null) _kv('Cost', '\$${e.cost!.toStringAsFixed(2)}', LucideIcons.dollarSign),

                    if (e.vaccines.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('VACCINES',
                          style: GoogleFonts.inter(
                              fontSize: 10, fontWeight: FontWeight.w700,
                              letterSpacing: 1.2, color: AppColors.stone2)),
                      const SizedBox(height: 6),
                      for (final v in e.vaccines)
                        _extractedListTile(
                          icon: LucideIcons.syringe,
                          title: v.name,
                          subtitle: [
                            if (v.givenOn != null) 'given ${DateFormat('MMM d, yyyy').format(v.givenOn!)}',
                            if (v.nextDue != null) 'next ${DateFormat('MMM d, yyyy').format(v.nextDue!)}',
                          ].join(' · '),
                          tint: AppColors.clay50,
                          fg: AppColors.clay600,
                        ),
                    ],

                    if (e.medications.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('MEDICATIONS',
                          style: GoogleFonts.inter(
                              fontSize: 10, fontWeight: FontWeight.w700,
                              letterSpacing: 1.2, color: AppColors.stone2)),
                      const SizedBox(height: 6),
                      for (final m in e.medications)
                        _extractedListTile(
                          icon: LucideIcons.pill,
                          title: m.name,
                          subtitle: [if (m.frequency != null) m.frequency!, if (m.dosage != null) m.dosage!].join(' · '),
                          tint: AppColors.rose50,
                          fg: AppColors.rose600,
                        ),
                    ],
                  ],

                  if (d.notes != null && d.notes!.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text('YOUR NOTES',
                        style: GoogleFonts.inter(
                            fontSize: 10, fontWeight: FontWeight.w700,
                            letterSpacing: 1.2, color: AppColors.stone2)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(d.notes!,
                          style: GoogleFonts.inter(
                              fontSize: 14, color: AppColors.ink2, height: 1.5)),
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

  Widget _kv(String label, String value, IconData icon) {
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

  Widget _extractedListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color tint,
    required Color fg,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 14, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.stone)),
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
