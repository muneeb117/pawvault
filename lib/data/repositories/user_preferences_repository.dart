import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_preferences_model.dart';

class UserPreferencesRepository {
  final SupabaseClient _client;
  UserPreferencesRepository(this._client);

  Future<void> upsert(UserPreferences prefs) async {
    await _client.from('user_preferences').upsert(prefs.toJson());
  }

  Future<UserPreferences?> get(String userId) async {
    try {
      final data = await _client
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (data == null) return null;
      return UserPreferences.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
