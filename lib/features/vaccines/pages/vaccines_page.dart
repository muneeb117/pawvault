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
import '../../../data/models/vaccine_model.dart';
import '../../../data/repositories/vaccine_repository.dart';
import '../bloc/vaccines_bloc.dart';
import '../../../shared/widgets/pet_switcher.dart';
import '../../pets/cubit/active_pet_cubit.dart';

/// Pet-scoped vaccines list. If [petId] is provided, used directly.
/// Otherwise reads the globally active pet from [ActivePetCubit].
class VaccinesPage extends StatelessWidget {
  final String? petId;
  const VaccinesPage({super.key, this.petId});

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
          key: ValueKey('vaccines-$id'),
          create: (_) => VaccinesBloc(VaccineRepository(Supabase.instance.client), petId: id)
            ..add(const VaccinesLoaded()),
          child: _VaccinesView(petId: id),
        );
      },
    );
  }
}

class _VaccinesView extends StatelessWidget {
  final String petId;
  const _VaccinesView({required this.petId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      body: BlocBuilder<VaccinesBloc, VaccinesState>(
        builder: (context, state) {
          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                _TopBar(petId: petId),
                const PetSwitcher(),
                const SizedBox(height: 6),
                Expanded(
                  child: _buildBody(context, state),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, VaccinesState state) {
    if (state is VaccinesLoading || state is VaccinesInitial) {
      return const Center(child: CircularProgressIndicator(color: AppColors.clay500, strokeWidth: 2));
    }
    if (state is VaccinesError) {
      return _ErrorState(message: state.message);
    }
    final s = state as VaccinesReady;

    if (s.list.isEmpty) return _EmptyState(petId: petId);

    return CustomScrollView(
      slivers: [
        if (s.nextDue != null)
          SliverToBoxAdapter(child: _NextBoosterCard(vaccine: s.nextDue!)),
        SliverToBoxAdapter(child: _SummaryRow(state: s)),
        SliverToBoxAdapter(child: _FilterChips(state: s)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _VaccineTile(petId: petId, vaccine: s.filtered[i], index: i),
              childCount: s.filtered.length,
            ),
          ),
        ),
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
          _IconBtn(
            onTap: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
            child: const Icon(LucideIcons.chevronLeft, size: 18, color: AppColors.ink),
          ),
          Expanded(
            child: Center(
              child: Text('Vaccines',
                  style: GoogleFonts.bricolageGrotesque(
                      fontSize: 20, fontWeight: FontWeight.w600,
                      color: AppColors.ink, letterSpacing: -0.5)),
            ),
          ),
          _IconBtn(
            onTap: () => context.push('/pet/$petId/vaccines/edit'),
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
              Text("Vaccines, meds and records live under each pet.",
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

class _NextBoosterCard extends StatelessWidget {
  final Vaccine vaccine;
  const _NextBoosterCard({required this.vaccine});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
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
              right: -12, top: -10,
              child: Transform.rotate(
                angle: 0.5,
                child: Icon(LucideIcons.syringe, size: 130,
                    color: Colors.white.withValues(alpha: 0.18)),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NEXT BOOSTER',
                    style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 0.6)),
                const SizedBox(height: 4),
                Text('${vaccine.name} — ${vaccine.dueLabelShort}',
                    style: GoogleFonts.bricolageGrotesque(
                        fontSize: 26, fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        letterSpacing: -0.5, height: 1.05)),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('EEE, MMM d').format(vaccine.nextDue)}${vaccine.clinic != null ? ' · ${vaccine.clinic}' : ''}',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.05, end: 0),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final VaccinesReady state;
  const _SummaryRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Row(
        children: [
          Expanded(child: _SummaryTile(count: state.upCount, label: 'Up to date', color: AppColors.sage500)),
          const SizedBox(width: 8),
          Expanded(child: _SummaryTile(count: state.dueCount, label: 'Due soon', color: AppColors.clay500)),
          const SizedBox(width: 8),
          Expanded(child: _SummaryTile(count: state.overCount, label: 'Overdue', color: AppColors.rose500)),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _SummaryTile({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(height: 6),
          Text('$count',
              style: GoogleFonts.bricolageGrotesque(
                  fontSize: 24, fontWeight: FontWeight.w600,
                  color: AppColors.ink, height: 1, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.stone)),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final VaccinesReady state;
  const _FilterChips({required this.state});

  static const _opts = [
    ('all', 'All'),
    ('upcoming', 'Due soon'),
    ('upToDate', 'Up to date'),
    ('overdue', 'Overdue'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
        children: _opts.map((o) {
          final active = o.$1 == state.filter;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => context.read<VaccinesBloc>().add(VaccinesFilterChanged(o.$1)),
              child: AnimatedContainer(
                duration: 180.ms,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? AppColors.ink : AppColors.ink.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Center(
                  child: Text(o.$2,
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: active ? Colors.white : AppColors.ink2)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _VaccineTile extends StatelessWidget {
  final String petId;
  final Vaccine vaccine;
  final int index;
  const _VaccineTile({required this.petId, required this.vaccine, required this.index});

  @override
  Widget build(BuildContext context) {
    final s = vaccine.status;
    final (chipLabel, chipBg, chipFg) = switch (s) {
      VaccineStatus.dueSoon  => ('Due soon',   AppColors.clay50, AppColors.clay600),
      VaccineStatus.overdue  => ('Overdue',    AppColors.rose50, AppColors.rose600),
      VaccineStatus.upToDate => ('Up to date', AppColors.sage100, AppColors.sage600),
    };
    final remColor = s == VaccineStatus.overdue
        ? AppColors.rose600
        : (s == VaccineStatus.dueSoon ? AppColors.clay600 : AppColors.stone);

    return GestureDetector(
      onTap: () => context.push('/pet/$petId/vaccines/${vaccine.id}'),
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
              decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(12)),
              child: Transform.rotate(
                angle: 0.5,
                child: Icon(LucideIcons.syringe, size: 18, color: chipFg),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(vaccine.name,
                            style: GoogleFonts.inter(
                                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(999)),
                        child: Text(chipLabel,
                            style: GoogleFonts.inter(
                                fontSize: 10, fontWeight: FontWeight.w600, color: chipFg)),
                      ),
                    ],
                  ),
                  if (vaccine.description != null && vaccine.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(vaccine.description!,
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.stone)),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Last', style: GoogleFonts.inter(fontSize: 10, color: AppColors.stone2)),
                            Text(DateFormat('MMM d, yyyy').format(vaccine.lastGiven),
                                style: GoogleFonts.inter(
                                    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Next', style: GoogleFonts.inter(fontSize: 10, color: AppColors.stone2)),
                            Text(DateFormat('MMM d, yyyy').format(vaccine.nextDue),
                                style: GoogleFonts.inter(
                                    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
                          ],
                        ),
                      ),
                      Text(vaccine.dueLabelShort,
                          style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w600, color: remColor)),
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

class _EmptyState extends StatelessWidget {
  final String petId;
  const _EmptyState({required this.petId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: AppColors.clay50, borderRadius: BorderRadius.circular(20)),
              child: Transform.rotate(
                angle: 0.5,
                child: const Icon(LucideIcons.syringe, size: 30, color: AppColors.clay500),
              ),
            ),
            const SizedBox(height: 20),
            Text('No vaccines yet',
                style: GoogleFonts.bricolageGrotesque(
                    fontSize: 24, fontWeight: FontWeight.w600,
                    color: AppColors.ink, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text('Add your first vaccine record to stay\non top of every booster.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.stone, height: 1.5)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/pet/$petId/vaccines/edit'),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: Text('Add vaccine',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
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
              Text("Couldn't load vaccines",
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
