import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../../../data/models/vaccine_model.dart';
import '../../../data/repositories/vaccine_repository.dart';
import '../../../shared/widgets/paw_form_field.dart';
import '../../../shared/widgets/pet_name_label.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../bloc/vaccines_bloc.dart';

class VaccineEditPage extends StatelessWidget {
  final String petId;
  final Vaccine? existing;
  const VaccineEditPage({super.key, required this.petId, this.existing});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VaccinesBloc(VaccineRepository(Supabase.instance.client), petId: petId)
        ..add(const VaccinesLoaded()),
      child: _VaccineEditView(petId: petId, existing: existing),
    );
  }
}

class _VaccineEditView extends StatefulWidget {
  final String petId;
  final Vaccine? existing;
  const _VaccineEditView({required this.petId, this.existing});

  @override
  State<_VaccineEditView> createState() => _VaccineEditViewState();
}

class _VaccineEditViewState extends State<_VaccineEditView> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _clinicCtrl;
  late final TextEditingController _vetCtrl;
  late final TextEditingController _costCtrl;
  DateTime? _lastGiven;
  DateTime? _nextDue;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl   = TextEditingController(text: e?.name ?? '');
    _descCtrl   = TextEditingController(text: e?.description ?? '');
    _clinicCtrl = TextEditingController(text: e?.clinic ?? '');
    _vetCtrl    = TextEditingController(text: e?.vet ?? '');
    _costCtrl   = TextEditingController(text: e?.cost?.toStringAsFixed(2) ?? '');
    _lastGiven  = e?.lastGiven;
    _nextDue    = e?.nextDue;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _clinicCtrl.dispose();
    _vetCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  bool get _valid => _nameCtrl.text.trim().isNotEmpty && _lastGiven != null && _nextDue != null;

  Future<void> _save() async {
    if (!_valid) return;
    setState(() => _saving = true);
    final vaccine = Vaccine(
      id: widget.existing?.id ?? const Uuid().v4(),
      petId: widget.petId,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      lastGiven: _lastGiven!,
      nextDue: _nextDue!,
      clinic: _clinicCtrl.text.trim().isEmpty ? null : _clinicCtrl.text.trim(),
      vet: _vetCtrl.text.trim().isEmpty ? null : _vetCtrl.text.trim(),
      cost: double.tryParse(_costCtrl.text),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    try {
      final repo = VaccineRepository(Supabase.instance.client);
      if (_isEdit) {
        await repo.updateVaccine(vaccine);
      } else {
        await repo.addVaccine(vaccine);
      }

      // Schedule a 7-days-before reminder if notifications are enabled.
      if (await NotificationsService.instance.isEnabled()) {
        String petName = 'your pet';
        try {
          final pets = await PetRepository(Supabase.instance.client)
              .getPets(Supabase.instance.client.auth.currentUser?.id ?? '');
          petName = pets.firstWhere((p) => p.id == widget.petId,
              orElse: () => pets.first).name;
        } catch (_) {}
        await NotificationsService.instance.scheduleVaccineReminder(
          vaccineId: vaccine.id,
          vaccineName: vaccine.name,
          petName: petName,
          dueAt: vaccine.nextDue,
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
            // ── Minimal top bar (back + close-style)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border)),
                      child: const Icon(LucideIcons.chevronLeft, size: 18, color: AppColors.ink),
                    ),
                  ),
                  const Spacer(),
                  PetNameLabel(
                    petId: widget.petId,
                    style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        letterSpacing: 1.2, color: AppColors.stone2),
                  ),
                  const Spacer(),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Hero gradient header (replaces drab page header)
                    Container(
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
                          Positioned(
                            right: -10, top: -6,
                            child: Transform.rotate(
                              angle: 0.5,
                              child: Icon(LucideIcons.syringe, size: 110,
                                  color: Colors.white.withValues(alpha: 0.16)),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_isEdit ? 'EDIT VACCINE' : 'NEW VACCINE',
                                  style: GoogleFonts.inter(
                                      fontSize: 11, fontWeight: FontWeight.w700,
                                      color: Colors.white.withValues(alpha: 0.9),
                                      letterSpacing: 0.6)),
                              const SizedBox(height: 4),
                              Text(_isEdit ? 'Update the record' : "Track every booster",
                                  style: GoogleFonts.bricolageGrotesque(
                                      fontSize: 26, fontWeight: FontWeight.w600,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.white,
                                      letterSpacing: -0.5, height: 1.05)),
                              const SizedBox(height: 4),
                              Text("Fill in the basics — we'll remind you 7 days before next due.",
                                  style: GoogleFonts.inter(
                                      fontSize: 12, color: Colors.white.withValues(alpha: 0.85), height: 1.5)),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.04, end: 0),
                    const SizedBox(height: 18),
                    _SectionLabel('VACCINE INFO'),
                    const SizedBox(height: 8),
                    PawFormField(
                      icon: LucideIcons.syringe,
                      label: 'NAME', hint: 'e.g. Rabies',
                      controller: _nameCtrl,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    PawFormField(
                      icon: LucideIcons.alignCenterHorizontal100,
                      label: 'DESCRIPTION (OPTIONAL)',
                      hint: 'e.g. 3-year booster',
                      controller: _descCtrl, maxLines: 2,
                    ),

                    const SizedBox(height: 20),
                    _SectionLabel('DATES'),
                    const SizedBox(height: 8),
                    PawFormField(
                      icon: LucideIcons.calendarCheck,
                      label: 'LAST GIVEN',
                      hint: 'Pick a date',
                      value: _lastGiven == null ? null : DateFormat('MMM d, yyyy').format(_lastGiven!),
                      onTap: () async {
                        final picked = await pickPawDate(context,
                            initialDate: _lastGiven ?? DateTime.now(),
                            firstDate: DateTime(2000), lastDate: DateTime.now());
                        if (picked != null) setState(() => _lastGiven = picked);
                      },
                    ),
                    const SizedBox(height: 8),
                    PawFormField(
                      icon: LucideIcons.calendar,
                      label: 'NEXT DUE',
                      hint: 'Pick a date',
                      value: _nextDue == null ? null : DateFormat('MMM d, yyyy').format(_nextDue!),
                      onTap: () async {
                        final picked = await pickPawDate(context,
                            initialDate: _nextDue ?? DateTime.now().add(const Duration(days: 365)),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(DateTime.now().year + 10));
                        if (picked != null) setState(() => _nextDue = picked);
                      },
                    ),

                    const SizedBox(height: 20),
                    _SectionLabel('CLINIC (OPTIONAL)'),
                    const SizedBox(height: 8),
                    PawFormField(
                      icon: LucideIcons.stethoscope,
                      label: 'CLINIC',
                      hint: 'e.g. Happy Paws Vet',
                      controller: _clinicCtrl,
                    ),
                    const SizedBox(height: 8),
                    PawFormField(
                      icon: LucideIcons.user,
                      label: 'VETERINARIAN',
                      hint: 'e.g. Dr. Nguyen',
                      controller: _vetCtrl,
                    ),
                    const SizedBox(height: 8),
                    PawFormField(
                      icon: LucideIcons.dollarSign,
                      label: 'COST',
                      hint: '0.00',
                      controller: _costCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                  label: _isEdit ? 'Save changes' : 'Add vaccine',
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w700,
          letterSpacing: 1.2, color: AppColors.stone2));
}
