import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Brand icon paths — pulled from the Petvault.zip brand pack.
/// Use [AppIcon] widget below to render with auto-tinting.
abstract class AppIcons {
  static const _app = 'assets/brand/icons/app';
  static const _auth = 'assets/brand/icons/auth';
  static const _logos = 'assets/brand/logos';
  static const _animated = 'assets/brand/animated';

  // ── Logos ─────────────────────────────────────────────────────────────
  static const logoMarkPrimary    = '$_logos/mark-primary.svg';
  static const logoMarkInk        = '$_logos/mark-ink.svg';
  static const logoMarkBone       = '$_logos/mark-bone.svg';
  static const logoMarkOutline    = '$_logos/mark-outline.svg';
  static const logoMarkPawClay    = '$_logos/mark-paw-clay.svg';
  static const logoMarkPawInk     = '$_logos/mark-paw-ink.svg';
  static const logoMarkPawBone    = '$_logos/mark-paw-bone.svg';
  static const wordmarkInk        = '$_logos/wordmark-ink.svg';
  static const wordmarkClay       = '$_logos/wordmark-clay.svg';
  static const wordmarkBone       = '$_logos/wordmark-bone.svg';
  static const lockupHorizontal   = '$_logos/lockup-horizontal.svg';
  static const lockupStacked      = '$_logos/lockup-stacked.svg';

  // ── Auth provider icons ───────────────────────────────────────────────
  static const authApple   = '$_auth/auth-apple.svg';
  static const authGoogle  = '$_auth/auth-google.svg';
  static const authEmail   = '$_auth/auth-email.svg';
  static const authPhone   = '$_auth/auth-phone.svg';
  static const authPasskey = '$_auth/auth-passkey.svg';
  static const authGuest   = '$_auth/auth-guest.svg';

  // ── Animated (Lottie) ────────────────────────────────────────────────
  static const pawLoader = '$_animated/paw-loader.lottie.json';
  static const pawStamp  = '$_animated/paw-stamp.lottie.json';

  // ── App icons (every SVG in icons/app/) ───────────────────────────────
  static String app(String name) => '$_app/$name.svg';
}

/// Renders a brand SVG icon with automatic color tinting.
/// Falls back to a Lucide icon if the asset is missing.
class AppIcon extends StatelessWidget {
  final String path;
  final double size;
  final Color? color;
  final IconData? fallback;

  const AppIcon(
    this.path, {
    super.key,
    this.size = 24,
    this.color,
    this.fallback,
  });

  /// Shorthand for `AppIcon(AppIcons.app(name))`.
  factory AppIcon.named(String name, {Key? key, double size = 24, Color? color, IconData? fallback}) =>
      AppIcon(AppIcons.app(name), key: key, size: size, color: color, fallback: fallback);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      path,
      width: size,
      height: size,
      colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
      placeholderBuilder: (_) => SizedBox(width: size, height: size,
          child: Icon(fallback ?? LucideIcons.image, size: size * 0.8, color: color)),
    );
  }
}
