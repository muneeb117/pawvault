import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/pet_model.dart';
import '../../../data/models/care_event_model.dart';
import '../../../data/models/vaccine_model.dart';
import '../../../data/repositories/pet_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final PetRepository _petRepo;

  HomeBloc(this._petRepo) : super(HomeInitial()) {
    on<HomeLoaded>(_onLoaded);
    on<HomePetSwitched>(_onPetSwitched);
    on<HomeAvatarMoodToggled>(_onMoodToggled);
    on<HomeCareEventToggled>(_onCareEventToggled);
  }

  Future<void> _onLoaded(HomeLoaded event, Emitter<HomeState> emit) async {
    emit(HomeLoading());

    if (event.userId.isEmpty) {
      emit(HomeNoPets());
      return;
    }

    try {
      final pets = await _petRepo.getPets(event.userId);
      if (pets.isEmpty) {
        emit(HomeNoPets());
        return;
      }
      emit(HomeReady(
        pets: pets,
        activePet: pets.first,
        todayEvents: _todayEventsFor(pets.first.id),
        upNextVaccine: null,
      ));
    } catch (e) {
      // Show the empty state rather than a giant error banner.
      // Real error is logged for debugging.
      // ignore: avoid_print
      print('HomeBloc load error: $e');
      emit(HomeNoPets());
    }
  }

  void _onPetSwitched(HomePetSwitched event, Emitter<HomeState> emit) {
    if (state is! HomeReady) return;
    final s = state as HomeReady;
    final pet = s.pets.firstWhere((p) => p.id == event.petId, orElse: () => s.activePet);
    emit(s.copyWith(activePet: pet, todayEvents: _todayEventsFor(pet.id)));
  }

  void _onMoodToggled(HomeAvatarMoodToggled event, Emitter<HomeState> emit) {
    if (state is! HomeReady) return;
    final s = state as HomeReady;
    final moods = AvatarMood.values;
    final next = moods[(moods.indexOf(s.activePet.mood) + 1) % moods.length];
    final updatedPet = s.activePet.copyWith(mood: next);
    emit(s.copyWith(
      activePet: updatedPet,
      pets: s.pets.map((p) => p.id == updatedPet.id ? updatedPet : p).toList(),
    ));
  }

  void _onCareEventToggled(HomeCareEventToggled event, Emitter<HomeState> emit) {
    if (state is! HomeReady) return;
    final s = state as HomeReady;
    final updated = s.todayEvents.map((e) {
      return e.id == event.eventId ? e.copyWith(isDone: !e.isDone) : e;
    }).toList();
    emit(s.copyWith(todayEvents: updated));
  }

  // Until care_events are wired to Supabase, return empty.
  List<CareEvent> _todayEventsFor(String petId) => const [];
}
