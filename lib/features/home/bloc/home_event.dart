part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override List<Object?> get props => [];
}

class HomeLoaded extends HomeEvent {
  final String userId;
  const HomeLoaded(this.userId);
  @override List<Object?> get props => [userId];
}

class HomePetSwitched extends HomeEvent {
  final String petId;
  const HomePetSwitched(this.petId);
  @override List<Object?> get props => [petId];
}

class HomeAvatarMoodToggled extends HomeEvent {
  const HomeAvatarMoodToggled();
}

class HomeCareEventToggled extends HomeEvent {
  final String eventId;
  const HomeCareEventToggled(this.eventId);
  @override List<Object?> get props => [eventId];
}
