import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
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
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (showMoodRing)
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.clay50, width: 3),
                ),
              ),
            ClipOval(
              child: Container(
                width: size * 0.9,
                height: size * 0.9,
                color: AppColors.clay50,
                child: pet.photoUrl != null
                    ? _PhotoAvatar(url: pet.photoUrl!, size: size * 0.9)
                    : _LottieAvatar(pet: pet, size: size * 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LottieAvatar extends StatelessWidget {
  final Pet pet;
  final double size;

  const _LottieAvatar({required this.pet, required this.size});

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      pet.lottieAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _FallbackAvatar(pet: pet, size: size),
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
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.pets, color: AppColors.clay500),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  final Pet pet;
  final double size;

  const _FallbackAvatar({required this.pet, required this.size});

  static const _emojiMap = {
    PetSpecies.dog: '🐶',
    PetSpecies.cat: '🐱',
    PetSpecies.rabbit: '🐰',
    PetSpecies.bird: '🐦',
  };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        _emojiMap[pet.species] ?? '🐾',
        style: TextStyle(fontSize: size * 0.5),
      ),
    );
  }
}

// Mood selector row used in Add Pet and Profile screens
class MoodSelectorRow extends StatelessWidget {
  final AvatarMood selected;
  final ValueChanged<AvatarMood> onChanged;

  const MoodSelectorRow({
    super.key,
    required this.selected,
    required this.onChanged,
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
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.bone : AppColors.clay500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
