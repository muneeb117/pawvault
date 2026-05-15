import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bloc/onboarding_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/router_helpers.dart';

// ════════════════════════════════════════════════════════════════════════
// PawVault — Onboarding (10 screens: 3 welcome + 5 questions + notifications + auth handoff)
// ════════════════════════════════════════════════════════════════════════

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingBloc(),
      child: const _OnboardingFlow(),
    );
  }
}

class _OnboardingFlow extends StatefulWidget {
  const _OnboardingFlow();
  @override
  State<_OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<_OnboardingFlow> {
  final _controller = PageController();
  static const _totalSteps = 9; // 3 welcome + 5 questions + 1 notifications

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    final state = context.read<OnboardingBloc>().state;
    if (state.currentPage < _totalSteps - 1) {
      _controller.nextPage(duration: 300.ms, curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  void _back() {
    if (context.read<OnboardingBloc>().state.currentPage > 0) {
      _controller.previousPage(duration: 300.ms, curve: Curves.easeInOut);
    }
  }

  Future<void> _finish() async {
    final s = context.read<OnboardingBloc>().state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('onboard_primary_species', s.primarySpecies ?? '');
    await prefs.setString('onboard_pet_count', s.petCount ?? '');
    await prefs.setStringList('onboard_priorities', s.priorities);
    await prefs.setString('onboard_care_time', s.careTime ?? '');
    await prefs.setString('onboard_referral', s.referralSource ?? '');
    await prefs.setBool('onboard_notifs', s.notificationsEnabled);
    await AppFlags.setOnboardingDone(true);
    if (!mounted) return;
    context.go(AppRoutes.authLanding);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, s) {
        final isFirstThree = s.currentPage < 3;
        return Scaffold(
          backgroundColor: AppColors.bone,
          body: Column(
            children: [
              // ── Top: logo + skip ─────────────────────────────────
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _Logo(),
                      Row(
                        children: [
                          if (s.currentPage > 0)
                            GestureDetector(
                              onTap: _back,
                              child: Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Icon(LucideIcons.arrowLeft, size: 16, color: AppColors.ink),
                              ),
                            ),
                          const SizedBox(width: 8),
                          if (s.currentPage < _totalSteps - 1)
                            TextButton(
                              onPressed: _finish,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: const Size(40, 30),
                              ),
                              child: Text('Skip',
                                  style: GoogleFonts.notoSans(
                                      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.stone)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Progress bar (visible from question 1 onward) ──
              if (!isFirstThree)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    children: List.generate(_totalSteps - 3, (i) {
                      final idx = i + 3;
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(left: i > 0 ? 4 : 0),
                          height: 3,
                          decoration: BoxDecoration(
                            color: idx <= s.currentPage ? AppColors.ink : AppColors.line,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

              // ── Page body ────────────────────────────────────────
              Expanded(
                child: PageView(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) =>
                      context.read<OnboardingBloc>().add(OnboardingPageChanged(i)),
                  children: [
                    const _WelcomeSlide(
                      eyebrow: 'Welcome',
                      title: 'A vault for every wag,\npurr & nuzzle.',
                      body: 'Track vaccines, vet visits, meds and milestones — all in one cozy place.',
                      lottiePath: 'assets/animations/dog_happy.json',
                      bgEnd: Color(0xFFF6DCC5),
                    ),
                    const _WelcomeSlide(
                      eyebrow: 'Stay ahead',
                      title: 'Never miss a\nbooster again.',
                      body: 'Smart reminders for vaccines, refills and check-ups, tuned to your pet.',
                      lottiePath: 'assets/animations/cat_idle.json',
                      bgEnd: Color(0xFFDDE5DA),
                    ),
                    const _WelcomeSlide(
                      eyebrow: 'Share & sync',
                      title: 'One tap to share\nwith your vet.',
                      body: 'Export beautiful PDF records or share a private link with sitters and vets.',
                      lottiePath: 'assets/animations/rabbit_idle.json',
                      bgEnd: Color(0xFFF4E6BD),
                    ),
                    _QuestionSpecies(),
                    _QuestionPetCount(),
                    _QuestionPriorities(),
                    _QuestionCareTime(),
                    _QuestionReferral(),
                    _QuestionNotifications(),
                  ],
                ),
              ),

              // ── Dots (only for welcome slides) ──
              if (isFirstThree)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final active = i == s.currentPage;
                      return AnimatedContainer(
                        duration: 250.ms,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 22 : 6, height: 6,
                        decoration: BoxDecoration(
                          color: active ? AppColors.ink : AppColors.line,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                ),

              // ── CTA ──
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                  child: SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: _canAdvance(s) ? _next : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        disabledBackgroundColor: AppColors.ink.withValues(alpha: 0.25),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            s.currentPage == _totalSteps - 1 ? 'Continue to sign up' : 'Continue',
                            style: GoogleFonts.notoSans(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 6),
                          const Icon(LucideIcons.arrowRight, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _canAdvance(OnboardingState s) {
    switch (s.currentPage) {
      case 3: return s.primarySpecies != null;
      case 4: return s.petCount != null;
      case 5: return s.priorities.isNotEmpty;
      case 6: return s.careTime != null;
      case 7: return s.referralSource != null;
      default: return true;
    }
  }
}

// ─── Logo ────────────────────────────────────────────────────────────────
class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26, height: 26,
          decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(7)),
          child: const Icon(LucideIcons.pawPrint, color: AppColors.bone, size: 14),
        ),
        const SizedBox(width: 7),
        Text(
          'PawVault',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 17, fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic, color: AppColors.ink2,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

// ─── Welcome slide ───────────────────────────────────────────────────────
class _WelcomeSlide extends StatelessWidget {
  final String eyebrow, title, body, lottiePath;
  final Color bgEnd;

  const _WelcomeSlide({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.lottiePath,
    required this.bgEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [AppColors.bone, bgEnd],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.line),
              ),
              child: Stack(
                children: [
                  Positioned(top: 18, left: 22,
                      child: Icon(LucideIcons.pawPrint, size: 36, color: AppColors.ink.withValues(alpha: 0.06))),
                  Positioned(top: 60, right: 26,
                      child: Icon(LucideIcons.pawPrint, size: 28, color: AppColors.ink.withValues(alpha: 0.05))),
                  Positioned(bottom: 30, left: 30,
                      child: Icon(LucideIcons.pawPrint, size: 24, color: AppColors.ink.withValues(alpha: 0.04))),
                  Center(
                    child: SizedBox(
                      width: 220, height: 220,
                      child: Lottie.asset(
                        lottiePath, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(LucideIcons.pawPrint, size: 80, color: AppColors.clay500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow.toUpperCase(),
                    style: GoogleFonts.bricolageGrotesque(
                        fontSize: 12, fontWeight: FontWeight.w500,
                        letterSpacing: 0.72, color: AppColors.clay500)),
                const SizedBox(height: 8),
                Text(title,
                    style: GoogleFonts.bricolageGrotesque(
                        fontSize: 34, fontWeight: FontWeight.w600,
                        color: AppColors.ink, letterSpacing: -1.2, height: 1.05)),
                const SizedBox(height: 10),
                Text(body,
                    style: GoogleFonts.notoSans(fontSize: 14, color: AppColors.stone, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─── Question template ────────────────────────────────────────────────────
class _QuestionFrame extends StatelessWidget {
  final String eyebrow, question, helper;
  final Widget child;
  const _QuestionFrame({required this.eyebrow, required this.question, required this.helper, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow.toUpperCase(),
              style: GoogleFonts.bricolageGrotesque(
                  fontSize: 12, fontWeight: FontWeight.w500,
                  letterSpacing: 0.72, color: AppColors.clay500)),
          const SizedBox(height: 8),
          Text(question,
              style: GoogleFonts.bricolageGrotesque(
                  fontSize: 30, fontWeight: FontWeight.w600,
                  color: AppColors.ink, letterSpacing: -0.9, height: 1.1)),
          const SizedBox(height: 8),
          Text(helper,
              style: GoogleFonts.notoSans(fontSize: 13, color: AppColors.stone, height: 1.5)),
          const SizedBox(height: 28),
          Expanded(child: child),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }
}

// ─── Q1: species ─────────────────────────────────────────────────────────
class _QuestionSpecies extends StatelessWidget {
  static const _opts = [
    ('dog',      'assets/animations/dog_idle.json',    '🐶', 'Dog'),
    ('cat',      'assets/animations/cat_idle.json',    '🐱', 'Cat'),
    ('rabbit',   'assets/animations/rabbit_idle.json', '🐰', 'Rabbit'),
    ('bird',     'assets/animations/bird_idle.json',   '🐦', 'Bird'),
    ('multiple', null,                                   '🐾', 'I have a few'),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<OnboardingBloc>().state.primarySpecies;
    return _QuestionFrame(
      eyebrow: 'Step 1 of 6',
      question: "Who's your\nfavourite buddy?",
      helper: "We'll preselect your species when adding pets.",
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10, mainAxisSpacing: 10,
        childAspectRatio: 1.1,
        children: _opts.map((o) {
          final active = o.$1 == selected;
          return GestureDetector(
            onTap: () => context.read<OnboardingBloc>().add(OnboardingSpeciesChosen(o.$1)),
            child: AnimatedContainer(
              duration: 160.ms,
              decoration: BoxDecoration(
                color: active ? AppColors.ink : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: active ? AppColors.ink : AppColors.border, width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: active ? Colors.white.withValues(alpha: 0.14) : AppColors.bone,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: o.$2 != null
                          ? Lottie.asset(o.$2!, width: 44, height: 44,
                              errorBuilder: (_, __, ___) => Text(o.$3, style: const TextStyle(fontSize: 28)))
                          : Text(o.$3, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(o.$4, style: GoogleFonts.notoSans(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: active ? AppColors.bone : AppColors.ink)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Q2: pet count ──────────────────────────────────────────────────────
class _QuestionPetCount extends StatelessWidget {
  static const _opts = ['1', '2', '3', '4+'];

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<OnboardingBloc>().state.petCount;
    return _QuestionFrame(
      eyebrow: 'Step 2 of 6',
      question: 'How many pets\nat home?',
      helper: 'Each gets their own vault, with quick switching from Home.',
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10, mainAxisSpacing: 10,
        childAspectRatio: 1.4,
        children: _opts.map((c) {
          final active = c == selected;
          return GestureDetector(
            onTap: () => context.read<OnboardingBloc>().add(OnboardingPetCountChosen(c)),
            child: AnimatedContainer(
              duration: 160.ms,
              decoration: BoxDecoration(
                color: active ? AppColors.ink : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: active ? AppColors.ink : AppColors.border, width: 1.5),
              ),
              child: Center(
                child: Text(c,
                    style: GoogleFonts.bricolageGrotesque(
                        fontSize: 36, fontWeight: FontWeight.w600,
                        color: active ? AppColors.bone : AppColors.ink,
                        letterSpacing: -1)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Q3: priorities (multi-select) ───────────────────────────────────────
class _QuestionPriorities extends StatelessWidget {
  static const _opts = [
    ('vaccines',  LucideIcons.syringe,         'Vaccines'),
    ('meds',      LucideIcons.pill,            'Medications'),
    ('records',   LucideIcons.folderHeart,    'Health records'),
    ('activities', LucideIcons.activity,       'Activities'),
    ('grooming',  LucideIcons.bath,            'Grooming'),
    ('food',      LucideIcons.utensils,        'Food & meals'),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<OnboardingBloc>().state.priorities;
    return _QuestionFrame(
      eyebrow: 'Step 3 of 6',
      question: 'What matters\nmost to you?',
      helper: 'Pick a few — we’ll arrange your home around them.',
      child: ListView(
        children: [
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _opts.map((o) {
              final active = selected.contains(o.$1);
              return GestureDetector(
                onTap: () => context.read<OnboardingBloc>().add(OnboardingPriorityToggled(o.$1)),
                child: AnimatedContainer(
                  duration: 160.ms,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: active ? AppColors.ink : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: active ? AppColors.ink : AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(o.$2, size: 16,
                          color: active ? AppColors.bone : AppColors.clay500),
                      const SizedBox(width: 8),
                      Text(o.$3,
                          style: GoogleFonts.notoSans(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: active ? AppColors.bone : AppColors.ink)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Q4: care time ──────────────────────────────────────────────────────
class _QuestionCareTime extends StatelessWidget {
  static const _opts = [
    ('morning',   LucideIcons.sunrise,  'Morning',   'Before 11am'),
    ('afternoon', LucideIcons.sun,      'Afternoon', '11am – 5pm'),
    ('evening',   LucideIcons.sunset,   'Evening',   'After 5pm'),
    ('anytime',   LucideIcons.clock,    'Anytime',   'Whenever they need it'),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<OnboardingBloc>().state.careTime;
    return _QuestionFrame(
      eyebrow: 'Step 4 of 6',
      question: 'When do you\nlook after them?',
      helper: 'Helps us pick a smart default time for reminders.',
      child: ListView.separated(
        itemCount: _opts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final o = _opts[i];
          final active = o.$1 == selected;
          return GestureDetector(
            onTap: () => context.read<OnboardingBloc>().add(OnboardingCareTimeChosen(o.$1)),
            child: AnimatedContainer(
              duration: 160.ms,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: active ? AppColors.ink : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: active ? AppColors.ink : AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: active ? Colors.white.withValues(alpha: 0.14) : AppColors.clay50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(o.$2, size: 18, color: active ? AppColors.bone : AppColors.clay600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.$3,
                            style: GoogleFonts.notoSans(
                                fontSize: 14, fontWeight: FontWeight.w600,
                                color: active ? AppColors.bone : AppColors.ink)),
                        Text(o.$4,
                            style: GoogleFonts.notoSans(
                                fontSize: 12,
                                color: active ? AppColors.bone.withValues(alpha: 0.7) : AppColors.stone)),
                      ],
                    ),
                  ),
                  if (active) const Icon(LucideIcons.check, size: 18, color: AppColors.bone),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Q5: referral ───────────────────────────────────────────────────────
class _QuestionReferral extends StatelessWidget {
  static const _opts = [
    ('app_store',  LucideIcons.appWindow,   'App Store'),
    ('friend',     LucideIcons.users,       'Friend or family'),
    ('vet',        LucideIcons.stethoscope, 'My vet recommended'),
    ('social',     LucideIcons.share2,            'Social media'),
    ('search',     LucideIcons.search,            'Google search'),
    ('other',      LucideIcons.circleQuestionMark, 'Somewhere else'),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<OnboardingBloc>().state.referralSource;
    return _QuestionFrame(
      eyebrow: 'Step 5 of 6',
      question: 'How did you\nfind PawVault?',
      helper: 'Helps us figure out what’s actually working — thank you.',
      child: ListView.separated(
        itemCount: _opts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (_, i) {
          final o = _opts[i];
          final active = o.$1 == selected;
          return GestureDetector(
            onTap: () => context.read<OnboardingBloc>().add(OnboardingReferralChosen(o.$1)),
            child: AnimatedContainer(
              duration: 160.ms,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: active ? AppColors.ink : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: active ? AppColors.ink : AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(o.$2, size: 18, color: active ? AppColors.bone : AppColors.stone),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(o.$3,
                        style: GoogleFonts.notoSans(
                            fontSize: 14, fontWeight: FontWeight.w500,
                            color: active ? AppColors.bone : AppColors.ink)),
                  ),
                  if (active) const Icon(LucideIcons.check, size: 16, color: AppColors.bone),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Q6: notifications ──────────────────────────────────────────────────
class _QuestionNotifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final enabled = context.watch<OnboardingBloc>().state.notificationsEnabled;
    return _QuestionFrame(
      eyebrow: 'Step 6 of 6',
      question: 'Stay on top of\nevery booster.',
      helper: "We'll only ping you when a vaccine, dose, or vet visit is coming up.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pretty mock notification card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(color: AppColors.ink.withValues(alpha: 0.04),
                    blurRadius: 18, offset: const Offset(0, 6)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.clay50, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(LucideIcons.bell, size: 18, color: AppColors.clay600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PawVault · 8:00 AM',
                          style: GoogleFonts.notoSans(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: AppColors.stone2, letterSpacing: 0.4)),
                      const SizedBox(height: 2),
                      Text('Heartgard Plus — time for the chewable.',
                          style: GoogleFonts.notoSans(
                              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              context.read<OnboardingBloc>().add(const OnboardingNotificationsToggled(true));
              // TODO: request platform notification permission on auth-done screen
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: enabled ? AppColors.ink : AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: enabled ? AppColors.ink : AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(enabled ? LucideIcons.check : LucideIcons.bell,
                      size: 16, color: enabled ? AppColors.bone : AppColors.ink),
                  const SizedBox(width: 8),
                  Text(enabled ? 'Notifications on' : 'Turn on notifications',
                      style: GoogleFonts.notoSans(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: enabled ? AppColors.bone : AppColors.ink)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => context.read<OnboardingBloc>().add(const OnboardingNotificationsToggled(false)),
            child: Center(
              child: Text('Maybe later',
                  style: GoogleFonts.notoSans(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      color: AppColors.stone)),
            ),
          ),
        ],
      ),
    );
  }
}
