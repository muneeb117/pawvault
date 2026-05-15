import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/pet_model.dart';
import '../../core/theme/app_colors.dart';

class PetAvatarWidget extends StatelessWidget {
  final Pet pet;
  final double size;
  final bool showMoodRing;
  final VoidCallback? onTap;

  const PetAvatarWidget({
    super.key,
    required this.pet,
    this.size = 120,
    this.showMoodRing = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size, height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (showMoodRing)
              Container(
                width: size, height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.clay50, width: 3),
                ),
              ),
            ClipOval(
              child: Container(
                width: size * 0.9, height: size * 0.9,
                color: _speciesTint(pet.species),
                child: pet.photoUrl != null
                    ? _PhotoAvatar(url: pet.photoUrl!, size: size * 0.9)
                    : _AnimatedAvatar(pet: pet, size: size * 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _speciesTint(PetSpecies s) => switch (s) {
    PetSpecies.dog    => AppColors.clay50,
    PetSpecies.cat    => AppColors.ochre50,
    PetSpecies.rabbit => AppColors.sage50,
    PetSpecies.bird   => AppColors.rose50,
  };
}

class _AnimatedAvatar extends StatelessWidget {
  final Pet pet;
  final double size;
  const _AnimatedAvatar({required this.pet, required this.size});

  @override
  Widget build(BuildContext context) {
    // Try species-specific Lottie first (drop your files in assets/animations/).
    // If missing, fall back to the brand animated paw + species tint.
    return Lottie.asset(
      pet.lottieAsset,
      width: size, height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _BrandPawAvatar(pet: pet, size: size),
    );
  }
}

/// Animated brand paw shown when species-specific Lottie files are missing.
/// The brand paw is the same across species but the tinted halo (set by the
/// parent) keeps each species visually distinct.
class _BrandPawAvatar extends StatelessWidget {
  final Pet pet;
  final double size;
  const _BrandPawAvatar({required this.pet, required this.size});

  @override
  Widget build(BuildContext context) {
    final Widget paw = Lottie.asset(
      'assets/brand/animated/paw-idle.lottie.json',
      width: size, height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _EmojiPawFallback(pet: pet, size: size),
    );
    return Padding(
      padding: EdgeInsets.all(size * 0.18),
      child: paw
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 0.95, end: 1.05, duration: 1800.ms, curve: Curves.easeInOut),
    );
  }
}

/// Last-resort static fallback if even the brand Lottie can't load.
/// Animated bounce so it still feels alive.
class _EmojiPawFallback extends StatelessWidget {
  final Pet pet;
  final double size;
  const _EmojiPawFallback({required this.pet, required this.size});

  static const _emoji = {
    PetSpecies.dog: '🐶',
    PetSpecies.cat: '🐱',
    PetSpecies.rabbit: '🐰',
    PetSpecies.bird: '🐦',
  };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        _emoji[pet.species] ?? '🐾',
        style: TextStyle(fontSize: size * 0.5),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
       .moveY(begin: -2, end: 2, duration: 1600.ms, curve: Curves.easeInOut),
    );
  }
}

class _PhotoAvatar extends StatelessWidget {
  final String url;
  final double size;
  const _PhotoAvatar({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url, width: size, height: size, fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.pets, color: AppColors.clay500),
    );
  }
}

// Mood selector row used in Add Pet and Profile screens
class MoodSelectorRow extends StatelessWidget {
  final AvatarMood selected;
  final ValueChanged<AvatarMood> onChanged;

  const MoodSelectorRow({
    super.key, required this.selected, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: AvatarMood.values.map((mood) {
        final isSelected = mood == selected;
        return GestureDetector(
          onTap: () => onChanged(mood),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.clay500 : AppColors.clay50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              mood.name[0].toUpperCase() + mood.name.substring(1),
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.bone : AppColors.clay500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
