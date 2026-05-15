import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vaccine_model.dart';

class VaccineRepository {
  final SupabaseClient _client;
  VaccineRepository(this._client);

  /// Realtime stream — requires the `vaccines` table to be in the
  /// `supabase_realtime` publication (see schema.sql).
  Stream<List<Vaccine>> watchVaccines(String petId) {
    return _client
        .from('vaccines')
        .stream(primaryKey: ['id'])
        .eq('pet_id', petId)
        .map((rows) {
          final list = rows.map((e) => Vaccine.fromJson(e)).toList();
          list.sort((a, b) => a.nextDue.compareTo(b.nextDue));
          return list;
        });
  }

  Future<List<Vaccine>> getVaccines(String petId) async {
    final data = await _client
        .from('vaccines')
        .select()
        .eq('pet_id', petId)
        .order('next_due');
    return (data as List).map((e) => Vaccine.fromJson(e)).toList();
  }

  Future<Vaccine> addVaccine(Vaccine vaccine) async {
    final data = await _client.from('vaccines').insert(vaccine.toJson()).select().single();
    return Vaccine.fromJson(data);
  }

  Future<Vaccine> updateVaccine(Vaccine vaccine) async {
    final data = await _client
        .from('vaccines')
        .update(vaccine.toJson())
        .eq('id', vaccine.id)
        .select()
        .single();
    return Vaccine.fromJson(data);
  }

  Future<void> deleteVaccine(String vaccineId) =>
      _client.from('vaccines').delete().eq('id', vaccineId);
}
