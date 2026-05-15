import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/document_model.dart';
import '../../../data/repositories/documents_repository.dart';
import '../../../shared/widgets/pet_switcher.dart';
import '../../pets/cubit/active_pet_cubit.dart';
import '../bloc/documents_bloc.dart';

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivePetCubit, ActivePetState>(
      builder: (context, ap) {
        final id = ap.active?.id;
        if (id == null) {
          return Scaffold(
            backgroundColor: AppColors.bone,
            body: SafeArea(child: _NoPetView()),
          );
        }
        return BlocProvider(
          key: ValueKey('docs-$id'),
          create: (_) => DocumentsBloc(
              DocumentsRepository(Supabase.instance.client), petId: id)
            ..add(const DocumentsLoaded()),
          child: _DocsView(petId: id),
        );
      },
    );
  }
}

class _DocsView extends StatelessWidget {
  final String petId;
  const _DocsView({required this.petId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(petId: petId),
            const PetSwitcher(),
            const SizedBox(height: 6),
            Expanded(
              child: BlocBuilder<DocumentsBloc, DocumentsState>(
                builder: (context, state) => _buildBody(context, state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DocumentsState state) {
    if (state is DocumentsLoading || state is DocumentsInitial) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.clay500, strokeWidth: 2));
    }
    if (state is DocumentsError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.triangleAlert, size: 36, color: AppColors.rose600),
              const SizedBox(height: 12),
              Text(state.message, textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.stone)),
            ],
          ),
        ),
      );
    }
    final s = state as DocumentsReady;
    if (s.list.isEmpty) return _EmptyState(petId: petId);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _StatsCard(state: s)),
        SliverToBoxAdapter(child: _FilterChips(state: s)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10, mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => _DocCard(doc: s.filtered[i], index: i),
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
              child: Text('Document vault',
                  style: GoogleFonts.bricolageGrotesque(
                      fontSize: 20, fontWeight: FontWeight.w600,
                      color: AppColors.ink, letterSpacing: -0.5)),
            ),
          ),
          _IconBtn(
            onTap: () => context.push('/pet/$petId/documents/upload'),
            child: const Icon(LucideIcons.plus, size: 18, color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final DocumentsReady state;
  const _StatsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final total = state.list.length;
    final extracted = state.list.where((d) => !d.captured.isEmpty).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [AppColors.clay50, AppColors.bone, AppColors.ochre50],
            stops: [0, 0.6, 1],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppColors.ink, borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(LucideIcons.folderLock, color: AppColors.bone, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Your pet's vault",
                      style: GoogleFonts.bricolageGrotesque(
                          fontSize: 20, fontWeight: FontWeight.w600,
                          color: AppColors.ink, letterSpacing: -0.5)),
                  Text(
                    '$total document${total == 1 ? '' : 's'}'
                    '${extracted > 0 ? ' · $extracted auto-extracted' : ''}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.stone),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final DocumentsReady state;
  const _FilterChips({required this.state});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        children: [
          _Chip(label: 'All', active: state.filter == null,
              onTap: () => context.read<DocumentsBloc>().add(const DocumentsFilterChanged(null))),
          for (final t in DocType.values)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: _Chip(
                label: t.label, active: state.filter == t,
                onTap: () => context.read<DocumentsBloc>().add(DocumentsFilterChanged(t)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 180.ms,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.ink : AppColors.ink.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.ink2)),
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  final PetDocument doc;
  final int index;
  const _DocCard({required this.doc, required this.index});

  (IconData, Color, Color) _typeMeta() {
    switch (doc.type) {
      case DocType.vaccineCard:  return (LucideIcons.syringe,        AppColors.clay50,  AppColors.clay600);
      case DocType.labReport:    return (LucideIcons.flaskConical,   AppColors.sage50,  AppColors.sage600);
      case DocType.prescription: return (LucideIcons.pill,           AppColors.rose50,  AppColors.rose600);
      case DocType.insurance:    return (LucideIcons.shieldCheck,    AppColors.ochre50, AppColors.ochre600);
      case DocType.receipt:      return (LucideIcons.receipt,        AppColors.ochre50, AppColors.ochre600);
      case DocType.vetVisit:     return (LucideIcons.stethoscope,    AppColors.clay50,  AppColors.clay600);
      case DocType.other:        return (LucideIcons.fileText,       AppColors.neutral100, AppColors.stone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, tint, fg) = _typeMeta();
    final hasExtract = !doc.captured.isEmpty;

    return GestureDetector(
      onTap: () => context.push('/pet/${doc.petId}/documents/${doc.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: tint),
                  if (doc.isImage && doc.documentUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: doc.thumbnailUrl ?? doc.documentUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Icon(icon, color: fg, size: 36),
                    )
                  else
                    Center(child: Icon(icon, color: fg, size: 36)),
                  if (hasExtract)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.ink.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.sparkles, size: 10, color: AppColors.bone),
                            const SizedBox(width: 3),
                            Text('AI',
                                style: GoogleFonts.inter(
                                    fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.bone)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(
                    '${doc.type.label} · ${DateFormat('MMM d').format(doc.createdAt)}',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.stone),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0);
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                    color: AppColors.clay50, borderRadius: BorderRadius.circular(20)),
                child: const Icon(LucideIcons.folderLock, size: 28, color: AppColors.clay500),
              ),
              const SizedBox(height: 18),
              Text('No documents yet',
                  style: GoogleFonts.bricolageGrotesque(
                      fontSize: 22, fontWeight: FontWeight.w600,
                      color: AppColors.ink, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              Text(
                'Snap a vaccine card or vet receipt — our AI will pull out the\nimportant details for you.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.stone, height: 1.5),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: () => context.push('/pet/$petId/documents/upload'),
                icon: const Icon(LucideIcons.scanLine, size: 16),
                label: Text('Add a document',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
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
