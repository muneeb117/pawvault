part of 'home_bloc.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  @override List<Object?> get props => [];
}

class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {}
class HomeNoPets extends HomeState {}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
  @override List<Object?> get props => [message];
}

class HomeReady extends HomeState {
  final List<Pet> pets;
  final Pet activePet;
  final List<CareEvent> todayEvents;
  final Vaccine? upNextVaccine;

  const HomeReady({
    required this.pets,
    required this.activePet,
    required this.todayEvents,
    this.upNextVaccine,
  });

  int get doneTodayCount => todayEvents.where((e) => e.isDone).length;

  HomeReady copyWith({
    List<Pet>? pets,
    Pet? activePet,
    List<CareEvent>? todayEvents,
    Vaccine? upNextVaccine,
  }) =>
      HomeReady(
        pets: pets ?? this.pets,
        activePet: activePet ?? this.activePet,
        todayEvents: todayEvents ?? this.todayEvents,
        upNextVaccine: upNextVaccine ?? this.upNextVaccine,
      );

  @override
  List<Object?> get props => [pets, activePet, todayEvents, upNextVaccine];
}
