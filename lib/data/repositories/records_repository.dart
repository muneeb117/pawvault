import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/record_model.dart';

class RecordsRepository {
  final SupabaseClient _client;
  RecordsRepository(this._client);

  Stream<List<HealthRecord>> watchRecords(String petId) {
    return _client
        .from('health_records')
        .stream(primaryKey: ['id'])
        .eq('pet_id', petId)
        .map((rows) {
          final list = rows.map((e) => HealthRecord.fromJson(e)).toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  Future<List<HealthRecord>> getRecords(String petId, {RecordType? type}) async {
    var query = _client.from('health_records').select().eq('pet_id', petId);
    if (type != null) query = query.eq('type', type.name);
    final data = await query.order('date', ascending: false);
    return (data as List).map((e) => HealthRecord.fromJson(e)).toList();
  }

  Future<double> getTotalSpentThisYear(String petId) async {
    final start = DateTime(DateTime.now().year);
    final data = await _client
        .from('health_records')
        .select('cost')
        .eq('pet_id', petId)
        .gte('date', start.toIso8601String());
    final list = data as List;
    return list.fold<double>(0, (sum, e) => sum + ((e['cost'] as num?)?.toDouble() ?? 0));
  }

  Future<HealthRecord> addRecord(HealthRecord record) async {
    final data = await _client.from('health_records').insert(record.toJson()).select().single();
    return HealthRecord.fromJson(data);
  }

  Future<HealthRecord> updateRecord(HealthRecord record) async {
    final data = await _client
        .from('health_records')
        .update(record.toJson())
        .eq('id', record.id)
        .select()
        .single();
    return HealthRecord.fromJson(data);
  }

  Future<void> deleteRecord(String recordId) =>
      _client.from('health_records').delete().eq('id', recordId);

  /// Uploads a document to Storage and returns a public URL.
  /// Uses the `pet-photos` bucket (already public) under `records/<petId>/<recordId>/<filename>`.
  Future<String> uploadDocument({
    required String petId,
    required String recordId,
    required Uint8List bytes,
    required String filename,
  }) async {
    final path = 'records/$petId/$recordId/$filename';
    await _client.storage.from('pet-photos').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('pet-photos').getPublicUrl(path);
  }
}
