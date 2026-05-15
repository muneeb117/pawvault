import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client;
  AuthRepository(this._client);

  static const _googleIosClientId =
      '228960742403-l4ia55bm2c9qmvkcr8gqum28t3o7pp4k.apps.googleusercontent.com';

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ── Email / password ──────────────────────────────────────────────────
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) => _client.auth.signInWithPassword(email: email.trim(), password: password);

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) => _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: fullName != null && fullName.isNotEmpty
            ? {'full_name': fullName.trim()}
            : null,
      );

  // ── Sign in with Apple (native, via id_token) ─────────────────────────
  Future<AuthResponse> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw 'Apple did not return an identity token.';
    }

    final res = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );

    // First-time Apple sign-in returns the user's real name; store it.
    final fullName = [credential.givenName, credential.familyName]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');
    if (fullName.isNotEmpty && res.user != null) {
      try {
        await _client.auth.updateUser(UserAttributes(data: {'full_name': fullName}));
      } catch (_) {}
    }
    return res;
  }

  // ── Sign in with Google (native, via id_token) ────────────────────────
  Future<AuthResponse> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      clientId: _googleIosClientId,
      scopes: const ['email', 'profile', 'openid'],
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw 'Sign-in cancelled.';
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw 'Google did not return an ID token.';
    }

    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn(clientId: _googleIosClientId).signOut();
    } catch (_) {}
    await _client.auth.signOut();
  }

  String _generateNonce([int length = 32]) {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._';
    final rand = Random.secure();
    return List.generate(length, (_) => charset[rand.nextInt(charset.length)]).join();
  }
}
