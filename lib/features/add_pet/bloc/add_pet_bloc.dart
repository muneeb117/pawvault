import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/pet_model.dart';
import '../../../data/repositories/pet_repository.dart';

part 'add_pet_event.dart';
part 'add_pet_state.dart';

class AddPetBloc extends Bloc<AddPetEvent, AddPetState> {
  final PetRepository _repo;

  AddPetBloc(this._repo) : super(AddPetState()) {
    on<AddPetSpeciesSelected>(_onSpeciesSelected);
    on<AddPetMoodSelected>(_onMoodSelected);
    on<AddPetNameChanged>(_onNameChanged);
    on<AddPetBreedChanged>(_onBreedChanged);
    on<AddPetDobChanged>(_onDobChanged);
    on<AddPetGenderChanged>(_onGenderChanged);
    on<AddPetPhotoSelected>(_onPhotoSelected);
    on<AddPetStepAdvanced>(_onStepAdvanced);
    on<AddPetStepBacked>(_onStepBacked);
    on<AddPetSubmitted>(_onSubmitted);
  }

  void _onSpeciesSelected(AddPetSpeciesSelected e, Emitter<AddPetState> emit) =>
      emit(state.copyWith(species: e.species));

  void _onMoodSelected(AddPetMoodSelected e, Emitter<AddPetState> emit) =>
      emit(state.copyWith(mood: e.mood));

  void _onNameChanged(AddPetNameChanged e, Emitter<AddPetState> emit) =>
      emit(state.copyWith(name: e.name));

  void _onBreedChanged(AddPetBreedChanged e, Emitter<AddPetState> emit) =>
      emit(state.copyWith(breed: e.breed));

  void _onDobChanged(AddPetDobChanged e, Emitter<AddPetState> emit) =>
      emit(state.copyWith(dob: e.dob));

  void _onGenderChanged(AddPetGenderChanged e, Emitter<AddPetState> emit) =>
      emit(state.copyWith(gender: e.gender));

  void _onPhotoSelected(AddPetPhotoSelected e, Emitter<AddPetState> emit) =>
      emit(state.copyWith(photoBytes: e.bytes, photoExt: e.ext));

  void _onStepAdvanced(AddPetStepAdvanced e, Emitter<AddPetState> emit) =>
      emit(state.copyWith(step: state.step + 1));

  void _onStepBacked(AddPetStepBacked e, Emitter<AddPetState> emit) =>
      emit(state.copyWith(step: state.step - 1));

  Future<void> _onSubmitted(AddPetSubmitted e, Emitter<AddPetState> emit) async {
    emit(state.copyWith(status: AddPetStatus.loading));
    try {
      // Resolve user id from active Supabase session if not provided.
      String userId = e.userId;
      if (userId.isEmpty) {
        try {
          userId = Supabase.instance.client.auth.currentUser?.id ?? '';
        } catch (_) {}
      }
      if (userId.isEmpty) {
        throw 'Anonymous sign-in not active. Enable it in Supabase → Authentication → Providers.';
      }

      final now = DateTime.now();
      final petId = now.millisecondsSinceEpoch.toString();

      String? photoUrl;
      if (state.photoBytes != null) {
        try {
          photoUrl = await _repo.uploadPhoto(petId, state.photoBytes!, state.photoExt ?? 'jpg');
        } catch (_) {/* photo upload non-fatal */}
      }

      final pet = Pet(
        id: petId,
        name: state.name.trim(),
        species: state.species,
        breed: state.breed.trim(),
        dateOfBirth: state.dob ?? DateTime(now.year - 1),
        gender: state.gender,
        mood: state.mood,
        photoUrl: photoUrl,
        userId: userId,
        createdAt: now,
      );

      await _repo.createPet(pet);
      emit(state.copyWith(status: AddPetStatus.success, createdPet: pet));
    } catch (err) {
      emit(state.copyWith(status: AddPetStatus.failure, error: err.toString()));
    }
  }
}
