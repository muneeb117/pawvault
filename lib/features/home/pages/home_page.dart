import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/home_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/pet_model.dart';
import '../../../data/models/care_event_model.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../shared/widgets/pet_avatar_widget.dart';

// ── Supabase import wrapped so it compiles without credentials ─────────────
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        String userId = '';
        try { userId = Supabase.instance.client.auth.currentUser?.id ?? ''; } catch (_) {}
        return HomeBloc(PetRepository(Supabase.instance.client))
          ..add(HomeLoaded(userId));
      },
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading || state is HomeInitial) {
          return const Scaffold(
            backgroundColor: AppColors.bone,
            body: Center(child: CircularProgressIndicator(color: AppColors.clay500, strokeWidth: 2)),
          );
        }
        if (state is HomeNoPets) return const _NoPetsView();
        if (state is HomeError) {
          return Scaffold(backgroundColor: AppColors.bone,
              body: Center(child: Text((state as HomeError).message)));
        }
        return _ReadyView(state: state as HomeReady);
      },
    );
  }
}

// ─── No pets ────────────────────────────────────────────────────────────────
class _NoPetsView extends StatelessWidget {
  const _NoPetsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: AppColors.clay50, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.pets_rounded, color: AppColors.clay500, size: 28),
              ),
              const SizedBox(height: 24),
              Text('Add your first pet',
                  style: GoogleFonts.bricolageGrotesque(fontSize: 30, fontWeight: FontWeight.w600,
                      color: AppColors.ink, letterSpacing: -0.8)),
              const SizedBox(height: 8),
              Text('Start building their health vault.',
                  style: GoogleFonts.inter(fontSize: 15, color: AppColors.stone, height: 1.5)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.addPet),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.add_rounded, size: 18),
                    const SizedBox(width: 6),
                    Text('Add Pet', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Main ready view ────────────────────────────────────────────────────────
class _ReadyView extends StatelessWidget {
  final HomeReady state;
  const _ReadyView({required this.state});

  @override
  Widget build(BuildContext context) {
    // User info
    String firstName = 'Jack';
    String initials = 'JS';
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final name = user?.userMetadata?['full_name'] as String? ?? '';
      if (name.isNotEmpty) {
        final parts = name.trim().split(' ');
        firstName = parts.first;
        initials = parts.length >= 2
            ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
            : parts[0].substring(0, 2).toUpperCase();
      }
    } catch (_) {}

    final dayLabel = DateFormat("EEE · MMM d").format(DateTime.now()).toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.bone,
      body: CustomScrollView(
        slivers: [
          // ── Greeting app bar ──────────────────────────────────────
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dayLabel,
                              style: GoogleFonts.inter(
                                  fontSize: 11, fontWeight: FontWeight.w500,
                                  color: AppColors.stone2, letterSpacing: 0.06 * 11)),
                          const SizedBox(height: 2),
                          Text('Hi $firstName.',
                              style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 26, fontWeight: FontWeight.w600,
                                  color: AppColors.ink, letterSpacing: -0.8, height: 1.1))
                              .animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Bell with badge
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.notifications),
                      child: Stack(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(Icons.notifications_outlined, size: 18, color: AppColors.ink),
                          ),
                          Positioned(
                            top: 7, right: 7,
                            child: Container(
                              width: 7, height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.clay500, shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // User avatar circle
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.clay500, borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(initials,
                            style: GoogleFonts.inter(
                                fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Pet switcher chips ──────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: state.pets.length + 1,
                itemBuilder: (_, i) {
                  if (i == state.pets.length) {
                    return GestureDetector(
                      onTap: () => context.go(AppRoutes.addPet),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.stone2, width: 1.5,
                              style: BorderStyle.solid),
                        ),
                        child: const Icon(Icons.add_rounded, size: 18, color: AppColors.stone2),
                      ),
                    );
                  }
                  final pet = state.pets[i];
                  final active = pet.id == state.activePet.id;
                  return GestureDetector(
                    onTap: () => context.read<HomeBloc>().add(HomePetSwitched(pet.id)),
                    child: AnimatedContainer(
                      duration: 200.ms,
                      padding: const EdgeInsets.fromLTRB(6, 5, 14, 5),
                      decoration: BoxDecoration(
                        color: active ? AppColors.ink : Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: active ? AppColors.ink : AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Pet thumbnail
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: active ? Colors.white.withValues(alpha: 0.18) : AppColors.sage100,
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: PetAvatarWidget(pet: pet, size: 28, showMoodRing: false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(pet.name,
                              style: GoogleFonts.inter(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: active ? Colors.white : AppColors.ink)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  // ── Hero pet card ──────────────────────────────
                  _PetHeroCard(pet: state.activePet),
                  const SizedBox(height: 14),

                  // ── Up next alert ──────────────────────────────
                  _UpNextCard(),
                  const SizedBox(height: 18),

                  // ── Quick care ─────────────────────────────────
                  _QuickCareRow(petId: state.activePet.id),
                  const SizedBox(height: 20),

                  // ── Today ──────────────────────────────────────
                  _TodaySection(events: state.todayEvents, doneCount: state.doneTodayCount),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero pet card ───────────────────────────────────────────────────────────
class _PetHeroCard extends StatelessWidget {
  final Pet pet;
  const _PetHeroCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.clay50, AppColors.bone, AppColors.ochre50],
          stops: [0, 0.6, 1],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Stack(
        children: [
          // Paw watermark — top right
          Positioned(
            right: -18, top: -18,
            child: Icon(Icons.pets, size: 140, color: AppColors.ink.withValues(alpha: 0.06)),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meta row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('YOUR BUDDY',
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600,
                                  color: AppColors.stone2, letterSpacing: 0.1 * 10)),
                          const SizedBox(height: 6),
                          Text(pet.name,
                              style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 40, fontWeight: FontWeight.w600,
                                  color: AppColors.ink, letterSpacing: -1.4, height: 0.95)),
                          const SizedBox(height: 4),
                          Text('${pet.breed} · ${pet.gender ?? ''}',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.stone)),
                        ],
                      ),
                    ),
                    // Edit pill
                    GestureDetector(
                      onTap: () => context.push('/pet/${pet.id}'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.ink.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit_outlined, size: 12, color: AppColors.ink2),
                            const SizedBox(width: 4),
                            Text('Edit', style: GoogleFonts.inter(
                                fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.ink2)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Stats + avatar row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Wrap(spacing: 6, runSpacing: 6, children: [
                              _StatPill(icon: Icons.cake_outlined, value: pet.ageLabel),
                              if (pet.weightKg != null)
                                _StatPill(icon: Icons.monitor_weight_outlined,
                                    value: '${(pet.weightKg! * 2.205).toStringAsFixed(0)} lbs'),
                            ]),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => context.read<HomeBloc>().add(const HomeAvatarMoodToggled()),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: AppColors.ink.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.auto_awesome_outlined, size: 12, color: AppColors.stone),
                                    const SizedBox(width: 6),
                                    Text('Tap ${pet.name} to play',
                                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.stone)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Avatar — right side, bottom aligned
                    GestureDetector(
                      onTap: () => context.read<HomeBloc>().add(const HomeAvatarMoodToggled()),
                      child: SizedBox(
                        width: 150, height: 150,
                        child: PetAvatarWidget(pet: pet, size: 150, showMoodRing: false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.04, end: 0);
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  const _StatPill({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.stone),
          const SizedBox(width: 5),
          Text(value, style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink2)),
        ],
      ),
    );
  }
}

// ─── Up Next ─────────────────────────────────────────────────────────────────
class _UpNextCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.ochre50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ochre100),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.ochre100),
            ),
            child: const Icon(Icons.vaccines_outlined, size: 20, color: AppColors.ochre600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UP NEXT · IN 12 DAYS',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600,
                        color: AppColors.ochre600, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text('Rabies booster — May 27',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                Text('Happy Paws Vet · Dr. Nguyen',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.stone)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.stone2),
        ],
      ),
    );
  }
}

// ─── Quick Care ───────────────────────────────────────────────────────────────
class _QuickCareRow extends StatelessWidget {
  final String petId;
  const _QuickCareRow({required this.petId});

  static const _actions = [
    (Icons.medical_services_outlined, 'Vet',  AppColors.clay50,   AppColors.clay600),
    (Icons.medication_outlined,        'Meds', AppColors.rose50,   AppColors.rose600),
    (Icons.directions_walk_rounded,    'Walk', AppColors.sage50,   AppColors.sage600),
    (Icons.restaurant_outlined,        'Meal', AppColors.ochre50,  AppColors.ochre600),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('QUICK CARE',
                style: GoogleFonts.bricolageGrotesque(fontSize: 12, fontWeight: FontWeight.w500,
                    letterSpacing: 0.06 * 12, color: AppColors.stone)),
            const Spacer(),
            GestureDetector(
              onTap: () {},
              child: Text('Customize',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.stone)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: _actions.asMap().entries.map((e) {
            final a = e.value;
            return Expanded(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  margin: EdgeInsets.only(
                    left: e.key == 0 ? 0 : 4,
                    right: e.key == _actions.length - 1 ? 0 : 4,
                  ),
                  padding: const EdgeInsets.fromLTRB(6, 14, 6, 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: a.$3, borderRadius: BorderRadius.circular(10)),
                        child: Icon(a.$1, size: 18, color: a.$4),
                      ),
                      const SizedBox(height: 6),
                      Text(a.$2, style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.ink)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Today Section ────────────────────────────────────────────────────────────
class _TodaySection extends StatelessWidget {
  final List<CareEvent> events;
  final int doneCount;
  const _TodaySection({required this.events, required this.doneCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('TODAY',
                style: GoogleFonts.bricolageGrotesque(fontSize: 12, fontWeight: FontWeight.w500,
                    letterSpacing: 0.06 * 12, color: AppColors.stone)),
            const Spacer(),
            Text('$doneCount of ${events.length} done',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.stone)),
          ],
        ),
        const SizedBox(height: 10),

        if (events.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.sage500, size: 18),
                const SizedBox(width: 10),
                Text('All caught up for today!',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.stone)),
              ],
            ),
          )
        else
          // Single card wrapping all rows
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: events.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                return _TodayRow(
                  event: e,
                  showDivider: i < events.length - 1,
                  onTap: () => context.read<HomeBloc>().add(HomeCareEventToggled(e.id)),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _TodayRow extends StatelessWidget {
  final CareEvent event;
  final bool showDivider;
  final VoidCallback onTap;
  const _TodayRow({required this.event, required this.showDivider, required this.onTap});

  static const _typeData = {
    CareEventType.medication: (AppColors.rose500,  AppColors.rose50),
    CareEventType.walk:       (AppColors.sage500,  AppColors.sage50),
    CareEventType.meal:       (AppColors.ochre500, AppColors.ochre50),
    CareEventType.vet:        (AppColors.clay500,  AppColors.clay50),
    CareEventType.vaccine:    (AppColors.clay500,  AppColors.clay50),
    CareEventType.activity:   (AppColors.sage500,  AppColors.sage50),
  };

  @override
  Widget build(BuildContext context) {
    final data = _typeData[event.type];
    final accent = data?.$1 ?? AppColors.stone;
    final tint   = data?.$2 ?? AppColors.neutral100;
    final isDone = event.isDone;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                // Accent bar
                Container(
                  width: 3, height: 36,
                  decoration: BoxDecoration(
                    color: isDone ? accent.withValues(alpha: 0.35) : accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 12),
                // Icon tile
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: isDone ? AppColors.neutral100 : tint,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(_iconFor(event.type), size: 16,
                      color: isDone ? AppColors.stone2 : accent),
                ),
                const SizedBox(width: 12),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w500,
                          color: isDone ? AppColors.stone : AppColors.ink,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          decorationColor: AppColors.stone,
                        ),
                      ),
                      if (event.subtitle != null)
                        Text(
                          event.subtitle!,
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.stone2),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Circle check
                AnimatedContainer(
                  duration: 200.ms,
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? AppColors.ink : Colors.transparent,
                    border: isDone ? null : Border.all(color: AppColors.stone3, width: 1.5),
                  ),
                  child: isDone
                      ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
          if (showDivider)
            Divider(height: 1, thickness: 1, color: AppColors.line2,
                indent: 14 + 3 + 12 + 32 + 12, endIndent: 0),
        ],
      ),
    );
  }

  IconData _iconFor(CareEventType t) {
    switch (t) {
      case CareEventType.medication: return Icons.medication_outlined;
      case CareEventType.walk:       return Icons.directions_walk_rounded;
      case CareEventType.meal:       return Icons.restaurant_outlined;
      case CareEventType.vet:        return Icons.medical_services_outlined;
      case CareEventType.vaccine:    return Icons.vaccines_outlined;
      case CareEventType.activity:   return Icons.sports_soccer_outlined;
    }
  }
}
