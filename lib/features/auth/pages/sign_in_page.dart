import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/paw_snackbar.dart';
import '../../../data/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(AuthRepository(Supabase.instance.client)),
      child: const _SignInView(),
    );
  }
}

class _SignInView extends StatefulWidget {
  const _SignInView();
  @override
  State<_SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<_SignInView> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool get _valid => _emailCtrl.text.contains('@') && _passCtrl.text.length >= 6;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, PawAuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) context.go(AppRoutes.home);
        if (state is AuthFailure) {
          showPawSnack(context, message: state.message, kind: PawSnackKind.error);
        }
      },
      builder: (context, state) {
        final loading = state is AuthLoading;
        return Scaffold(
          backgroundColor: AppColors.bone,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.canPop() ? context.pop() : context.go(AppRoutes.authLanding),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border)),
                      child: const Icon(LucideIcons.arrowLeft, size: 16, color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('WELCOME BACK',
                      style: GoogleFonts.bricolageGrotesque(
                          fontSize: 12, fontWeight: FontWeight.w500,
                          letterSpacing: 0.72, color: AppColors.clay500)),
                  const SizedBox(height: 8),
                  Text('Sign in to\nyour vault.',
                      style: GoogleFonts.bricolageGrotesque(
                          fontSize: 34, fontWeight: FontWeight.w600,
                          color: AppColors.ink, letterSpacing: -1.2, height: 1.05)),
                  const SizedBox(height: 28),

                  _Field(
                    icon: LucideIcons.mail, label: 'EMAIL', hint: 'name@example.com',
                    controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  _Field(
                    icon: LucideIcons.lock, label: 'PASSWORD', hint: 'Your password',
                    controller: _passCtrl, obscure: _obscure,
                    onChanged: (_) => setState(() {}),
                    suffix: IconButton(
                      icon: Icon(_obscure ? LucideIcons.eye : LucideIcons.eyeOff,
                          size: 16, color: AppColors.stone),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: !_valid || loading ? null : () {
                        context.read<AuthBloc>().add(AuthSignInRequested(
                              email: _emailCtrl.text, password: _passCtrl.text,
                            ));
                      },
                      child: loading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(color: AppColors.bone, strokeWidth: 2))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Sign in',
                                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 6),
                                const Icon(LucideIcons.arrowRight, size: 16),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Center(
                    child: GestureDetector(
                      onTap: () => context.go(AppRoutes.signUp),
                      child: Text.rich(
                        TextSpan(
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.stone),
                          children: [
                            const TextSpan(text: "No account yet? "),
                            TextSpan(
                              text: 'Sign up',
                              style: GoogleFonts.inter(
                                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
                            ),
                          ],
                        ),
                      ),
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

class _Field extends StatelessWidget {
  final IconData icon;
  final String label, hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

  const _Field({
    required this.icon, required this.label, required this.hint,
    required this.controller, this.keyboardType, this.obscure = false,
    this.suffix, this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.stone),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    letterSpacing: 0.5, color: AppColors.stone)),
                const SizedBox(height: 2),
                TextField(
                  controller: controller, keyboardType: keyboardType,
                  obscureText: obscure, onChanged: onChanged,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.stone2),
                    border: InputBorder.none, enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none, isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          if (suffix != null) suffix!,
        ],
      ),
    );
  }
}
