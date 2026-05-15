import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/date_picker.dart';
import '../../../core/notifications/notifications_service.dart';
import '../../../core/utils/paw_snackbar.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../data/models/medication_model.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../shared/widgets/paw_form_field.dart';

class MedicationEditPage extends StatefulWidget {
  final String petId;
  final Medication? existing;
  const MedicationEditPage({super.key, required this.petId, this.existing});

  @override
  State<MedicationEditPage> createState() => _MedicationEditPageState();
}

class _MedicationEditPageState extends State<MedicationEditPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _dosageCtrl;
  late final TextEditingController _remainingCtrl;
  String? _category;
  MedFrequency _frequency = MedFrequency.daily;
  DateTime? _startDate;
  DateTime? _nextDose;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  static const _categories = ['Heartworm', 'Allergy', 'Supplement', 'Joint', 'Pain', 'Antibiotic', 'Other'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl      = TextEditingController(text: e?.name ?? '');
    _dosageCtrl    = TextEditingController(text: e?.dosage ?? '');
    _remainingCtrl = TextEditingController(text: e?.remainingCount?.toString() ?? '');
    _category      = e?.category;
    _frequency     = e?.frequency ?? MedFrequency.daily;
    _startDate     = e?.startDate;
    _nextDose      = e?.nextDoseAt;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _remainingCtrl.dispose();
    super.dispose();
  }

  String _freqLabel(MedFrequency f) {
    switch (f) {
      case MedFrequency.once: return 'Once';
      case MedFrequency.daily: return '1× daily';
      case MedFrequency.twiceDaily: return '2× daily';
      case MedFrequency.threeTimesDaily: return '3× daily';
      case MedFrequency.weekly: return 'Weekly';
      case MedFrequency.monthly: return 'Monthly';
      case MedFrequency.asNeeded: return 'As needed';
    }
  }

  bool get _valid =>
      _nameCtrl.text.trim().isNotEmpty &&
      _dosageCtrl.text.trim().isNotEmpty &&
      _startDate != null;

  Future<void> _save() async {
    if (!_valid) return;
    setState(() => _saving = true);
    final med = Medication(
      id: widget.existing?.id ?? const Uuid().v4(),
      petId: widget.petId,
      name: _nameCtrl.text.trim(),
      category: _category,
      frequency: _frequency,
      dosage: _dosageCtrl.text.trim(),
      remainingCount: int.tryParse(_remainingCtrl.text),
      nextDoseAt: _nextDose,
      isActive: true,
      startDate: _startDate!,
      endDate: widget.existing?.endDate,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    try {
      final repo = MedicationRepository(Supabase.instance.client);
      if (_isEdit) {
        await repo.updateMedication(med);
      } else {
        await repo.addMedication(med);
      }

      if (med.nextDoseAt != null && await NotificationsService.instance.isEnabled()) {
        String petName = 'your pet';
        try {
          final pets = await PetRepository(Supabase.instance.client)
              .getPets(Supabase.instance.client.auth.currentUser?.id ?? '');
          petName = pets.firstWhere((p) => p.id == widget.petId,
              orElse: () => pets.first).name;
        } catch (_) {}
        await NotificationsService.instance.scheduleDoseReminder(
          medId: med.id,
          medName: med.name,
          petName: petName,
          doseAt: med.nextDoseAt!,
        );
      }

      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showPawError(context, e);
      }
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
              title: _isEdit ? 'Edit medication' : 'Add medication',
              eyebrow: 'Medications',
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
                      icon: LucideIcons.pill, label: 'NAME', hint: 'e.g. Heartgard Plus',
                      controller: _nameCtrl,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    PawFormField(
                      icon: LucideIcons.beaker, label: 'DOSAGE', hint: 'e.g. 1 chewable',
                      controller: _dosageCtrl,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    PawFormField(
                      icon: LucideIcons.boxes, label: 'REMAINING COUNT', hint: '0',
                      controller: _remainingCtrl,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 20),
                    PawFormSelector<String>(
                      label: 'CATEGORY',
                      options: _categories,
                      selected: _category,
                      labelFor: (c) => c,
                      onChanged: (c) => setState(() => _category = c),
                    ),

                    const SizedBox(height: 20),
                    PawFormSelector<MedFrequency>(
                      label: 'FREQUENCY',
                      options: MedFrequency.values,
                      selected: _frequency,
                      labelFor: _freqLabel,
                      onChanged: (f) => setState(() => _frequency = f),
                    ),

                    const SizedBox(height: 20),
                    _Label('SCHEDULE'),
                    const SizedBox(height: 8),
                    PawFormField(
                      icon: LucideIcons.calendarPlus, label: 'START DATE', hint: 'Pick a date',
                      value: _startDate == null ? null : DateFormat('MMM d, yyyy').format(_startDate!),
                      onTap: () async {
                        final p = await pickPawDate(context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(DateTime.now().year + 5));
                        if (p != null) setState(() => _startDate = p);
                      },
                    ),
                    const SizedBox(height: 8),
                    PawFormField(
                      icon: LucideIcons.bell, label: 'NEXT DOSE', hint: 'Pick date',
                      value: _nextDose == null ? null : DateFormat('MMM d, h:mm a').format(_nextDose!),
                      onTap: () async {
                        final p = await pickPawDate(context,
                            initialDate: _nextDose ?? DateTime.now().add(const Duration(hours: 8)),
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime(DateTime.now().year + 5));
                        if (p != null && mounted) {
                          final t = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(_nextDose ?? DateTime.now()));
                          setState(() {
                            _nextDose = DateTime(p.year, p.month, p.day, t?.hour ?? 8, t?.minute ?? 0);
                          });
                        }
                      },
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
                  label: _isEdit ? 'Save changes' : 'Add medication',
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
