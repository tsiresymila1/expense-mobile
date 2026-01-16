import 'package:expense/core/adapters/adapters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRemoteServiceAdapter implements RemoteServiceAdapter {
  final SupabaseClient _client;

  SupabaseRemoteServiceAdapter(this._client);

  @override
  Future<void> upsert(String table, Map<String, dynamic> data) async {
    await _client.from(table).upsert(data);
  }

  @override
  Future<void> delete(String table, String id) async {
    await _client.from(table).delete().eq('id', id);
  }

  @override
  Future<List<Map<String, dynamic>>> fetch(
    String table,
    DateTime since, {
    String updatedAtColumn = 'updated_at',
  }) async {
    final response = await _client
        .from(table)
        .select()
        .gt(updatedAtColumn, since.toIso8601String());
    return List<Map<String, dynamic>>.from(response);
  }
}
