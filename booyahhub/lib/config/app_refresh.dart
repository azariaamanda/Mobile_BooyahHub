import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppRefresh extends ChangeNotifier {
  static final AppRefresh instance = AppRefresh._();
  AppRefresh._();

  RealtimeChannel? _channel;

  void init() {
    _channel = Supabase.instance.client
        .channel('app_global_refresh')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'scrim',
          callback: (_) => refresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'pendaftaran_tim',
          callback: (_) => refresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sesi_scrim',
          callback: (_) => refresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profil_pengguna',
          callback: (_) => refresh(),
        )
        .subscribe();
  }

  void refresh() {
    notifyListeners();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
