part of 'auth_bloc.dart';

abstract class PawAuthState extends Equatable {
  const PawAuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends PawAuthState {}
class AuthLoading extends PawAuthState {}
class AuthSuccess extends PawAuthState {}

class AuthFailure extends PawAuthState {
  final String message;
  const AuthFailure(this.message);
  @override
  List<Object?> get props => [message];
}
