import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';

/// Bone+ink themed form field — used in all add/edit screens.
class PawFormField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final TextEditingController? controller;
  final String? value;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool obscure;
  final int? maxLines;
  final Widget? trailing;
  final bool readOnly;

  const PawFormField({
    super.key,
    required this.icon,
    required this.label,
    required this.hint,
    this.controller,
    this.value,
    this.onTap,
    this.onChanged,
    this.keyboardType,
    this.obscure = false,
    this.maxLines = 1,
    this.trailing,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final isTappable = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 10, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Icon(icon, size: 18, color: AppColors.stone),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          letterSpacing: 0.5, color: AppColors.stone)),
                  const SizedBox(height: 2),
                  if (isTappable)
                    Text(value ?? hint,
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w500,
                            color: value == null ? AppColors.stone2 : AppColors.ink))
                  else
                    TextField(
                      controller: controller,
                      keyboardType: keyboardType,
                      obscureText: obscure,
                      maxLines: maxLines,
                      readOnly: readOnly,
                      onChanged: onChanged,
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
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
            if (trailing != null) trailing!,
            if (isTappable && trailing == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(LucideIcons.chevronRight, size: 16, color: AppColors.stone2),
              ),
          ],
        ),
      ),
    );
  }
}

class PawFormSelector<T> extends StatelessWidget {
  final String label;
  final List<T> options;
  final T? selected;
  final String Function(T) labelFor;
  final ValueChanged<T> onChanged;

  const PawFormSelector({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.labelFor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w700,
                letterSpacing: 1.2, color: AppColors.stone2)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: options.map((o) {
            final active = o == selected;
            return GestureDetector(
              onTap: () => onChanged(o),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppColors.ink : AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: active ? AppColors.ink : AppColors.border),
                ),
                child: Text(labelFor(o),
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w500,
                        color: active ? AppColors.bone : AppColors.ink)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Big save / primary action button used in edit screens.
class PawPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final Color? color;
  const PawPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.ink,
          disabledBackgroundColor: (color ?? AppColors.ink).withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
        child: loading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(color: AppColors.bone, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.bone)),
                  if (icon != null) ...[
                    const SizedBox(width: 6),
                    Icon(icon, size: 16, color: AppColors.bone),
                  ],
                ],
              ),
      ),
    );
  }
}

class PawAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? eyebrow;
  final List<Widget> actions;
  final VoidCallback? onBack;
  const PawAppBar({super.key, required this.title, this.eyebrow, this.actions = const [], this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(58);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            GestureDetector(
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border)),
                child: const Icon(LucideIcons.chevronLeft, size: 18, color: AppColors.ink),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  if (eyebrow != null)
                    Text(eyebrow!.toUpperCase(),
                        style: GoogleFonts.inter(
                            fontSize: 10, fontWeight: FontWeight.w700,
                            letterSpacing: 1.2, color: AppColors.stone2)),
                  Text(title,
                      style: GoogleFonts.bricolageGrotesque(
                          fontSize: 20, fontWeight: FontWeight.w600,
                          color: AppColors.ink, letterSpacing: -0.5)),
                ],
              ),
            ),
            ...actions,
            if (actions.isEmpty) const SizedBox(width: 36),
          ],
        ),
      ),
    );
  }
}
