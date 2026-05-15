import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/pet_model.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../shared/widgets/pet_name_label.dart';

/// One source of truth for "which pet is the user currently looking at?".
/// Provided at app root → every screen reads from this so picking a pet on
/// Home propagates to Vaccines, Meds, Records, Care, AI chat, etc.
class ActivePetState {
  final List<Pet> pets;
  final Pet? active;
  final bool loading;
  final String? error;

  const ActivePetState({
    this.pets = const [],
    this.active,
    this.loading = false,
    this.error,
  });

  bool get isEmpty => !loading && pets.isEmpty;
  String? get activeId => active?.id;

  ActivePetState copyWith({
    List<Pet>? pets,
    Pet? active,
    bool? loading,
    String? error,
    bool clearError = false,
  }) =>
      ActivePetState(
        pets: pets ?? this.pets,
        active: active ?? this.active,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );
}

class ActivePetCubit extends Cubit<ActivePetState> {
  ActivePetCubit() : super(const ActivePetState());

  static const _prefsKey = 'active_pet_id';

  /// Loads pets for the signed-in user and picks last-active (or first).
  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) {
        emit(const ActivePetState());
        return;
      }
      final pets = await PetRepository(Supabase.instance.client).getPets(uid);
      if (pets.isEmpty) {
        emit(const ActivePetState());
        return;
      }
      for (final p in pets) {
        PetNameCache.put(p.id, p.name);
      }
      final sp = await SharedPreferences.getInstance();
      final lastId = sp.getString(_prefsKey);
      final active = pets.firstWhere(
        (p) => p.id == lastId,
        orElse: () => pets.first,
      );
      emit(ActivePetState(pets: pets, active: active));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  /// Switches the active pet and remembers the choice.
  Future<void> setActive(String petId) async {
    Pet? next;
    try {
      next = state.pets.firstWhere((p) => p.id == petId);
    } catch (_) {
      return;
    }
    emit(state.copyWith(active: next));
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_prefsKey, petId);
    } catch (_) {}
  }

  /// Add or refresh a single pet — call this after the Add Pet flow saves a
  /// new pet so the switcher updates without a full reload.
  Future<void> refresh() => load();
}
