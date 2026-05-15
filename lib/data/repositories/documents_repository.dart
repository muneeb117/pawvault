import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/document_model.dart';

class DocumentsRepository {
  final SupabaseClient _client;
  DocumentsRepository(this._client);

  /// Realtime stream of documents for a pet.
  Stream<List<PetDocument>> watchDocuments(String petId) {
    return _client
        .from('documents')
        .stream(primaryKey: ['id'])
        .eq('pet_id', petId)
        .map((rows) {
          final list = rows.map((e) => PetDocument.fromJson(e)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<List<PetDocument>> getDocuments(String petId, {DocType? type}) async {
    var query = _client.from('documents').select().eq('pet_id', petId);
    if (type != null) query = query.eq('type', type.wireName);
    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => PetDocument.fromJson(e)).toList();
  }

  Future<PetDocument> addDocument(PetDocument doc) async {
    final data = await _client
        .from('documents')
        .insert(doc.toJson())
        .select()
        .single();
    return PetDocument.fromJson(data);
  }

  Future<PetDocument> updateDocument(PetDocument doc) async {
    final data = await _client
        .from('documents')
        .update(doc.toJson())
        .eq('id', doc.id)
        .select()
        .single();
    return PetDocument.fromJson(data);
  }

  Future<void> deleteDocument(String id) =>
      _client.from('documents').delete().eq('id', id);

  /// Uploads bytes to Supabase Storage under `documents/<petId>/<docId>/<filename>`
  /// and returns the public URL.
  Future<String> uploadFile({
    required String petId,
    required String docId,
    required Uint8List bytes,
    required String filename,
  }) async {
    final path = 'documents/$petId/$docId/$filename';
    await _client.storage.from('pet-photos').uploadBinary(
          path, bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('pet-photos').getPublicUrl(path);
  }
}
