import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotifData {
  final int id;
  final String tipe;
  final String judul;
  final String pesan;
  final String? targetRole;
  final int? targetIdAkun;
  final bool sudahDibaca;
  final DateTime dibuatPada;

  NotifData({
    required this.id,
    required this.tipe,
    required this.judul,
    required this.pesan,
    this.targetRole,
    this.targetIdAkun,
    required this.sudahDibaca,
    required this.dibuatPada,
  });

  factory NotifData.fromMap(Map<String, dynamic> m) => NotifData(
        id: m['id_notifikasi'] as int,
        tipe: m['tipe'] as String? ?? '',
        judul: m['judul'] as String? ?? '',
        pesan: m['pesan'] as String? ?? '',
        targetRole: m['target_role'] as String?,
        targetIdAkun: m['target_id_akun'] as int?,
        sudahDibaca: m['sudah_dibaca'] as bool? ?? false,
        dibuatPada: DateTime.tryParse(m['dibuat_pada'] as String? ?? '') ??
            DateTime.now(),
      );

  NotifData copyWith({bool? sudahDibaca}) => NotifData(
        id: id,
        tipe: tipe,
        judul: judul,
        pesan: pesan,
        targetRole: targetRole,
        targetIdAkun: targetIdAkun,
        sudahDibaca: sudahDibaca ?? this.sudahDibaca,
        dibuatPada: dibuatPada,
      );
}

/// Singleton service — initialize once setelah login, lalu pakai dari mana saja.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;

  int _akunId = 0;
  String _role = 'pengguna'; // 'pengguna' atau 'admin'

  final _newNotifCtrl = StreamController<NotifData>.broadcast();
  final _unreadCtrl = StreamController<int>.broadcast();

  /// Emit setiap kali ada notif baru masuk via Realtime
  Stream<NotifData> get newNotifStream => _newNotifCtrl.stream;

  /// Emit jumlah unread setiap kali berubah (untuk badge)
  Stream<int> get unreadCountStream => _unreadCtrl.stream;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;
  bool get isInitialized => _akunId != 0;

  // ── Panggil segera setelah login / navigator dibuka ───────────
  Future<void> initialize(int akunId, String role) async {
    if (_akunId == akunId) return; // sudah di-init dengan akun yang sama
    _akunId = akunId;
    _role = role;
    await _refreshCount();
    _subscribe();
  }

  Future<void> _refreshCount() async {
    if (_akunId == 0) return;
    try {
      final res = await _supabase
          .from('notifikasi')
          .select('id_notifikasi')
          .or('target_id_akun.eq.$_akunId,target_role.eq.$_role')
          .eq('sudah_dibaca', false);
      _unreadCount = (res as List).length;
      _unreadCtrl.add(_unreadCount);
    } catch (_) {}
  }

  void _subscribe() {
    _channel?.unsubscribe();
    _channel = _supabase
        .channel('notif_$_akunId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifikasi',
          callback: (payload) {
            final rec = payload.newRecord;
            final tgtId = rec['target_id_akun'] as int?;
            final tgtRole = rec['target_role'] as String?;

            // Filter: hanya notif yang ditujukan ke saya
            if (tgtId == _akunId || tgtRole == _role) {
              _unreadCount++;
              _unreadCtrl.add(_unreadCount);
              try {
                _newNotifCtrl.add(NotifData.fromMap(rec));
              } catch (_) {}
            }
          },
        )
        .subscribe();
  }

  // ── Ambil semua notif untuk halaman notifikasi ────────────────
  Future<List<NotifData>> fetchNotifications() async {
    if (_akunId == 0) return [];
    try {
      final res = await _supabase
          .from('notifikasi')
          .select()
          .or('target_id_akun.eq.$_akunId,target_role.eq.$_role')
          .order('dibuat_pada', ascending: false);
      return (res as List)
          .map((e) => NotifData.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Tandai satu notif sebagai sudah dibaca ────────────────────
  Future<void> markAsRead(int idNotifikasi) async {
    try {
      await _supabase
          .from('notifikasi')
          .update({'sudah_dibaca': true})
          .eq('id_notifikasi', idNotifikasi);
      if (_unreadCount > 0) {
        _unreadCount--;
        _unreadCtrl.add(_unreadCount);
      }
    } catch (_) {}
  }

  // ── Tandai semua notif sebagai sudah dibaca ───────────────────
  Future<void> markAllAsRead() async {
    if (_akunId == 0) return;
    try {
      await _supabase
          .from('notifikasi')
          .update({'sudah_dibaca': true})
          .or('target_id_akun.eq.$_akunId,target_role.eq.$_role')
          .eq('sudah_dibaca', false);
      _unreadCount = 0;
      _unreadCtrl.add(0);
    } catch (_) {}
  }

  // ── Bersihkan saat logout ─────────────────────────────────────
  void clear() {
    _channel?.unsubscribe();
    _channel = null;
    _akunId = 0;
    _unreadCount = 0;
  }
}
