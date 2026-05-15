import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, PawAuthState> {
  final AuthRepository _repo;

  AuthBloc(this._repo) : super(AuthInitial()) {
    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthAppleSignInRequested>(_onAppleSignIn);
  }

  Future<void> _onSignIn(AuthSignInRequested event, Emitter<PawAuthState> emit) async {
    emit(AuthLoading());
    try {
      await _repo.signInWithEmail(email: event.email, password: event.password);
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(_friendly(e)));
    }
  }

  Future<void> _onSignUp(AuthSignUpRequested event, Emitter<PawAuthState> emit) async {
    emit(AuthLoading());
    try {
      await _repo.signUpWithEmail(
          email: event.email, password: event.password, fullName: event.fullName);
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(_friendly(e)));
    }
  }

  Future<void> _onSignOut(AuthSignOutRequested event, Emitter<PawAuthState> emit) async {
    await _repo.signOut();
    emit(AuthInitial());
  }

  Future<void> _onGoogleSignIn(
      AuthGoogleSignInRequested event, Emitter<PawAuthState> emit) async {
    emit(AuthLoading());
    try {
      await _repo.signInWithGoogle();
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(_friendly(e)));
    }
  }

  Future<void> _onAppleSignIn(
      AuthAppleSignInRequested event, Emitter<PawAuthState> emit) async {
    emit(AuthLoading());
    try {
      await _repo.signInWithApple();
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(_friendly(e)));
    }
  }

  String _friendly(Object e) {
    final raw = e.toString();
    if (raw.contains('cancelled')) return 'Sign-in cancelled.';
    if (raw.contains('Invalid login')) return 'Wrong email or password.';
    if (raw.contains('already registered') || raw.contains('User already')) {
      return 'That email is already in use. Try signing in.';
    }
    if (raw.contains('Password should be')) return 'Password must be at least 6 characters.';
    if (raw.contains('email_address_invalid') || raw.contains('Invalid email')) {
      return "That email doesn't look right.";
    }
    return raw.length > 140 ? '${raw.substring(0, 140)}…' : raw;
  }
}
