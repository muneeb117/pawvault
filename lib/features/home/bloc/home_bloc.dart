import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/pet_model.dart';
import '../../../data/models/care_event_model.dart';
import '../../../data/models/vaccine_model.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../data/repositories/vaccine_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<Vaccine?> _fetchNextVaccine(String petId) async {
    try {
      final repo = VaccineRepository(Supabase.instance.client);
      final list = await repo.getVaccines(petId);
      if (list.isEmpty) return null;
      final upcoming = list.where((v) => v.status != VaccineStatus.overdue).toList()
        ..sort((a, b) => a.nextDue.compareTo(b.nextDue));
      if (upcoming.isNotEmpty) return upcoming.first;
      // Otherwise return the most-overdue (smallest nextDue)
      list.sort((a, b) => a.nextDue.compareTo(b.nextDue));
      return list.first;
    } catch (_) {
      return null;
    }
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
      final active = pets.first;
      final nextV = await _fetchNextVaccine(active.id);
      emit(HomeReady(
        pets: pets,
        activePet: active,
        todayEvents: const [],
        upNextVaccine: nextV,
      ));
    } catch (e) {
      // ignore: avoid_print
      print('HomeBloc load error: $e');
      emit(HomeNoPets());
    }
  }

  Future<void> _onPetSwitched(HomePetSwitched event, Emitter<HomeState> emit) async {
    if (state is! HomeReady) return;
    final s = state as HomeReady;
    final pet = s.pets.firstWhere((p) => p.id == event.petId, orElse: () => s.activePet);
    final nextV = await _fetchNextVaccine(pet.id);
    emit(s.copyWith(activePet: pet, upNextVaccine: nextV, clearUpNext: nextV == null));
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
}
