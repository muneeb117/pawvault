import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/date_picker.dart';
import '../../../data/models/record_model.dart';
import '../../../data/repositories/records_repository.dart';
import '../../../shared/widgets/paw_form_field.dart';
import '../../../core/utils/paw_snackbar.dart';

class RecordEditPage extends StatefulWidget {
  final String petId;
  final HealthRecord? existing;
  const RecordEditPage({super.key, required this.petId, this.existing});

  @override
  State<RecordEditPage> createState() => _RecordEditPageState();
}

class _RecordEditPageState extends State<RecordEditPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _clinicCtrl;
  late final TextEditingController _vetCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _notesCtrl;
  RecordType _type = RecordType.vet;
  DateTime? _date;
  List<String> _existingUrls = [];
  final List<({Uint8List bytes, String name})> _pendingUploads = [];
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl  = TextEditingController(text: e?.title ?? '');
    _clinicCtrl = TextEditingController(text: e?.clinic ?? '');
    _vetCtrl    = TextEditingController(text: e?.vet ?? '');
    _costCtrl   = TextEditingController(text: e?.cost?.toStringAsFixed(2) ?? '');
    _notesCtrl  = TextEditingController(text: e?.notes ?? '');
    _type       = e?.type ?? RecordType.vet;
    _date       = e?.date;
    _existingUrls = List.from(e?.documentUrls ?? const []);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _clinicCtrl.dispose();
    _vetCtrl.dispose();
    _costCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _valid => _titleCtrl.text.trim().isNotEmpty && _date != null;

  Future<void> _attach() async {
    final picker = ImagePicker();
    final f = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (f != null) {
      final bytes = await f.readAsBytes();
      setState(() => _pendingUploads.add((bytes: bytes, name: f.name)));
    }
  }

  Future<void> _save() async {
    if (!_valid) return;
    setState(() => _saving = true);
    try {
      final repo = RecordsRepository(Supabase.instance.client);
      final id = widget.existing?.id ?? const Uuid().v4();

      // Upload any pending docs first
      final uploadedUrls = <String>[];
      for (final u in _pendingUploads) {
        try {
          final url = await repo.uploadDocument(
              petId: widget.petId, recordId: id,
              bytes: u.bytes, filename: u.name);
          uploadedUrls.add(url);
        } catch (_) {}
      }

      final record = HealthRecord(
        id: id,
        petId: widget.petId,
        type: _type,
        title: _titleCtrl.text.trim(),
        clinic: _clinicCtrl.text.trim().isEmpty ? null : _clinicCtrl.text.trim(),
        vet: _vetCtrl.text.trim().isEmpty ? null : _vetCtrl.text.trim(),
        cost: double.tryParse(_costCtrl.text),
        date: _date!,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        documentUrls: [..._existingUrls, ...uploadedUrls],
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      );

      if (_isEdit) {
        await repo.updateRecord(record);
      } else {
        await repo.addRecord(record);
      }
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showPawError(context, e);
      }
    }
  }

  String _typeLabel(RecordType t) => switch (t) {
    RecordType.vet => 'Vet visit',
    RecordType.vaccine => 'Vaccine',
    RecordType.medication => 'Medication',
    RecordType.procedure => 'Procedure',
    RecordType.other => 'Other',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PawAppBar(
              title: _isEdit ? 'Edit record' : 'Add record',
              eyebrow: 'Records',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('BASICS'),
                    const SizedBox(height: 8),
                    PawFormField(
                      icon: LucideIcons.fileText, label: 'TITLE',
                      hint: 'e.g. Annual wellness exam',
                      controller: _titleCtrl, onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    PawFormField(
                      icon: LucideIcons.calendar, label: 'DATE',
                      hint: 'Pick date',
                      value: _date == null ? null : DateFormat('MMM d, yyyy').format(_date!),
                      onTap: () async {
                        final p = await pickPawDate(context,
                            initialDate: _date ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now());
                        if (p != null) setState(() => _date = p);
                      },
                    ),

                    const SizedBox(height: 20),
                    PawFormSelector<RecordType>(
                      label: 'TYPE',
                      options: RecordType.values,
                      selected: _type,
                      labelFor: _typeLabel,
                      onChanged: (t) => setState(() => _type = t),
                    ),

                    const SizedBox(height: 20),
                    _Label('CLINIC (OPTIONAL)'),
                    const SizedBox(height: 8),
                    PawFormField(
                      icon: LucideIcons.stethoscope, label: 'CLINIC',
                      hint: 'e.g. Happy Paws Vet', controller: _clinicCtrl,
                    ),
                    const SizedBox(height: 8),
                    PawFormField(
                      icon: LucideIcons.user, label: 'VETERINARIAN',
                      hint: 'e.g. Dr. Nguyen', controller: _vetCtrl,
                    ),
                    const SizedBox(height: 8),
                    PawFormField(
                      icon: LucideIcons.dollarSign, label: 'COST',
                      hint: '0.00', controller: _costCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),

                    const SizedBox(height: 20),
                    _Label('NOTES (OPTIONAL)'),
                    const SizedBox(height: 8),
                    PawFormField(
                      icon: LucideIcons.alignCenterHorizontal100, label: 'NOTES',
                      hint: 'Anything to remember about this visit…',
                      controller: _notesCtrl, maxLines: 4,
                    ),

                    const SizedBox(height: 20),
                    _Label('DOCUMENTS'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _attach,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.clay50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.clay100),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.surface, borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(LucideIcons.upload, size: 16, color: AppColors.clay600),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Attach photo or PDF',
                                      style: GoogleFonts.inter(
                                          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.clay700)),
                                  Text('Stored in your private Supabase vault',
                                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.clay600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_existingUrls.isNotEmpty || _pendingUploads.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 8, runSpacing: 8,
                          children: [
                            for (final u in _existingUrls)
                              _DocChip(label: 'Existing', onRemove: () => setState(() => _existingUrls.remove(u))),
                            for (final p in _pendingUploads)
                              _DocChip(label: p.name, onRemove: () => setState(() => _pendingUploads.remove(p))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: PawPrimaryButton(
                  label: _isEdit ? 'Save changes' : 'Add record',
                  icon: LucideIcons.check,
                  loading: _saving,
                  onPressed: _valid ? _save : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w700,
          letterSpacing: 1.2, color: AppColors.stone2));
}

class _DocChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _DocChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.fileText, size: 12, color: AppColors.stone),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.ink)),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(LucideIcons.x, size: 12, color: AppColors.stone),
            ),
          ),
        ],
      ),
    );
  }
}
