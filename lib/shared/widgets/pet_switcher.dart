import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../features/pets/cubit/active_pet_cubit.dart';
import 'pet_avatar_widget.dart';

/// Compact horizontally-scrolling pet chip row.
/// Drop in the top of any per-pet screen (Vaccines / Records / Meds / Care / AI).
/// Tapping a chip updates the global [ActivePetCubit], which propagates to all
/// other screens.
///
/// When [onSelected] is provided it's called instead of changing the cubit —
/// useful for nested per-screen logic (e.g. AI chat reset).
class PetSwitcher extends StatelessWidget {
  final ValueChanged<String>? onSelected;

  /// Optional explicit selected id — when null, uses ActivePetCubit's active.
  final String? selectedId;

  const PetSwitcher({super.key, this.onSelected, this.selectedId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivePetCubit, ActivePetState>(
      builder: (context, s) {
        if (s.pets.isEmpty) return const SizedBox.shrink();
        final activeId = selectedId ?? s.activeId;

        return SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: s.pets.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              if (i == s.pets.length) {
                return GestureDetector(
                  onTap: () => context.go(AppRoutes.addPet),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.stone2, width: 1.4),
                    ),
                    child: const Icon(LucideIcons.plus, size: 16, color: AppColors.stone2),
                  ),
                );
              }

              final pet = s.pets[i];
              final active = pet.id == activeId;
              return GestureDetector(
                onTap: () {
                  if (onSelected != null) {
                    onSelected!(pet.id);
                  } else {
                    context.read<ActivePetCubit>().setActive(pet.id);
                  }
                },
                child: AnimatedContainer(
                  duration: 180.ms,
                  padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                  decoration: BoxDecoration(
                    color: active ? AppColors.ink : Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: active ? AppColors.ink : AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 28, height: 28,
                        child: ClipOval(
                          child: PetAvatarWidget(pet: pet, size: 28, showMoodRing: false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        pet.name,
                        style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: active ? Colors.white : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
