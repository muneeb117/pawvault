import 'dart:math' as math;
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
import '../../../data/models/record_model.dart';
import '../../../data/repositories/records_repository.dart';
import '../bloc/records_bloc.dart';
import '../../../shared/widgets/pet_switcher.dart';
import '../../pets/cubit/active_pet_cubit.dart';

class RecordsPage extends StatelessWidget {
  final String? petId;
  const RecordsPage({super.key, this.petId});

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
          key: ValueKey('records-$id'),
          create: (_) => RecordsBloc(RecordsRepository(Supabase.instance.client), petId: id)
            ..add(const RecordsLoaded()),
          child: _RecordsView(petId: id),
        );
      },
    );
  }
}

class _RecordsView extends StatelessWidget {
  final String petId;
  const _RecordsView({required this.petId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      body: BlocBuilder<RecordsBloc, RecordsState>(
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

  Widget _buildBody(BuildContext context, RecordsState state) {
    if (state is RecordsLoading || state is RecordsInitial) {
      return const Center(child: CircularProgressIndicator(color: AppColors.clay500, strokeWidth: 2));
    }
    if (state is RecordsError) {
      return _ErrorState(message: state.message);
    }
    final s = state as RecordsReady;
    if (s.list.isEmpty) return _EmptyState(petId: petId);

    final groups = s.groupedByMonth.entries.toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _SpendHero(state: s)),
        SliverToBoxAdapter(child: _FilterChips(state: s)),
        for (final g in groups) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(g.key,
                  style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      letterSpacing: 1.2, color: AppColors.stone2)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _RecordRow(petId: petId, record: g.value[i], index: i),
                childCount: g.value.length,
              ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          _IconBtn(onTap: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
              child: const Icon(LucideIcons.chevronLeft, size: 18, color: AppColors.ink)),
          Expanded(
            child: Center(
              child: Text('Records',
                  style: GoogleFonts.bricolageGrotesque(
                      fontSize: 20, fontWeight: FontWeight.w600,
                      color: AppColors.ink, letterSpacing: -0.5)),
            ),
          ),
          _IconBtn(
            onTap: () => context.push('/pet/$petId/records/edit'),
            child: const Icon(LucideIcons.plus, size: 18, color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

class _SpendHero extends StatelessWidget {
  final RecordsReady state;
  const _SpendHero({required this.state});

  @override
  Widget build(BuildContext context) {
    final dollars = state.totalSpentThisYear.toStringAsFixed(0);

    // Build donut segments by type
    final byType = <RecordType, double>{};
    for (final r in state.list) {
      byType[r.type] = (byType[r.type] ?? 0) + (r.cost ?? 0);
    }
    final total = byType.values.fold<double>(0, (a, b) => a + b);
    final segments = byType.entries
        .where((e) => e.value > 0)
        .map((e) => (e.value / (total == 0 ? 1 : total), _colorFor(e.key)))
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(18),
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
                  Text('SPENT THIS YEAR',
                      style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          letterSpacing: 1.2, color: AppColors.stone2)),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(text: '\$$dollars',
                          style: GoogleFonts.bricolageGrotesque(
                              fontSize: 30, fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                              color: AppColors.ink, letterSpacing: -1)),
                      TextSpan(text: '.00',
                          style: GoogleFonts.bricolageGrotesque(
                              fontSize: 14, fontWeight: FontWeight.w500,
                              color: AppColors.stone2)),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  Text('across ${state.list.length} record${state.list.length == 1 ? '' : 's'}',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.stone)),
                ],
              ),
            ),
            SizedBox(
              width: 80, height: 80,
              child: CustomPaint(
                painter: _DonutPainter(segments: segments.isEmpty
                    ? [(1.0, AppColors.line)] : segments),
                child: Center(
                  child: Text('${DateTime.now().year}',
                      style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.stone)),
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 450.ms),
    );
  }

  static Color _colorFor(RecordType t) {
    switch (t) {
      case RecordType.vet: return AppColors.clay500;
      case RecordType.vaccine: return AppColors.ochre500;
      case RecordType.medication: return AppColors.rose500;
      case RecordType.procedure: return AppColors.clay600;
      case RecordType.other: return AppColors.sage500;
    }
  }
}

class _FilterChips extends StatelessWidget {
  final RecordsReady state;
  const _FilterChips({required this.state});

  static const _opts = [
    ('all', 'All'),
    ('vet', 'Vet'),
    ('vaccine', 'Vaccine'),
    ('medication', 'Medication'),
    ('procedure', 'Procedure'),
    ('other', 'Other'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
        children: _opts.map((o) {
          final active = o.$1 == state.filter;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => context.read<RecordsBloc>().add(RecordsFilterChanged(o.$1)),
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

class _RecordRow extends StatelessWidget {
  final String petId;
  final HealthRecord record;
  final int index;
  const _RecordRow({required this.petId, required this.record, required this.index});

  IconData _icon() {
    switch (record.type) {
      case RecordType.vet:        return LucideIcons.stethoscope;
      case RecordType.vaccine:    return LucideIcons.syringe;
      case RecordType.medication: return LucideIcons.pill;
      case RecordType.procedure:  return LucideIcons.heartPulse;
      case RecordType.other:      return LucideIcons.folder;
    }
  }

  (Color, Color) _colors() {
    switch (record.type) {
      case RecordType.vet:        return (AppColors.clay50, AppColors.clay600);
      case RecordType.vaccine:    return (AppColors.ochre50, AppColors.ochre600);
      case RecordType.medication: return (AppColors.rose50, AppColors.rose600);
      case RecordType.procedure:  return (AppColors.clay50, AppColors.clay600);
      case RecordType.other:      return (AppColors.sage50, AppColors.sage600);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (tint, fg) = _colors();
    final docs = record.documentUrls.length;
    return GestureDetector(
      onTap: () => context.push('/pet/$petId/records/${record.id}'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 44,
              child: Column(
                children: [
                  Text(DateFormat('dd').format(record.date),
                      style: GoogleFonts.bricolageGrotesque(
                          fontSize: 22, fontWeight: FontWeight.w600,
                          color: AppColors.ink, height: 1)),
                  const SizedBox(height: 2),
                  Text(DateFormat('MMM').format(record.date).toUpperCase(),
                      style: GoogleFonts.inter(
                          fontSize: 9, fontWeight: FontWeight.w700,
                          letterSpacing: 0.5, color: AppColors.stone2)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(10)),
                      child: Icon(_icon(), size: 16, color: fg),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(record.title,
                              style: GoogleFonts.inter(
                                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                          Text([if (record.clinic != null) record.clinic, if (record.vet != null) record.vet].whereType<String>().join(' · '),
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.stone)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.neutral100,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(record.type.name,
                                    style: GoogleFonts.inter(
                                        fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.ink2)),
                              ),
                              if (docs > 0) ...[
                                const SizedBox(width: 6),
                                const Icon(LucideIcons.fileText, size: 11, color: AppColors.stone2),
                                const SizedBox(width: 2),
                                Text('$docs',
                                    style: GoogleFonts.inter(
                                        fontSize: 10, color: AppColors.stone2, fontWeight: FontWeight.w600)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (record.cost != null) ...[
                      const SizedBox(width: 8),
                      Text('\$${record.cost!.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0);
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
                decoration: BoxDecoration(color: AppColors.clay50, borderRadius: BorderRadius.circular(20)),
                child: const Icon(LucideIcons.folder, size: 30, color: AppColors.clay500),
              ),
              const SizedBox(height: 20),
              Text('No records yet',
                  style: GoogleFonts.bricolageGrotesque(
                      fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.ink, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              Text("Track every vet visit, vaccine receipt\nand procedure in one place.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.stone, height: 1.5)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.push('/pet/$petId/records/edit'),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text('Add record',
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
              Text("Couldn't load records",
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

class _DonutPainter extends CustomPainter {
  final List<(double, Color)> segments;
  _DonutPainter({required this.segments});
  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.0;
    final rect = Rect.fromCircle(
        center: size.center(Offset.zero), radius: (size.shortestSide - stroke) / 2);
    double start = -math.pi / 2;
    for (final (frac, color) in segments) {
      final sweep = frac * 2 * math.pi;
      final paint = Paint()
        ..color = color
        ..strokeWidth = stroke
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start + 0.02, sweep - 0.04, false, paint);
      start += sweep;
    }
  }
  @override
  bool shouldRepaint(_) => false;
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
              Text("Records live under each pet.",
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
