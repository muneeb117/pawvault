import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/router_helpers.dart';
import '../../../core/assets/app_icons.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/utils/paw_snackbar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _busy = false;

  AuthRepository get _repo => AuthRepository(Supabase.instance.client);

  Future<void> _signOut() async {
    final ok = await _confirm(
      title: 'Sign out?',
      body: "We'll keep your vault safe — just sign in again when you're back.",
      confirmLabel: 'Sign out',
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _repo.signOut();
      // Keep onboarding_done = true; existing users land on auth, not onboarding.
      if (mounted) context.go(AppRoutes.authLanding);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount() async {
    final ok = await _confirm(
      title: 'Delete your account?',
      body: 'This permanently deletes your vault, pets and records. This cannot be undone.',
      confirmLabel: 'Delete forever',
      destructive: true,
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _repo.deleteAccount();
      // Account is gone — bring user back through onboarding as a fresh start.
      await AppFlags.setOnboardingDone(false);
      if (mounted) {
        showPawSuccess(context, 'Your account has been deleted.');
        context.go(AppRoutes.onboarding);
      }
    } catch (e) {
      if (!mounted) return;
      showPawError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.bone,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.bricolageGrotesque(
                      fontSize: 22, fontWeight: FontWeight.w600,
                      color: AppColors.ink, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text(body,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.stone, height: 1.5)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      child: Text('Cancel',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: destructive ? AppColors.rose600 : AppColors.ink,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      child: Text(confirmLabel,
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'no email';
    final fullName = (user?.userMetadata?['full_name'] as String?) ?? '';
    final initials = _initialsOf(fullName.isNotEmpty ? fullName : email);

    return Scaffold(
      backgroundColor: AppColors.bone,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // ── Header ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(
                  children: [
                    Text('Profile',
                        style: GoogleFonts.bricolageGrotesque(
                            fontSize: 24, fontWeight: FontWeight.w600,
                            color: AppColors.ink, letterSpacing: -0.6)),
                    const Spacer(),
                    _IconBtn(
                      icon: AppIcons.app('settings'),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),

            // ── Identity card ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [AppColors.clay50, AppColors.bone, AppColors.ochre50],
                      stops: [0, 0.6, 1],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.clay500,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Text(initials,
                              style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 22, fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(fullName.isNotEmpty ? fullName : 'Pet parent',
                                style: GoogleFonts.bricolageGrotesque(
                                    fontSize: 22, fontWeight: FontWeight.w600,
                                    color: AppColors.ink, letterSpacing: -0.5)),
                            const SizedBox(height: 2),
                            Text(email,
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: AppColors.stone)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Text('Free plan',
                                  style: GoogleFonts.inter(
                                      fontSize: 11, fontWeight: FontWeight.w600,
                                      color: AppColors.ink2)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
              ),
            ),

            // ── Section: Account ───────────────────────────────────
            SliverToBoxAdapter(child: _SectionLabel('ACCOUNT')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SettingsCard(rows: [
                  _SettingsRow(
                    icon: AppIcons.app('user'),
                    label: 'Edit profile',
                    onTap: () {},
                  ),
                  _SettingsRow(
                    icon: AppIcons.app('mail'),
                    label: 'Email',
                    trailingText: email,
                    onTap: () {},
                  ),
                  _SettingsRow(
                    icon: AppIcons.app('lock'),
                    label: 'Change password',
                    onTap: () {},
                  ),
                ]),
              ),
            ),

            // ── Section: Care ──────────────────────────────────────
            SliverToBoxAdapter(child: _SectionLabel('CARE')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SettingsCard(rows: [
                  _SettingsRow(
                    icon: AppIcons.app('paw'),
                    label: 'My pets',
                    onTap: () {},
                  ),
                  _SettingsRow(
                    icon: AppIcons.app('folder'),
                    label: 'Document vault',
                    onTap: () => context.push(AppRoutes.documents),
                  ),
                  _SettingsRow(
                    icon: AppIcons.app('bell'),
                    label: 'Notifications',
                    onTap: () => context.push(AppRoutes.notifications),
                  ),
                  _SettingsRow(
                    icon: AppIcons.app('shield-check'),
                    label: 'Privacy',
                    onTap: () {},
                  ),
                ]),
              ),
            ),

            // ── Section: Pro ───────────────────────────────────────
            SliverToBoxAdapter(child: _SectionLabel('UPGRADE')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.proUpgrade),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.clay50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.clay100),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.clay500,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const AppIcon(
                            AppIcons.lockupHorizontal,
                            size: 22, color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PawVault Pro',
                                  style: GoogleFonts.bricolageGrotesque(
                                      fontSize: 16, fontWeight: FontWeight.w600,
                                      color: AppColors.clay700)),
                              Text('Unlimited pets · AI vet · Smart reminders',
                                  style: GoogleFonts.inter(
                                      fontSize: 11, color: AppColors.clay600)),
                            ],
                          ),
                        ),
                        const AppIcon(
                          AppIcons.lockupHorizontal,
                          size: 14, color: AppColors.clay600,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Section: Help ──────────────────────────────────────
            SliverToBoxAdapter(child: _SectionLabel('SUPPORT')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SettingsCard(rows: [
                  _SettingsRow(
                    icon: AppIcons.app('help'),
                    label: 'Help & FAQ',
                    onTap: () {},
                  ),
                  _SettingsRow(
                    icon: AppIcons.app('message'),
                    label: 'Contact support',
                    onTap: () {},
                  ),
                  _SettingsRow(
                    icon: AppIcons.app('info'),
                    label: 'About PawVault',
                    onTap: () {},
                  ),
                ]),
              ),
            ),

            // ── Section: Danger zone ───────────────────────────────
            SliverToBoxAdapter(child: _SectionLabel('DANGER ZONE')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _SettingsCard(rows: [
                  _SettingsRow(
                    icon: AppIcons.app('arrow-right'),
                    label: 'Sign out',
                    destructive: false,
                    busy: _busy,
                    onTap: _signOut,
                  ),
                  _SettingsRow(
                    icon: AppIcons.app('trash'),
                    label: 'Delete account',
                    destructive: true,
                    busy: _busy,
                    onTap: _deleteAccount,
                  ),
                ]),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 120, top: 8),
                child: Center(
                  child: Text('v1.0.0',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.stone3)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initialsOf(String s) {
    final clean = s.trim();
    if (clean.isEmpty) return '?';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }
}

class _IconBtn extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(child: AppIcon(icon, size: 18, color: AppColors.ink)),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 16, 20, 8),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w700,
                letterSpacing: 1.2, color: AppColors.stone2)),
      );
}

class _SettingsRow {
  final String icon, label;
  final String? trailingText;
  final bool destructive;
  final bool busy;
  final VoidCallback onTap;
  _SettingsRow({
    required this.icon,
    required this.label,
    this.trailingText,
    this.destructive = false,
    this.busy = false,
    required this.onTap,
  });
}

class _SettingsCard extends StatelessWidget {
  final List<_SettingsRow> rows;
  const _SettingsCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final r = entry.value;
          return GestureDetector(
            onTap: r.busy ? null : r.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                border: i < rows.length - 1
                    ? const Border(bottom: BorderSide(color: AppColors.line2))
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: r.destructive ? AppColors.rose50 : AppColors.clay50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: AppIcon(
                        r.icon, size: 16,
                        color: r.destructive ? AppColors.rose600 : AppColors.clay600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(r.label,
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w500,
                            color: r.destructive ? AppColors.rose600 : AppColors.ink)),
                  ),
                  if (r.trailingText != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(r.trailingText!,
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.stone2),
                          overflow: TextOverflow.ellipsis),
                    ),
                  if (r.busy)
                    const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.stone),
                    )
                  else
                    AppIcon(AppIcons.app('chevron-right'),
                        size: 14, color: AppColors.stone3),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
