import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
=======
import 'package:go_router/go_router.dart';
>>>>>>> Stashed changes
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/services/notification_service.dart';

class UserNotificationPage extends StatefulWidget {
  const UserNotificationPage({super.key});

  @override
  State<UserNotificationPage> createState() => _UserNotificationPageState();
}

class _UserNotificationPageState extends State<UserNotificationPage> {
<<<<<<< Updated upstream
  List<Notification> notifications = [];
  bool isLoading = true;
  int selectedTabIndex = 0;
  List<String> _readNotificationIds = [];
  // Key unik per user ─ format: 'read_notifications_<userId>'
  // Supaya status baca antar akun tidak saling tercampur
  String _prefKey = 'read_notifications';
=======
  final _service = NotificationService();
  List<NotifData> _notifications = [];
  bool _isLoading = true;
  int _selectedTab = 0;
>>>>>>> Stashed changes

  @override
  void initState() {
    super.initState();
<<<<<<< Updated upstream
    _loadReadNotificationsAndFetch();
  }

  Future<void> _loadReadNotificationsAndFetch() async {
    // Buat key per-user berdasarkan ID akun yang sedang login
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      _prefKey = 'read_notifications_$userId';
    }

    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _readNotificationIds = prefs.getStringList(_prefKey) ?? [];
      });
    }
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final response = await Supabase.instance.client
          .from('notifikasi')
          .select()
          .order('dikirim_pada', ascending: false);

      final List<Notification> fetchedNotifications = [];
      for (var item in response) {
        DateTime timestamp = DateTime.now();
        if (item['dikirim_pada'] != null) {
          timestamp = DateTime.parse(item['dikirim_pada'].toString());
        }

        final notifId = item['id_notifikasi'].toString();
        fetchedNotifications.add(
          Notification(
            id: notifId,
            title: item['judul'] ?? 'Notifikasi',
            message: item['pesan'] ?? '',
            type: NotificationType.info,
            timestamp: timestamp,
            isRead: _readNotificationIds.contains(notifId),
          ),
        );
      }

      if (mounted) {
        setState(() {
          notifications = fetchedNotifications;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
=======
    _load();
>>>>>>> Stashed changes
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _service.fetchNotifications();
    if (mounted) setState(() { _notifications = data; _isLoading = false; });
  }

  List<NotifData> get _filtered {
    switch (_selectedTab) {
      case 1: return _notifications.where((n) => !n.sudahDibaca).toList();
      case 2: return _notifications.where((n) => n.sudahDibaca).toList();
      default: return _notifications;
    }
  }

  int get _unreadCount => _notifications.where((n) => !n.sudahDibaca).length;

<<<<<<< Updated upstream
    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}j yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d yang lalu';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.info:
        return AppColors.info;
      case NotificationType.warning:
        return AppColors.warning;
      case NotificationType.success:
        return AppColors.accent;
      case NotificationType.error:
        return AppColors.error;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.info:
        return Icons.info_outline;
      case NotificationType.warning:
        return Icons.warning_outlined;
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.error:
        return Icons.error_outline;
    }
  }

  Future<void> _markAsRead(String id) async {
    setState(() {
      final index = notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        notifications[index] = Notification(
          id: notifications[index].id,
          title: notifications[index].title,
          message: notifications[index].message,
          type: notifications[index].type,
          timestamp: notifications[index].timestamp,
          isRead: true,
          actionLabel: notifications[index].actionLabel,
          onAction: notifications[index].onAction,
        );
      }
      if (!_readNotificationIds.contains(id)) {
        _readNotificationIds.add(id);
      }
=======
  Future<void> _markAsRead(NotifData notif) async {
    if (notif.sudahDibaca) return;
    await _service.markAsRead(notif.id);
    setState(() {
      final i = _notifications.indexWhere((n) => n.id == notif.id);
      if (i != -1) _notifications[i] = notif.copyWith(sudahDibaca: true);
>>>>>>> Stashed changes
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKey, _readNotificationIds);
  }

  Future<void> _markAllAsRead() async {
    await _service.markAllAsRead();
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(sudahDibaca: true)).toList();
    });
  }

<<<<<<< Updated upstream
  Future<void> _markAllAsRead() async {
    setState(() {
      notifications = notifications
          .map(
            (n) {
              if (!_readNotificationIds.contains(n.id)) {
                _readNotificationIds.add(n.id);
              }
              return Notification(
                id: n.id,
                title: n.title,
                message: n.message,
                type: n.type,
                timestamp: n.timestamp,
                isRead: true,
                actionLabel: n.actionLabel,
                onAction: n.onAction,
              );
            }
          )
          .toList();
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKey, _readNotificationIds);
=======
  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
    return '${t.day}/${t.month}/${t.year}';
>>>>>>> Stashed changes
  }

  Color _tipeColor(String tipe) {
    switch (tipe) {
      case 'pembayaran_dikonfirmasi': return AppColors.accent;
      case 'pembayaran_ditolak': return AppColors.error;
      case 'pembayaran_masuk': return AppColors.warning;
      case 'scrim_baru': return AppColors.info;
      default: return AppColors.primary;
    }
  }

  IconData _tipeIcon(String tipe) {
    switch (tipe) {
      case 'pembayaran_dikonfirmasi': return Icons.check_circle_outline;
      case 'pembayaran_ditolak': return Icons.cancel_outlined;
      case 'pembayaran_masuk': return Icons.payment_outlined;
      case 'scrim_baru': return Icons.sports_esports_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Notifikasi', style: AppTextStyles.poppinsTitle),
        centerTitle: false,
        actions: [
<<<<<<< Updated upstream
          if (unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all, color: AppColors.primary),
              tooltip: 'Tandai Semua Dibaca',
              onPressed: _markAllAsRead,
            ),
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'Hapus Semua',
              onPressed: _clearAll,
=======
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text('Tandai Semua', style: AppTextStyles.interLink.copyWith(fontSize: 13)),
>>>>>>> Stashed changes
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingL, 0, AppConstants.paddingL, AppConstants.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_unreadCount > 0)
                  Text('$_unreadCount notifikasi belum dibaca',
                      style: AppTextStyles.interBody.copyWith(color: AppColors.warning))
                else
                  Text('Semua notifikasi sudah dibaca', style: AppTextStyles.interBody),
                const SizedBox(height: AppConstants.paddingM),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTabBtn('Semua', 0),
                      const SizedBox(width: 12),
                      _buildTabBtn('Belum Dibaca', 1, _unreadCount),
                      const SizedBox(width: 12),
                      _buildTabBtn('Sudah Dibaca', 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
<<<<<<< Updated upstream
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : filteredNotifications.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingL,
                    ),
                    itemCount: filteredNotifications.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notification = filteredNotifications[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
=======
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.paddingL),
                          itemCount: _filtered.length,
                          separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _buildCard(_filtered[i]),
                        ),
                      ),
>>>>>>> Stashed changes
          ),
        ],
      ),
    );
  }

  Widget _buildTabBtn(String label, int index, [int count = 0]) {
    final isSelected = _selectedTab == index;
    final display = count > 0 ? '$label ($count)' : label;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingM, vertical: AppConstants.paddingS),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.inputBorder),
        ),
        child: Text(display,
            style: AppTextStyles.interBodyMedium.copyWith(
              color: isSelected ? AppColors.buttonText : AppColors.textSecondary,
              fontSize: 13,
            )),
      ),
    );
  }

<<<<<<< Updated upstream
  void _showNotificationDetails(Notification notification) {
    _markAsRead(notification.id); // Otomatis tandai sudah dibaca

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            side: const BorderSide(color: AppColors.inputBorder),
          ),
          title: Row(
            children: [
              Icon(_getTypeIcon(notification.type),
                  color: _getTypeColor(notification.type)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  notification.title,
                  style: AppTextStyles.poppinsTitleSmall
                      .copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getTimeAgo(notification.timestamp),
                style: AppTextStyles.interCaption,
              ),
              const SizedBox(height: 16),
              Text(
                notification.message,
                style: AppTextStyles.interBody,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Tutup',
                style:
                    AppTextStyles.interLink.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationCard(Notification notification) {
    final typeColor = _getTypeColor(notification.type);
    final typeIcon = _getTypeIcon(notification.type);

    return GestureDetector(
      onTap: () => _showNotificationDetails(notification),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.backgroundCard
              : AppColors.backgroundCard.withOpacity(0.7),
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(
            color: notification.isRead
                ? AppColors.inputBorder
                : typeColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: AppTextStyles.poppinsTitleSmall,
                                ),
                              ),
                              if (!notification.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: typeColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.message,
                            style: AppTextStyles.interBody,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getTimeAgo(notification.timestamp),
                            style: AppTextStyles.interCaption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                color: AppColors.backgroundCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  side: const BorderSide(color: AppColors.inputBorder),
                ),
                itemBuilder: (context) => [
                  if (!notification.isRead)
                    PopupMenuItem(
                      child: Text(
                        'Tandai Terbaca',
                        style: AppTextStyles.interBody,
                      ),
                      onTap: () {
                        _markAsRead(notification.id);
                      },
                    ),
                  PopupMenuItem(
                    child: Text(
                      'Hapus',
                      style: AppTextStyles.interBody.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    onTap: () {
                      _deleteNotification(notification.id);
                    },
                  ),
                ],
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ],
=======
  Widget _buildCard(NotifData notif) {
    final color = _tipeColor(notif.tipe);
    final icon = _tipeIcon(notif.tipe);

    return GestureDetector(
      onTap: () => _markAsRead(notif),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(
            color: notif.sudahDibaca
                ? AppColors.inputBorder
                : color.withValues(alpha: 0.4),
            width: notif.sudahDibaca ? 1 : 1.5,
>>>>>>> Stashed changes
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(notif.judul,
                            style: AppTextStyles.poppinsTitleSmall.copyWith(
                              fontSize: notif.sudahDibaca ? 13 : 14,
                            )),
                      ),
                      if (!notif.sudahDibaca)
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(notif.pesan,
                      style: AppTextStyles.interBody.copyWith(
                          color: notif.sudahDibaca
                              ? AppColors.textSecondary
                              : AppColors.textPrimary),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(_timeAgo(notif.dibuatPada),
                      style: AppTextStyles.interCaption.copyWith(
                          color: AppColors.textDisabled)),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('Tidak ada notifikasi',
              style: AppTextStyles.poppinsTitleSmall.copyWith(
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Semua beres!', style: AppTextStyles.interBody),
        ],
      ),
    );
  }
}
