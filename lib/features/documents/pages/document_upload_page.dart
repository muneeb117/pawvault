import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/paw_snackbar.dart';
import '../../../data/models/document_model.dart';
import '../../../data/models/vaccine_model.dart';
import '../../../data/models/medication_model.dart';
import '../../../data/models/record_model.dart';
import '../../../data/repositories/ai_extraction_repository.dart';
import '../../../data/repositories/documents_repository.dart';
import '../../../data/repositories/vaccine_repository.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../data/repositories/records_repository.dart';
import '../../../shared/widgets/paw_form_field.dart';

class DocumentUploadPage extends StatefulWidget {
  final String petId;
  const DocumentUploadPage({super.key, required this.petId});

  @override
  State<DocumentUploadPage> createState() => _DocumentUploadPageState();
}

enum _UploadStep { pickType, capture, extracting, review, saving }

class _DocumentUploadPageState extends State<DocumentUploadPage> {
  _UploadStep _step = _UploadStep.pickType;
  DocType _type = DocType.vaccineCard;
  Uint8List? _bytes;
  String? _filename;
  String? _mimeType;
  ExtractedHealth _extracted = const ExtractedHealth();
  final _titleCtrl = TextEditingController();
  bool _ingestVaccines = true;
  bool _ingestMeds = true;
  bool _ingestVisit = true;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final f = await picker.pickImage(source: source, imageQuality: 90, maxWidth: 2400);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    final lower = f.name.toLowerCase();
    String mime = 'image/jpeg';
    if (lower.endsWith('.png')) mime = 'image/png';
    else if (lower.endsWith('.heic')) mime = 'image/heic';
    else if (lower.endsWith('.webp')) mime = 'image/webp';
    if (mounted) {
      setState(() {
        _bytes = bytes;
        _filename = f.name;
        _mimeType = mime;
        _titleCtrl.text = _suggestedTitle();
        _step = _UploadStep.extracting;
      });
      _runExtraction();
    }
  }

  String _suggestedTitle() {
    final d = DateTime.now();
    return '${_type.label} · ${DateFormat('MMM d').format(d)}';
  }

  Future<void> _runExtraction() async {
    try {
      final extracted = await AiExtractionRepository().extract(
        bytes: _bytes!, mimeType: _mimeType ?? 'image/jpeg', hintType: _type,
      );
      if (!mounted) return;
      setState(() {
        _extracted = extracted;
        _step = _UploadStep.review;
        if (extracted.visitDate != null) {
          _titleCtrl.text = '${_type.label} · ${DateFormat('MMM d, yyyy').format(extracted.visitDate!)}';
        }
      });
    } catch (e) {
      if (!mounted) return;
      // Skip extraction — still let user save the document without AI fields.
      setState(() {
        _extracted = const ExtractedHealth();
        _step = _UploadStep.review;
      });
      showPawError(context, e);
    }
  }

  Future<void> _save() async {
    if (_bytes == null || _titleCtrl.text.trim().isEmpty) return;
    setState(() => _step = _UploadStep.saving);

    try {
      final docId = const Uuid().v4();
      final supa = Supabase.instance.client;
      final docsRepo = DocumentsRepository(supa);

      // Upload image to storage.
      final url = await docsRepo.uploadFile(
        petId: widget.petId,
        docId: docId,
        bytes: _bytes!,
        filename: _filename ?? '$docId.jpg',
      );

      final doc = PetDocument(
        id: docId,
        petId: widget.petId,
        type: _type,
        title: _titleCtrl.text.trim(),
        documentUrl: url,
        thumbnailUrl: url,
        capturedText: null,
        captured: _extracted,
        isImage: true,
        createdAt: DateTime.now(),
      );
      await docsRepo.addDocument(doc);

      // Ingest extracted fields into other tables (with user consent).
      if (_ingestVaccines) {
        final vrepo = VaccineRepository(supa);
        for (final v in _extracted.vaccines) {
          if (v.name.trim().isEmpty) continue;
          final given = v.givenOn ?? _extracted.visitDate ?? DateTime.now();
          final next = v.nextDue ?? given.add(const Duration(days: 365));
          await vrepo.addVaccine(Vaccine(
            id: const Uuid().v4(),
            petId: widget.petId,
            name: v.name.trim(),
            description: 'Auto-extracted from ${_type.label}',
            lastGiven: given,
            nextDue: next,
            clinic: _extracted.clinic,
            vet: _extracted.vet,
            createdAt: DateTime.now(),
          ));
        }
      }

      if (_ingestMeds) {
        final mrepo = MedicationRepository(supa);
        for (final m in _extracted.medications) {
          if (m.name.trim().isEmpty) continue;
          await mrepo.addMedication(Medication(
            id: const Uuid().v4(),
            petId: widget.petId,
            name: m.name.trim(),
            category: 'Other',
            frequency: _parseFrequency(m.frequency),
            dosage: m.dosage?.trim() ?? '',
            startDate: _extracted.visitDate ?? DateTime.now(),
            isActive: true,
            createdAt: DateTime.now(),
          ));
        }
      }

      if (_ingestVisit && (_extracted.clinic != null || _extracted.visitDate != null)) {
        final rrepo = RecordsRepository(supa);
        await rrepo.addRecord(HealthRecord(
          id: const Uuid().v4(),
          petId: widget.petId,
          type: _mapRecordType(),
          title: _titleCtrl.text.trim(),
          clinic: _extracted.clinic,
          vet: _extracted.vet,
          cost: _extracted.cost,
          date: _extracted.visitDate ?? DateTime.now(),
          notes: _extracted.diagnosis,
          documentUrls: [url],
          createdAt: DateTime.now(),
        ));
      }

      if (mounted) {
        showPawSuccess(context, 'Saved to vault');
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _step = _UploadStep.review);
        showPawError(context, e);
      }
    }
  }

  MedFrequency _parseFrequency(String? s) {
    if (s == null) return MedFrequency.daily;
    final lower = s.toLowerCase();
    if (lower.contains('monthly')) return MedFrequency.monthly;
    if (lower.contains('weekly')) return MedFrequency.weekly;
    if (lower.contains('three') || lower.contains('3x') || lower.contains('3 times')) return MedFrequency.threeTimesDaily;
    if (lower.contains('twice') || lower.contains('2x') || lower.contains('2 times') || lower.contains('bid')) return MedFrequency.twiceDaily;
    if (lower.contains('once') || lower.contains('daily') || lower.contains('1x') || lower.contains('qd') || lower.contains('sid')) return MedFrequency.daily;
    if (lower.contains('as needed') || lower.contains('prn')) return MedFrequency.asNeeded;
    return MedFrequency.daily;
  }

  RecordType _mapRecordType() {
    switch (_type) {
      case DocType.vaccineCard:  return RecordType.vaccine;
      case DocType.prescription: return RecordType.medication;
      case DocType.vetVisit:     return RecordType.vet;
      case DocType.labReport:    return RecordType.vet;
      case DocType.receipt:      return RecordType.vet;
      case DocType.insurance:    return RecordType.other;
      case DocType.other:        return RecordType.other;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PawAppBar(
              title: switch (_step) {
                _UploadStep.pickType   => 'New document',
                _UploadStep.capture    => 'Choose image',
                _UploadStep.extracting => 'Reading…',
                _UploadStep.review     => 'Review & save',
                _UploadStep.saving     => 'Saving…',
              },
              eyebrow: 'Document vault',
              onBack: () {
                if (_step == _UploadStep.review || _step == _UploadStep.capture) {
                  setState(() => _step = _UploadStep.pickType);
                } else {
                  context.pop();
                }
              },
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case _UploadStep.pickType:   return _buildTypePicker();
      case _UploadStep.capture:    return _buildSource();
      case _UploadStep.extracting: return _buildExtractingState();
      case _UploadStep.review:     return _buildReview();
      case _UploadStep.saving:     return const Center(
          child: CircularProgressIndicator(color: AppColors.clay500, strokeWidth: 2));
    }
  }

  Widget _buildTypePicker() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.ink, AppColors.ink2],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(LucideIcons.sparkles, color: AppColors.bone, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Snap. Extract. Save.',
                          style: GoogleFonts.bricolageGrotesque(
                              fontSize: 20, fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                              color: Colors.white, letterSpacing: -0.5)),
                      const SizedBox(height: 2),
                      Text(
                        'Our AI reads vaccine cards, receipts, lab reports and prescriptions and auto-fills your vault.',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.white.withValues(alpha: 0.85), height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('TYPE',
              style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 1.2, color: AppColors.stone2)),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10, mainAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: DocType.values.map((t) {
              final active = t == _type;
              final meta = _typeMeta(t);
              return GestureDetector(
                onTap: () => setState(() => _type = t),
                child: AnimatedContainer(
                  duration: 160.ms,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: active ? AppColors.ink : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: active ? AppColors.ink : AppColors.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: active ? Colors.white.withValues(alpha: 0.14) : meta.$2,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(meta.$1, size: 16,
                            color: active ? AppColors.bone : meta.$3),
                      ),
                      const SizedBox(height: 8),
                      Text(t.label,
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: active ? AppColors.bone : AppColors.ink)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: PawPrimaryButton(
              label: 'Continue',
              icon: LucideIcons.arrowRight,
              onPressed: () => setState(() => _step = _UploadStep.capture),
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, Color) _typeMeta(DocType t) {
    switch (t) {
      case DocType.vaccineCard:  return (LucideIcons.syringe,        AppColors.clay50,  AppColors.clay600);
      case DocType.labReport:    return (LucideIcons.flaskConical,   AppColors.sage50,  AppColors.sage600);
      case DocType.prescription: return (LucideIcons.pill,           AppColors.rose50,  AppColors.rose600);
      case DocType.insurance:    return (LucideIcons.shieldCheck,    AppColors.ochre50, AppColors.ochre600);
      case DocType.receipt:      return (LucideIcons.receipt,        AppColors.ochre50, AppColors.ochre600);
      case DocType.vetVisit:     return (LucideIcons.stethoscope,    AppColors.clay50,  AppColors.clay600);
      case DocType.other:        return (LucideIcons.fileText,       AppColors.neutral100, AppColors.stone);
    }
  }

  Widget _buildSource() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CAPTURE',
              style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 1.2, color: AppColors.stone2)),
          const SizedBox(height: 8),
          _SourceTile(
            icon: LucideIcons.camera,
            title: 'Take a photo',
            subtitle: 'Best for vaccine cards and small receipts',
            onTap: () => _pickImage(ImageSource.camera),
          ),
          const SizedBox(height: 8),
          _SourceTile(
            icon: LucideIcons.image,
            title: 'Pick from photos',
            subtitle: 'Already-saved photos or screenshots',
            onTap: () => _pickImage(ImageSource.gallery),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.ink, AppColors.ink2],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(LucideIcons.sparkles, size: 40, color: AppColors.bone),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(0.92, 0.92), end: const Offset(1.05, 1.05), duration: 1100.ms),
            const SizedBox(height: 18),
            Text('Reading your document…',
                style: GoogleFonts.bricolageGrotesque(
                    fontSize: 22, fontWeight: FontWeight.w600,
                    color: AppColors.ink, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text('Looking for vaccine dates, meds, clinic info\nand anything else worth saving.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.stone, height: 1.55)),
          ],
        ),
      ),
    );
  }

  Widget _buildReview() {
    final e = _extracted;
    final hasFindings = !e.isEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview
          if (_bytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1.4,
                child: Image.memory(_bytes!, fit: BoxFit.cover),
              ),
            ),

          const SizedBox(height: 16),
          PawFormField(
            icon: LucideIcons.fileText,
            label: 'TITLE',
            hint: 'e.g. Rabies booster',
            controller: _titleCtrl,
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 16),
          Text(hasFindings ? 'AI FOUND' : 'NO STRUCTURED DATA',
              style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: hasFindings ? AppColors.clay500 : AppColors.stone2)),
          const SizedBox(height: 8),

          if (!hasFindings)
            Container(
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
                    decoration: BoxDecoration(
                        color: AppColors.neutral100, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(LucideIcons.fileQuestion, size: 16, color: AppColors.stone),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'We saved your document. Nothing structured to import this time.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.stone, height: 1.4),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                if (e.clinic != null || e.vet != null || e.visitDate != null || e.cost != null)
                  _findingsCard(
                    title: 'Visit',
                    rows: [
                      if (e.clinic != null)     ('Clinic', e.clinic!),
                      if (e.vet != null)        ('Vet', e.vet!),
                      if (e.visitDate != null)  ('Date', DateFormat('MMM d, yyyy').format(e.visitDate!)),
                      if (e.nextVisit != null)  ('Next visit', DateFormat('MMM d, yyyy').format(e.nextVisit!)),
                      if (e.cost != null)       ('Cost', '\$${e.cost!.toStringAsFixed(2)}'),
                      if (e.diagnosis != null)  ('Notes', e.diagnosis!),
                    ],
                    enabled: _ingestVisit,
                    onToggle: (v) => setState(() => _ingestVisit = v),
                    toggleLabel: 'Save as a record',
                  ),
                if (e.vaccines.isNotEmpty)
                  _findingsCard(
                    title: '${e.vaccines.length} vaccine${e.vaccines.length == 1 ? '' : 's'}',
                    rows: e.vaccines.map((v) {
                      final dates = [
                        if (v.givenOn != null) 'given ${DateFormat('MMM d').format(v.givenOn!)}',
                        if (v.nextDue != null) 'next ${DateFormat('MMM d').format(v.nextDue!)}',
                      ].join(' · ');
                      return (v.name, dates.isEmpty ? '—' : dates);
                    }).toList(),
                    enabled: _ingestVaccines,
                    onToggle: (v) => setState(() => _ingestVaccines = v),
                    toggleLabel: 'Add to vaccines',
                  ),
                if (e.medications.isNotEmpty)
                  _findingsCard(
                    title: '${e.medications.length} medication${e.medications.length == 1 ? '' : 's'}',
                    rows: e.medications.map((m) {
                      final extra = [if (m.frequency != null) m.frequency!, if (m.dosage != null) m.dosage!].join(' · ');
                      return (m.name, extra.isEmpty ? '—' : extra);
                    }).toList(),
                    enabled: _ingestMeds,
                    onToggle: (v) => setState(() => _ingestMeds = v),
                    toggleLabel: 'Add to medications',
                  ),
              ],
            ),

          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: PawPrimaryButton(
              label: 'Save to vault',
              icon: LucideIcons.check,
              loading: _step == _UploadStep.saving,
              onPressed: _titleCtrl.text.trim().isEmpty ? null : _save,
            ),
          ),
        ],
      ),
    );
  }

  Widget _findingsCard({
    required String title,
    required List<(String, String)> rows,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required String toggleLabel,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: enabled ? AppColors.ink : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ),
              Switch.adaptive(
                value: enabled,
                onChanged: onToggle,
                activeColor: AppColors.ink,
              ),
            ],
          ),
          Text(toggleLabel,
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.stone)),
          const SizedBox(height: 8),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(r.$1,
                        style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.stone)),
                  ),
                  Expanded(
                    child: Text(r.$2,
                        style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _SourceTile({
    required this.icon, required this.title, required this.subtitle, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.clay50, borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.clay600, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  Text(subtitle,
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.stone)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.stone2),
          ],
        ),
      ),
    );
  }
}
