import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_session.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

class AdminInboxPage extends StatefulWidget {
  const AdminInboxPage({super.key});

  @override
  State<AdminInboxPage> createState() => _AdminInboxPageState();
}

class _AdminInboxPageState extends State<AdminInboxPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _notifs = [];
  final Set<int> _readIds = {};
  bool _isLoading = true;
  int? _akunId;

  @override
  void initState() {
    super.initState();
    _fetchInbox();
  }

  Future<void> _fetchInbox() async {
    setState(() => _isLoading = true);
    try {
      final email = _supabase.sessionEmail;
      if (email == null) return;

      final akun = await _supabase
          .from('akun')
          .select('id_akun')
          .eq('email', email)
          .maybeSingle();
      _akunId = akun?['id_akun'] as int?;
      if (_akunId == null) return;

      // Notifikasi untuk admin: broadcast ke semua admin ATAU spesifik ke admin ini
      final data = await _supabase
          .from('notifikasi')
          .select()
          .or('target_role.eq.admin,target_id_akun.eq.$_akunId')
          .order('dikirim_pada', ascending: false);

      if (mounted) {
        setState(() {
          _notifs = List<Map<String, dynamic>>.from(data as List);
          // Sinkronkan read state dari kolom sudah_dibaca
          for (final n in _notifs) {
            if ((n['sudah_dibaca'] as bool? ?? false)) {
              _readIds.add(n['id_notifikasi'] as int);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetch admin inbox: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markRead(int idNotifikasi) async {
    if (_readIds.contains(idNotifikasi)) return;
    setState(() => _readIds.add(idNotifikasi));
    try {
      await _supabase
          .from('notifikasi')
          .update({'sudah_dibaca': true})
          .eq('id_notifikasi', idNotifikasi);
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    final unreadIds = _notifs
        .map((n) => n['id_notifikasi'] as int)
        .where((id) => !_readIds.contains(id))
        .toList();
    if (unreadIds.isEmpty) return;

    setState(() => _readIds.addAll(unreadIds));
    try {
      await _supabase
          .from('notifikasi')
          .update({'sudah_dibaca': true})
          .inFilter('id_notifikasi', unreadIds);
    } catch (_) {}
  }

  String _timeAgo(String? raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  IconData _tipeIcon(String? tipe) {
    switch (tipe) {
      case 'pembayaran_masuk': return Icons.payment_rounded;
      case 'pembayaran_dikonfirmasi': return Icons.check_circle_rounded;
      case 'pembayaran_ditolak': return Icons.cancel_rounded;
      case 'scrim_baru': return Icons.sports_esports_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _tipeColor(String? tipe) {
    switch (tipe) {
      case 'pembayaran_masuk': return AppColors.warning;
      case 'pembayaran_dikonfirmasi': return AppColors.success;
      case 'pembayaran_ditolak': return AppColors.error;
      case 'scrim_baru': return AppColors.primary;
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifs
        .where((n) => !_readIds.contains(n['id_notifikasi'] as int))
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kotak Masuk', style: AppTextStyles.poppinsTitle.copyWith(color: AppColors.primary)),
            if (unreadCount > 0)
              Text(
                '$unreadCount belum dibaca',
                style: AppTextStyles.interCaption.copyWith(color: AppColors.textSecondary, fontSize: 11),
              ),
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Baca Semua',
                style: AppTextStyles.interCaption.copyWith(color: AppColors.primary, fontSize: 12),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
            onPressed: _fetchInbox,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _notifs.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _fetchInbox,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingM,
                      vertical: AppConstants.paddingS,
                    ),
                    itemCount: _notifs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _buildItem(_notifs[i]),
                  ),
                ),
    );
  }

  Widget _buildItem(Map<String, dynamic> n) {
    final id = n['id_notifikasi'] as int;
    final isRead = _readIds.contains(id);
    final tipe = n['tipe'] as String?;
    final color = _tipeColor(tipe);

    return GestureDetector(
      onTap: () => _markRead(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? AppColors.backgroundCard : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(
            color: isRead ? AppColors.divider : color.withValues(alpha: 0.35),
            width: isRead ? 1 : 1.3,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isRead ? 0.08 : 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_tipeIcon(tipe), color: color, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n['judul'] ?? '',
                          style: AppTextStyles.interBody.copyWith(
                            fontSize: 13,
                            fontWeight: isRead ? FontWeight.normal : FontWeight.w700,
                            color: isRead ? AppColors.textSecondary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timeAgo(n['dikirim_pada']?.toString()),
                        style: AppTextStyles.interCaption.copyWith(
                          fontSize: 10,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n['pesan'] ?? '',
                    style: AppTextStyles.interCaption.copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_rounded, size: 40, color: AppColors.textHint),
          ),
          const SizedBox(height: 16),
          Text('Tidak ada notifikasi', style: AppTextStyles.poppinsTitleSmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(
            'Semua notifikasi masuk akan tampil di sini',
            style: AppTextStyles.interCaption.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}
