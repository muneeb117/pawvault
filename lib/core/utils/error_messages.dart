import 'dart:io';
import 'package:postgrest/postgrest.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Translates raw exceptions and error objects into short, friendly,
/// user-facing messages. Always returns something safe to show in a snackbar
/// or empty state — never leaks stack traces, package names, or HTTP codes.
String friendlyError(Object error) {
  // ── Apple Sign-In ─────────────────────────────────────────────────────
  if (error is SignInWithAppleAuthorizationException) {
    switch (error.code) {
      case AuthorizationErrorCode.canceled:
        return 'Sign-in cancelled.';
      case AuthorizationErrorCode.notHandled:
        return "Apple couldn't complete sign-in. Please try again.";
      case AuthorizationErrorCode.invalidResponse:
        return 'Apple sent an unexpected response. Try again in a moment.';
      case AuthorizationErrorCode.failed:
        return "Apple sign-in failed. Make sure you're signed into iCloud, then try again.";
      case AuthorizationErrorCode.notInteractive:
      // case AuthorizationErrorCode.credentialExport:
      // case AuthorizationErrorCode.credentialImport:
      // case AuthorizationErrorCode.matchedExcludedCredential:
      case AuthorizationErrorCode.unknown:
        return "Apple sign-in isn't available right now. Please try again or use Google / email.";
    }
  }
  if (error is SignInWithAppleException) {
    return "Apple sign-in didn't work. Please try Google or email.";
  }

  // ── Supabase Auth ─────────────────────────────────────────────────────
  if (error is AuthException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      return 'Wrong email or password.';
    }
    if (msg.contains('already registered') || msg.contains('user already')) {
      return 'That email is already in use. Try signing in instead.';
    }
    if (msg.contains('password should be at least')) {
      return 'Password must be at least 6 characters.';
    }
    if (msg.contains('invalid email')) {
      return "That email doesn't look right.";
    }
    if (msg.contains('email not confirmed')) {
      return 'Please confirm your email before signing in.';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Too many attempts. Wait a minute and try again.';
    }
    if (msg.contains('provider is not enabled') || msg.contains('not enabled')) {
      return "That sign-in method isn't enabled yet. Try email instead.";
    }
    return _capitalise(error.message);
  }

  // ── Supabase Postgrest (database) ─────────────────────────────────────
  if (error is PostgrestException) {
    final code = error.code;
    final msg = error.message;
    if (code == 'PGRST205' || msg.contains('schema cache') || msg.contains('Could not find the table')) {
      return "Your vault isn't set up yet. Run supabase/schema.sql in your Supabase project.";
    }
    if (msg.contains('row-level security') || msg.contains('RLS')) {
      return "Couldn't save — please sign in again.";
    }
    if (code == '23505') return 'That already exists.';
    if (code == '23503') return "That can't be deleted while other records reference it.";
    if (msg.contains('JWT expired')) return 'Your session expired. Please sign in again.';
    return _capitalise(msg);
  }

  // ── Storage ───────────────────────────────────────────────────────────
  if (error is StorageException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('payload too large')) return 'That file is too large.';
    if (msg.contains('not found')) return "File doesn't exist.";
    return 'Upload failed. Please try again.';
  }

  // ── Network ───────────────────────────────────────────────────────────
  if (error is SocketException) {
    return 'No internet connection. Reconnect and try again.';
  }
  if (error is HttpException) {
    return 'Network error. Please try again.';
  }
  if (error is FormatException) {
    return 'Got an unexpected response. Please try again.';
  }

  // ── Generic string-based hints (manually thrown strings, etc.) ────────
  final raw = error.toString();
  final lower = raw.toLowerCase();
  if (lower.contains('cancelled') || lower.contains('canceled')) return 'Cancelled.';
  if (lower.contains('no api key') || lower.contains('openai key')) {
    return 'AI Assistant needs an API key. Add it in app_constants.dart.';
  }
  if (lower.contains('anonymous sign-in')) {
    return 'Anonymous sign-in is off. Enable it in Supabase → Auth → Providers.';
  }
  if (lower.contains('no active session') || lower.contains('jwt')) {
    return 'Your session expired. Please sign in again.';
  }

  // ── Fallback ──────────────────────────────────────────────────────────
  // Strip "Exception:" prefix and trim very long messages.
  final cleaned = raw
      .replaceFirst(RegExp(r'^(Exception|Error|FlutterError):\s*'), '')
      .replaceFirst(RegExp(r'^[A-Za-z_]+Exception\([^)]*\)\s*'), '');
  if (cleaned.isEmpty) return "Something went wrong. Please try again.";
  if (cleaned.length > 120) return "Something went wrong. Please try again.";
  return _capitalise(cleaned);
}

String _capitalise(String s) {
  final t = s.trim();
  if (t.isEmpty) return t;
  return t[0].toUpperCase() + t.substring(1);
}
