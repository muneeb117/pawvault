import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Single source of truth for image / icon asset paths.
/// Drop your PNG files into the matching folders and they'll show up
/// automatically with a Lucide-icon fallback if the file is missing.
abstract class AppAssets {
  // ── Pet avatars (static fallbacks for Lottie animations) ──────────────
  static const _avatars = 'assets/avatars';
  static String avatar(String species) => '$_avatars/$species.png';

  // ── Onboarding hero illustrations ──────────────────────────────────────
  static const _illustrations = 'assets/illustrations';
  static String welcome(int idx) => '$_illustrations/welcome_$idx.png';

  // ── Care category icons (Quick Care row, etc.) ────────────────────────
  static const _care = 'assets/icons/care';
  static String careIcon(String key) => '$_care/$key.png';

  // ── Auth provider logos ───────────────────────────────────────────────
  static const _auth = 'assets/icons/auth';
  static const googleLogo = '$_auth/google.png';
  static const appleLogo  = '$_auth/apple.png';

  // ── Onboarding question icons ─────────────────────────────────────────
  static const _onb = 'assets/icons/onboarding';
  static String onboardingIcon(String key) => '$_onb/$key.png';
}

/// Renders an image asset, falls back to a Lucide icon if the file is
/// missing or hasn't been added yet. Lets the user drop in images at
/// their own pace without breaking the app.
class AppImage extends StatelessWidget {
  final String assetPath;
  final double size;
  final IconData fallback;
  final Color? color;
  final BoxFit fit;

  const AppImage({
    super.key,
    required this.assetPath,
    required this.size,
    this.fallback = LucideIcons.image,
    this.color,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size, height: size,
      color: color, fit: fit,
      errorBuilder: (_, __, ___) => Icon(fallback, size: size * 0.7, color: color),
    );
  }
}
