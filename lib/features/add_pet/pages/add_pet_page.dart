import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../bloc/add_pet_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/date_picker.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/pet_model.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../shared/widgets/pet_avatar_widget.dart';

class AddPetPage extends StatelessWidget {
  const AddPetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddPetBloc(PetRepository(Supabase.instance.client)),
      child: const _AddPetView(),
    );
  }
}

class _AddPetView extends StatelessWidget {
  const _AddPetView();

  static const _totalSteps = 3;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddPetBloc, AddPetState>(
      listener: (context, state) {
        if (state.status == AddPetStatus.success) context.go(AppRoutes.home);
        if (state.status == AddPetStatus.failure && state.error != null) {
          final raw = state.error!;
          final friendly = raw.contains('schema cache') || raw.contains('public.pets')
              ? "Database isn't set up yet. Run supabase/schema.sql in your Supabase SQL Editor."
              : raw.contains('row-level security') || raw.contains('RLS')
                  ? "Couldn't save — sign-in required. Enable Anonymous Auth in Supabase."
                  : raw.length > 120 ? '${raw.substring(0, 120)}…' : raw;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(friendly, style: const TextStyle(color: Colors.white, fontSize: 13)),
              backgroundColor: AppColors.ink,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.bone,
          body: SafeArea(
            child: Column(
              children: [
                // ── top bar ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      _IconBtn(
                        onTap: () {
                          if (state.step > 0) {
                            context.read<AddPetBloc>().add(const AddPetStepBacked());
                          } else if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(AppRoutes.home);
                          }
                        },
                        child: const Icon(Icons.close_rounded, size: 18, color: AppColors.ink),
                      ),
                      const Spacer(),
                      Text(
                        'STEP ${state.step + 1} OF $_totalSteps',
                        style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: AppColors.stone2, letterSpacing: 1.0,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 36),
                    ],
                  ),
                ),

                // ── progress bar ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Row(
                    children: List.generate(_totalSteps, (i) => Expanded(
                      child: Container(
                        margin: EdgeInsets.only(left: i > 0 ? 4 : 0),
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= state.step ? AppColors.ink : AppColors.line,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    )),
                  ),
                ),

                // ── step body ─────────────────────────────────────────
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero).animate(anim),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(state.step),
                      child: [
                        const _StepSpecies(),
                        const _StepAvatarAndBasics(),
                        const _StepHealth(),
                      ][state.step],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Shared header ─────────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  const _StepHeader({required this.eyebrow, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 12, fontWeight: FontWeight.w500,
                letterSpacing: 0.7, color: AppColors.clay500,
              )),
          const SizedBox(height: 6),
          Text(title,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 30, fontWeight: FontWeight.w600,
                color: AppColors.ink, letterSpacing: -0.9, height: 1.08,
              )),
          const SizedBox(height: 6),
          Text(subtitle,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.stone, height: 1.5)),
        ],
      ),
    );
  }
}

// ─── Shared footer ─────────────────────────────────────────────────────────

class _StepFooter extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onContinue;
  final String label;
  final bool loading;

  const _StepFooter({
    this.onBack,
    this.onContinue,
    this.label = 'Continue',
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.bone,
        border: Border(top: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            _IconBtn(
              onTap: onBack!,
              child: const Icon(Icons.chevron_left_rounded, size: 22, color: AppColors.ink),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: loading ? null : onContinue,
                child: loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: AppColors.bone, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right_rounded, size: 18),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  const _IconBtn({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      ),
    );
  }
}

// ─── Step 0 — Species ───────────────────────────────────────────────────────

class _StepSpecies extends StatelessWidget {
  const _StepSpecies();

  static const _species = [
    (PetSpecies.dog, 'assets/animations/dog_idle.json', '🐶', 'Dog'),
    (PetSpecies.cat, 'assets/animations/cat_idle.json', '🐱', 'Cat'),
    (PetSpecies.rabbit, 'assets/animations/rabbit_idle.json', '🐰', 'Rabbit'),
    (PetSpecies.bird, 'assets/animations/bird_idle.json', '🐦', 'Bird'),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<AddPetBloc>().state.species;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHeader(
          eyebrow: 'NEW FAMILY MEMBER',
          title: "Who's joining\nthe family?",
          subtitle: "Pick your buddy's species to get started.",
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
              physics: const NeverScrollableScrollPhysics(),
              children: _species.map((s) {
                final active = s.$1 == selected;
                return GestureDetector(
                  onTap: () => context.read<AddPetBloc>().add(AddPetSpeciesSelected(s.$1)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: active ? AppColors.ink : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: active ? AppColors.ink : AppColors.border,
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            color: active ? Colors.white.withValues(alpha: 0.14) : AppColors.bone,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Lottie.asset(
                              s.$2, width: 46, height: 46, fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Text(s.$3, style: const TextStyle(fontSize: 32)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(s.$4,
                            style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: active ? AppColors.bone : AppColors.ink,
                            )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        _StepFooter(
          onContinue: () => context.read<AddPetBloc>().add(const AddPetStepAdvanced()),
        ),
      ],
    );
  }
}

// ─── Step 1 — Avatar card + Species row + Basics form (all one scroll) ──────

class _StepAvatarAndBasics extends StatefulWidget {
  const _StepAvatarAndBasics();

  @override
  State<_StepAvatarAndBasics> createState() => _StepAvatarAndBasicsState();
}

class _StepAvatarAndBasicsState extends State<_StepAvatarAndBasics> {
  final _nameCtrl = TextEditingController();
  final _breedCtrl = TextEditingController();
  DateTime? _dob;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await pickPawDate(
      context,
      initialDate: _dob ?? DateTime(DateTime.now().year - 1),
    );
    if (picked != null && mounted) {
      setState(() => _dob = picked);
      context.read<AddPetBloc>().add(AddPetDobChanged(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AddPetBloc>().state;
    final previewPet = Pet(
      id: 'preview',
      name: state.name.isEmpty ? 'Buddy' : state.name,
      species: state.species,
      breed: '',
      dateOfBirth: DateTime(2022),
      mood: state.mood,
      userId: '',
      createdAt: DateTime.now(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHeader(
          eyebrow: 'NEW FAMILY MEMBER',
          title: 'Pick the perfect look\nfor your buddy.',
          subtitle: 'Tap the avatar to see them play. You can upload a real photo later.',
        ),
        const SizedBox(height: 14),

        // ── scrollable body ──────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [AppColors.clay50, AppColors.bone],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Stack(
                      children: [
                        // Mood pills — top right
                        Positioned(
                          top: 12, right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: AvatarMood.values.map((m) {
                                final active = m == state.mood;
                                return GestureDetector(
                                  onTap: () => context.read<AddPetBloc>().add(AddPetMoodSelected(m)),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: active ? AppColors.ink : Colors.transparent,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _moodLabel(m),
                                      style: GoogleFonts.inter(
                                        fontSize: 10, fontWeight: FontWeight.w500,
                                        color: active ? AppColors.bone : AppColors.stone,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                        // Avatar
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              final moods = AvatarMood.values;
                              final next = moods[(moods.indexOf(state.mood) + 1) % moods.length];
                              context.read<AddPetBloc>().add(AddPetMoodSelected(next));
                            },
                            child: PetAvatarWidget(
                              pet: previewPet,
                              size: 170,
                              showMoodRing: false,
                            ),
                          ),
                        ),

                        // Upload photo button — bottom center
                        Positioned(
                          bottom: 14, left: 0, right: 0,
                          child: Center(
                            child: GestureDetector(
                              onTap: () async {
                                final picker = ImagePicker();
                                final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                                if (file != null && mounted) {
                                  final bytes = Uint8List.fromList(await file.readAsBytes());
                                  final ext = file.path.split('.').last;
                                  context.read<AddPetBloc>().add(AddPetPhotoSelected(bytes, ext));
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.camera_alt_outlined, size: 13, color: AppColors.ink2),
                                    const SizedBox(width: 6),
                                    Text('Upload photo instead',
                                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink2)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Species row ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SPECIES',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.stone2)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _speciesTile(context, PetSpecies.dog, 'assets/animations/dog_idle.json', '🐶', 'Dog', state.species),
                          _speciesTile(context, PetSpecies.cat, 'assets/animations/cat_idle.json', '🐱', 'Cat', state.species),
                          _speciesTile(context, PetSpecies.rabbit, 'assets/animations/rabbit_idle.json', '🐰', 'Rabbit', state.species),
                          _speciesTile(context, PetSpecies.bird, 'assets/animations/bird_idle.json', '🐦', 'Bird', state.species),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Basics section ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BASICS',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.stone2)),
                      const SizedBox(height: 8),

                      // Name field
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.pets_rounded, size: 16, color: AppColors.stone),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('NAME', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.stone, letterSpacing: 0.5)),
                                  const SizedBox(height: 2),
                                  TextFormField(
                                    controller: _nameCtrl,
                                    onChanged: (v) => context.read<AddPetBloc>().add(AddPetNameChanged(v)),
                                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
                                    decoration: InputDecoration(
                                      hintText: 'e.g. Biscuit',
                                      hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.stone2),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                      isDense: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Breed + Birthday row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('BREED', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.stone, letterSpacing: 0.5)),
                                  const SizedBox(height: 2),
                                  TextFormField(
                                    controller: _breedCtrl,
                                    onChanged: (v) => context.read<AddPetBloc>().add(AddPetBreedChanged(v)),
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink),
                                    decoration: InputDecoration(
                                      hintText: 'Golden Retriever',
                                      hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.stone2),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                      isDense: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickDate,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('BIRTHDAY', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.stone, letterSpacing: 0.5)),
                                    const SizedBox(height: 2),
                                    Text(
                                      _dob == null ? 'Pick date' : _formatDate(_dob!),
                                      style: GoogleFonts.inter(
                                        fontSize: 13, fontWeight: FontWeight.w500,
                                        color: _dob == null ? AppColors.stone2 : AppColors.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        _StepFooter(
          onBack: () => context.read<AddPetBloc>().add(const AddPetStepBacked()),
          onContinue: () => context.read<AddPetBloc>().add(const AddPetStepAdvanced()),
        ),
      ],
    );
  }

  Widget _speciesTile(BuildContext context, PetSpecies sp, String lottie, String emoji, String label, PetSpecies selected) {
    final active = sp == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<AddPetBloc>().add(AddPetSpeciesSelected(sp)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
          decoration: BoxDecoration(
            color: active ? AppColors.ink : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? AppColors.ink : AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: active ? Colors.white.withValues(alpha: 0.14) : AppColors.bone,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Lottie.asset(
                    lottie, width: 34, height: 34, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(label,
                  style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: active ? AppColors.bone : AppColors.ink,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  String _moodLabel(AvatarMood m) {
    switch (m) {
      case AvatarMood.idle: return 'Idle';
      case AvatarMood.happy: return 'Happy';
      case AvatarMood.running: return 'Running';
      case AvatarMood.sleeping: return 'Sleeping';
    }
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ─── Step 2 — Health basics ─────────────────────────────────────────────────

class _StepHealth extends StatefulWidget {
  const _StepHealth();

  @override
  State<_StepHealth> createState() => _StepHealthState();
}

class _StepHealthState extends State<_StepHealth> {
  String? _gender;
  final _weightCtrl = TextEditingController();

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AddPetBloc>().state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHeader(
          eyebrow: 'NEW FAMILY MEMBER',
          title: 'A little more\nabout them.',
          subtitle: 'These details help personalise health reminders and insights.',
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gender
                Text('GENDER', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.stone2)),
                const SizedBox(height: 8),
                Row(
                  children: ['Male', 'Female', 'Unknown'].map((g) {
                    final sel = _gender == g;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _gender = g);
                          context.read<AddPetBloc>().add(AddPetGenderChanged(g));
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: EdgeInsets.only(right: g != 'Unknown' ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.ink : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: sel ? AppColors.ink : AppColors.border),
                          ),
                          child: Center(
                            child: Text(g,
                                style: GoogleFonts.inter(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: sel ? AppColors.bone : AppColors.ink,
                                )),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Weight
                Text('WEIGHT', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.stone2)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _weightCtrl,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: '0.0',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            hintStyle: GoogleFonts.inter(color: AppColors.stone2),
                          ),
                        ),
                      ),
                      Text('kg', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.stone)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Microchip / neutered
                Row(
                  children: [
                    Expanded(child: _ToggleCard(label: 'Neutered / Spayed', icon: Icons.health_and_safety_outlined)),
                    const SizedBox(width: 8),
                    Expanded(child: _ToggleCard(label: 'Has microchip', icon: Icons.memory_outlined)),
                  ],
                ),
              ],
            ),
          ),
        ),
        _StepFooter(
          onBack: () => context.read<AddPetBloc>().add(const AddPetStepBacked()),
          label: 'Add to my family 🐾',
          loading: state.status == AddPetStatus.loading,
          onContinue: state.status == AddPetStatus.loading || state.name.isEmpty ? null : () {
            String userId = '';
            try { userId = Supabase.instance.client.auth.currentUser?.id ?? ''; } catch (_) {}
            context.read<AddPetBloc>().add(AddPetSubmitted(userId));
          },
        ),
      ],
    );
  }
}

class _ToggleCard extends StatefulWidget {
  final String label;
  final IconData icon;
  const _ToggleCard({required this.label, required this.icon});

  @override
  State<_ToggleCard> createState() => _ToggleCardState();
}

class _ToggleCardState extends State<_ToggleCard> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _on = !_on),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _on ? AppColors.ink : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _on ? AppColors.ink : AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(widget.icon, size: 20, color: _on ? AppColors.bone : AppColors.stone),
            const SizedBox(height: 8),
            Text(widget.label,
                style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: _on ? AppColors.bone : AppColors.ink,
                )),
          ],
        ),
      ),
    );
  }
}
