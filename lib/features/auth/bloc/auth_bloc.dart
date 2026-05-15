import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/utils/error_messages.dart';
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
      emit(AuthFailure(friendlyError(e)));
    }
  }

  Future<void> _onSignUp(AuthSignUpRequested event, Emitter<PawAuthState> emit) async {
    emit(AuthLoading());
    try {
      await _repo.signUpWithEmail(
          email: event.email, password: event.password, fullName: event.fullName);
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(friendlyError(e)));
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
      emit(AuthFailure(friendlyError(e)));
    }
  }

  Future<void> _onAppleSignIn(
      AuthAppleSignInRequested event, Emitter<PawAuthState> emit) async {
    emit(AuthLoading());
    try {
      await _repo.signInWithApple();
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(friendlyError(e)));
    }
  }
}
