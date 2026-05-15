import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/assets/app_assets.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/user_preferences_repository.dart';
import '../../../data/models/user_preferences_model.dart';
import '../bloc/auth_bloc.dart';

class AuthLandingPage extends StatelessWidget {
  const AuthLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(AuthRepository(Supabase.instance.client)),
      child: const _AuthLandingView(),
    );
  }
}

class _AuthLandingView extends StatelessWidget {
  const _AuthLandingView();

  Future<void> _savePrefsAndGo(BuildContext context) async {
    final sp = await SharedPreferences.getInstance();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      try {
        await UserPreferencesRepository(Supabase.instance.client).upsert(
          UserPreferences(
            userId: userId,
            primarySpecies: sp.getString('onboard_primary_species'),
            petCount: sp.getString('onboard_pet_count'),
            priorities: sp.getStringList('onboard_priorities') ?? const [],
            careTime: sp.getString('onboard_care_time'),
            referralSource: sp.getString('onboard_referral'),
            notificationsEnabled: sp.getBool('onboard_notifs') ?? false,
          ),
        );
      } catch (_) {/* non-fatal */}
    }
    if (context.mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, PawAuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) _savePrefsAndGo(context);
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        }
      },
      builder: (context, state) {
        final loading = state is AuthLoading;
        return Scaffold(
          backgroundColor: AppColors.bone,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                children: [
                  // Logo top-left
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                              color: AppColors.ink, borderRadius: BorderRadius.circular(7)),
                          child: const Icon(LucideIcons.pawPrint, color: AppColors.bone, size: 14),
                        ),
                        const SizedBox(width: 7),
                        Text('PawVault',
                            style: GoogleFonts.bricolageGrotesque(
                                fontSize: 17, fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.italic, color: AppColors.ink2,
                                letterSpacing: -0.3)),
                      ],
                    ),
                  ),

                  // Hero
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: Container(
                        width: 220, height: 220,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [AppColors.clay50, AppColors.ochre50],
                          ),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Stack(
                          children: [
                            Positioned(top: 16, left: 18,
                                child: Icon(LucideIcons.pawPrint, size: 28,
                                    color: AppColors.ink.withValues(alpha: 0.06))),
                            Positioned(bottom: 16, right: 18,
                                child: Icon(LucideIcons.pawPrint, size: 22,
                                    color: AppColors.ink.withValues(alpha: 0.06))),
                            Center(
                              child: Lottie.asset(
                                'assets/animations/dog_happy.json',
                                width: 170, height: 170,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(LucideIcons.pawPrint, size: 80, color: AppColors.clay500),
                              ),
                            ),
                          ],
                        ),
                      ).animate().scale(
                          begin: const Offset(0.85, 0.85),
                          end: const Offset(1, 1),
                          duration: 500.ms, curve: Curves.elasticOut),
                    ),
                  ),

                  // Headline
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CREATE YOUR ACCOUNT',
                          style: GoogleFonts.bricolageGrotesque(
                              fontSize: 12, fontWeight: FontWeight.w500,
                              letterSpacing: 0.72, color: AppColors.clay500)),
                      const SizedBox(height: 8),
                      Text('Save every wag.\nIn one cozy vault.',
                          style: GoogleFonts.bricolageGrotesque(
                              fontSize: 28, fontWeight: FontWeight.w600,
                              color: AppColors.ink, letterSpacing: -0.9, height: 1.05)),
                      const SizedBox(height: 8),
                      Text("Sign in to sync across devices and never lose a record.",
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.stone, height: 1.5)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Apple — uses assets/icons/auth/apple.png if present
                  _AuthButton(
                    iconWidget: const AppImage(
                      assetPath: AppAssets.appleLogo,
                      size: 18,
                      fallback: LucideIcons.apple,
                      color: AppColors.bone,
                    ),
                    label: 'Continue with Apple',
                    bg: AppColors.ink, fg: AppColors.bone,
                    loading: loading,
                    onTap: () => context.read<AuthBloc>().add(const AuthAppleSignInRequested()),
                  ),
                  const SizedBox(height: 10),

                  // Google — uses assets/icons/auth/google.png if present, falls back to painted glyph
                  _AuthButton(
                    iconWidget: SizedBox(
                      width: 18, height: 18,
                      child: Image.asset(
                        AppAssets.googleLogo,
                        errorBuilder: (_, __, ___) => const _GoogleGlyph(),
                      ),
                    ),
                    label: 'Continue with Google',
                    bg: AppColors.surface, fg: AppColors.ink,
                    bordered: true,
                    loading: loading,
                    onTap: () => context.read<AuthBloc>().add(const AuthGoogleSignInRequested()),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.line)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('or',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.stone2)),
                      ),
                      const Expanded(child: Divider(color: AppColors.line)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: loading ? null : () => context.push(AppRoutes.signUp),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Continue with email',
                            style: GoogleFonts.inter(
                                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                          ),
                          const WidgetSpan(child: SizedBox(width: 6)),
                          const WidgetSpan(child: Icon(LucideIcons.arrowRight, size: 14, color: AppColors.ink)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text.rich(
                      TextSpan(
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.stone2, height: 1.5),
                        children: const [
                          TextSpan(text: 'By continuing you agree to our '),
                          TextSpan(text: 'Terms', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.stone)),
                          TextSpan(text: ' and '),
                          TextSpan(text: 'Privacy Policy', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.stone)),
                          TextSpan(text: '.'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AuthButton extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final Color bg, fg;
  final bool bordered;
  final bool loading;
  final VoidCallback onTap;

  const _AuthButton({
    this.icon,
    this.iconWidget,
    required this.label,
    required this.bg,
    required this.fg,
    this.bordered = false,
    this.loading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: bordered
                ? const BorderSide(color: AppColors.border)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconWidget != null) iconWidget!
            else if (icon != null) Icon(icon, size: 18, color: fg),
            const SizedBox(width: 10),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w600, color: fg)),
          ],
        ),
      ),
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();
  @override
  Widget build(BuildContext context) {
    // Minimal "G" mark — 4 quadrants in Google's brand colors.
    return SizedBox(
      width: 18, height: 18,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = Offset(r, r);
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -0.6, 1.8, true, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), 1.2, 1.6, true, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), 2.8, 1.5, true, paint);
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), 4.3, 1.4, true, paint);

    // White center cut-out — gives the "G" the hole.
    paint.color = Colors.white;
    canvas.drawCircle(c, r * 0.4, paint);
    // Blue tick on the right side (simplified)
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(Rect.fromLTWH(r, r * 0.85, r, r * 0.30), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
