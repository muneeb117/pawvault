import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import 'error_messages.dart';

enum PawSnackKind { error, success, info }

/// Shows a floating, themed snackbar with consistent design.
void showPawSnack(
  BuildContext context, {
  required String message,
  PawSnackKind kind = PawSnackKind.info,
  Duration duration = const Duration(seconds: 4),
}) {
  final (bg, icon) = switch (kind) {
    PawSnackKind.error   => (AppColors.ink, LucideIcons.triangleAlert),
    PawSnackKind.success => (AppColors.sage600, LucideIcons.check),
    PawSnackKind.info    => (AppColors.ink, LucideIcons.info),
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: duration,
    ));
}

/// Shorthand for showing an error snack — runs the message through
/// [friendlyError] so callers can pass raw exceptions.
void showPawError(BuildContext context, Object error) {
  showPawSnack(context, message: friendlyError(error), kind: PawSnackKind.error);
}

void showPawSuccess(BuildContext context, String message) {
  showPawSnack(context, message: message, kind: PawSnackKind.success);
}
