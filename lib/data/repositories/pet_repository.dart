import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pet_model.dart';

class PetRepository {
  final SupabaseClient _client;
  PetRepository(this._client);

  Future<List<Pet>> getPets(String userId) async {
    final data = await _client
        .from('pets')
        .select()
        .eq('user_id', userId)
        .order('created_at');
    return (data as List).map((e) => Pet.fromJson(e)).toList();
  }

  Future<Pet> createPet(Pet pet) async {
    final data = await _client.from('pets').insert(pet.toJson()).select().single();
    return Pet.fromJson(data);
  }

  Future<Pet> updatePet(Pet pet) async {
    final data = await _client
        .from('pets')
        .update(pet.toJson())
        .eq('id', pet.id)
        .select()
        .single();
    return Pet.fromJson(data);
  }

  Future<void> deletePet(String petId) =>
      _client.from('pets').delete().eq('id', petId);

  Future<String?> uploadPhoto(String petId, Uint8List bytes, String ext) async {
    final path = 'pets/$petId/avatar.$ext';
    await _client.storage.from('pet-photos').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('pet-photos').getPublicUrl(path);
  }
}
