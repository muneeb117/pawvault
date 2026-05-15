import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medication_model.dart';

class MedicationRepository {
  final SupabaseClient _client;
  MedicationRepository(this._client);

  Stream<List<Medication>> watchMedications(String petId) {
    return _client
        .from('medications')
        .stream(primaryKey: ['id'])
        .eq('pet_id', petId)
        .map((rows) {
          final list = rows
              .map((e) => Medication.fromJson(e))
              .where((m) => m.isActive)
              .toList();
          list.sort((a, b) {
            if (a.nextDoseAt == null) return 1;
            if (b.nextDoseAt == null) return -1;
            return a.nextDoseAt!.compareTo(b.nextDoseAt!);
          });
          return list;
        });
  }

  Future<List<Medication>> getMedications(String petId) async {
    final data = await _client
        .from('medications')
        .select()
        .eq('pet_id', petId)
        .eq('is_active', true)
        .order('next_dose_at');
    return (data as List).map((e) => Medication.fromJson(e)).toList();
  }

  Future<Medication> addMedication(Medication med) async {
    final data = await _client.from('medications').insert(med.toJson()).select().single();
    return Medication.fromJson(data);
  }

  Future<Medication> updateMedication(Medication med) async {
    final data = await _client
        .from('medications')
        .update(med.toJson())
        .eq('id', med.id)
        .select()
        .single();
    return Medication.fromJson(data);
  }

  Future<void> deleteMedication(String medId) =>
      _client.from('medications').delete().eq('id', medId);

  Future<void> markDoseGiven(String medId) async {
    await _client.from('dose_logs').insert({
      'medication_id': medId,
      'given_at': DateTime.now().toIso8601String(),
    });
  }
}
