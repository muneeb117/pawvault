import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/medication_model.dart';
import '../../../data/repositories/medication_repository.dart';
import '../bloc/medications_bloc.dart';
import '../../../shared/widgets/pet_switcher.dart';
import '../../pets/cubit/active_pet_cubit.dart';

class MedicationsPage extends StatelessWidget {
  final String? petId;
  const MedicationsPage({super.key, this.petId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivePetCubit, ActivePetState>(
      builder: (context, ap) {
        final id = ap.active?.id ?? petId;
        if (id == null) {
          return Scaffold(
            backgroundColor: AppColors.bone,
            body: SafeArea(child: _NoPetView()),
          );
        }
        return BlocProvider(
          key: ValueKey('meds-$id'),
          create: (_) => MedicationsBloc(MedicationRepository(Supabase.instance.client), petId: id)
            ..add(const MedicationsLoaded()),
          child: _MedsView(petId: id),
        );
      },
    );
  }
}

class _MedsView extends StatelessWidget {
  final String petId;
  const _MedsView({required this.petId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      body: BlocBuilder<MedicationsBloc, MedicationsState>(
        builder: (context, state) {
          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                _TopBar(petId: petId),
                const PetSwitcher(),
                const SizedBox(height: 6),
                Expanded(child: _buildBody(context, state)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, MedicationsState state) {
    if (state is MedicationsLoading || state is MedicationsInitial) {
      return const Center(child: CircularProgressIndicator(color: AppColors.clay500, strokeWidth: 2));
    }
    if (state is MedicationsError) {
      return _ErrorState(message: state.message);
    }
    final s = state as MedicationsReady;
    if (s.list.isEmpty) return _EmptyState(petId: petId);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _TodayCard(meds: s.list)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ACTIVE',
                    style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        letterSpacing: 1.2, color: AppColors.stone2)),
                Text('${s.list.length} medications',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.stone)),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _MedTile(petId: petId, med: s.list[i], index: i),
              childCount: s.list.length,
            ),
          ),
        ),
        if (s.lowRefillCount > 0)
          SliverToBoxAdapter(
            child: _LowRefillBanner(count: s.lowRefillCount),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final String petId;
  const _TopBar({required this.petId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          _IconBtn(onTap: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
              child: const Icon(LucideIcons.chevronLeft, size: 18, color: AppColors.ink)),
          Expanded(
            child: Center(
              child: Text('Medications',
                  style: GoogleFonts.bricolageGrotesque(
                      fontSize: 20, fontWeight: FontWeight.w600,
                      color: AppColors.ink, letterSpacing: -0.5)),
            ),
          ),
          _IconBtn(
            onTap: () => context.push('/pet/$petId/medications/edit'),
            child: const Icon(LucideIcons.plus, size: 18, color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

class _NoPetView extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.pawPrint, size: 36, color: AppColors.stone2),
              const SizedBox(height: 12),
              Text('Add a pet first',
                  style: GoogleFonts.bricolageGrotesque(
                      fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink)),
              const SizedBox(height: 6),
              Text("Meds live under each pet.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.stone)),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => context.go(AppRoutes.addPet),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text('Add pet',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
}

class _TodayCard extends StatelessWidget {
  final List<Medication> meds;
  const _TodayCard({required this.meds});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dueToday = meds.where((m) {
      final n = m.nextDoseAt;
      return n != null && n.year == today.year && n.month == today.month && n.day == today.day;
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TODAY · ${DateFormat('MMM d').format(today).toUpperCase()}',
                      style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          letterSpacing: 1.2, color: AppColors.stone2)),
                  const SizedBox(height: 4),
                  Text('${dueToday.length} dose${dueToday.length == 1 ? '' : 's'} scheduled',
                      style: GoogleFonts.bricolageGrotesque(
                          fontSize: 22, fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          color: AppColors.ink, letterSpacing: -0.5)),
                ],
              ),
            ),
            SizedBox(
              width: 56, height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox(
                    width: 56, height: 56,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      backgroundColor: AppColors.line,
                      valueColor: AlwaysStoppedAnimation(AppColors.ink),
                      strokeWidth: 5,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text('${meds.length}',
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

class _MedTile extends StatelessWidget {
  final String petId;
  final Medication med;
  final int index;
  const _MedTile({required this.petId, required this.med, required this.index});

  IconData _icon() {
    switch (med.category?.toLowerCase()) {
      case 'allergy':     return LucideIcons.pill;
      case 'supplement':  return LucideIcons.droplet;
      case 'heartworm':   return LucideIcons.pill;
      case 'joint':       return LucideIcons.pill;
      default:            return LucideIcons.pill;
    }
  }

  (Color, Color) _colors() {
    switch (med.category?.toLowerCase()) {
      case 'allergy':    return (AppColors.ochre50, AppColors.ochre600);
      case 'supplement': return (AppColors.clay50, AppColors.clay500);
      case 'heartworm':  return (AppColors.rose50, AppColors.rose600);
      case 'joint':      return (AppColors.rose50, AppColors.rose600);
      default:           return (AppColors.rose50, AppColors.rose600);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (tint, fg) = _colors();
    return GestureDetector(
      onTap: () => context.push('/pet/$petId/medications/${med.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)),
              child: Icon(_icon(), size: 18, color: fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(med.name,
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  Text(
                    [
                      if (med.category != null) med.category!,
                      med.frequencyLabel,
                      med.dosage,
                    ].join(' · '),
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.stone),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(LucideIcons.bell, size: 13, color: AppColors.stone2),
                      const SizedBox(width: 4),
                      Text(
                        med.nextDoseAt != null
                            ? 'Next: ${DateFormat('MMM d, h:mm a').format(med.nextDoseAt!)}'
                            : 'No schedule',
                        style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.stone),
                      ),
                      const Spacer(),
                      Text(
                        med.remainingCount != null
                            ? (med.isLowRefill ? 'Low · ${med.remainingCount} left' : '${med.remainingCount} left')
                            : '',
                        style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: med.isLowRefill ? AppColors.rose600 : AppColors.stone),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 60).ms).fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0);
  }
}

class _LowRefillBanner extends StatelessWidget {
  final int count;
  const _LowRefillBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.rose50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.rose100),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: AppColors.rose100, borderRadius: BorderRadius.circular(10)),
              child: const Icon(LucideIcons.triangleAlert, color: AppColors.rose600, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$count medication${count == 1 ? '' : 's'} running low',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.rose600)),
                  Text('Tap a med to update remaining count',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.rose600.withValues(alpha: 0.85))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String petId;
  const _EmptyState({required this.petId});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(color: AppColors.rose50, borderRadius: BorderRadius.circular(20)),
                child: const Icon(LucideIcons.pill, size: 30, color: AppColors.rose600),
              ),
              const SizedBox(height: 20),
              Text('No medications yet',
                  style: GoogleFonts.bricolageGrotesque(
                      fontSize: 24, fontWeight: FontWeight.w600,
                      color: AppColors.ink, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              Text("Add the meds your pet is on so you never\nmiss a dose.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.stone, height: 1.5)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.push('/pet/$petId/medications/edit'),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text('Add medication',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.triangleAlert, size: 36, color: AppColors.rose600),
              const SizedBox(height: 12),
              Text("Couldn't load medications",
                  style: GoogleFonts.bricolageGrotesque(
                      fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink)),
              const SizedBox(height: 6),
              Text(message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.stone)),
            ],
          ),
        ),
      );
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
