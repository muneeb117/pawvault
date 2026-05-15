import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Synchronous app-wide flags so the GoRouter `redirect` callback never has
/// to await SharedPreferences — that's the source of the bounce-back bug.
class AppFlags {
  static bool onboardingDone = false;

  static Future<void> hydrate() async {
    try {
      final sp = await SharedPreferences.getInstance();
      onboardingDone = sp.getBool('onboarding_done') ?? false;
    } catch (_) {}
  }

  static Future<void> setOnboardingDone(bool v) async {
    onboardingDone = v;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool('onboarding_done', v);
    } catch (_) {}
  }
}

/// Bridges a Stream to a Listenable so GoRouter can re-evaluate `redirect`
/// whenever Supabase auth state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Wrapper Listenable that combines Supabase auth changes.
class AuthRefreshNotifier extends ChangeNotifier {
  late final StreamSubscription _sub;
  AuthRefreshNotifier() {
    try {
      _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
        notifyListeners();
      });
    } catch (_) {
      _sub = const Stream<dynamic>.empty().listen((_) {});
    }
  }
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
