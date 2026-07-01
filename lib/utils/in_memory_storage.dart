import 'package:supabase_flutter/supabase_flutter.dart';

/// In-memory LocalStorage implementation for web builds where
/// browser localStorage may be unavailable or crash on init.
class InMemoryLocalStorage implements LocalStorage {
  final Map<String, String> _store = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() async => _store['access_token'];

  @override
  Future<bool> hasAccessToken() async => _store.containsKey('access_token');

  @override
  Future<void> persistSession(String persistSessionString) async {
    _store['access_token'] = persistSessionString;
  }

  @override
  Future<void> removePersistedSession() async {
    _store.remove('access_token');
  }
}
