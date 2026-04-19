import 'package:supabase_flutter/supabase_flutter.dart';

class DbService {
  static final DbService _instance = DbService._internal();
  factory DbService() => _instance;
  DbService._internal();

  SupabaseClient get client => Supabase.instance.client;
}

