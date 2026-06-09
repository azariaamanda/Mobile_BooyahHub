import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

enum NotificationType { info, warning, success, error }

class Notification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? actionLabel;
  final VoidCallback? onAction;

  const Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.actionLabel,
    this.onAction,
  });
}

class UserNotificationPage extends StatefulWidget {
  const UserNotificationPage({super.key});

  @override
  State<UserNotificationPage> createState() => _UserNotificationPageState();
}

class _UserNotificationPageState extends State<UserNotificationPage> {
  List<Notification> notifications = [];
  bool isLoading = true;
  int selectedTabIndex = 0;
  List<String> _readNotificationIds = [];
  String _prefKey = 'read_notifications';

  @override
  void initState() {
    super.initState();
    _loadReadNotificationsAndFetch();
  }

  Future<void> _loadReadNotificationsAndFetch() async {
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
  }

  List<Notification> get filteredNotifications {
    switch (selectedTabIndex) {
      case 0:
        return notifications;
      case 1:
        return notifications.where((n) => !n.isRead).toList();
      case 2:
        return notifications.where((n) => n.isRead).toList();
      default:
        return notifications;
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKey, _readNotificationIds);
  }

  void _deleteNotification(String id) {
    setState(() {
      notifications.removeWhere((n) => n.id == id);
    });
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      notifications = notifications
          .map((n) {
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
          })
          .toList();
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKey, _readNotificationIds);
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
        title: Text(
          'Hapus Semua Notifikasi?',
          style: AppTextStyles.poppinsTitleSmall,
        ),
        content: Text(
          'Semua notifikasi akan dihapus secara permanen',
          style: AppTextStyles.interBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: AppTextStyles.interLink),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                notifications.clear();
              });
              Navigator.pop(context);
            },
            child: Text(
              'Hapus',
              style: AppTextStyles.interLink.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notifikasi',
          style: AppTextStyles.poppinsTitle.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
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
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingL,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Notifikasi Anda',
                  style: AppTextStyles.poppinsHeadline.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 8),
                if (unreadCount > 0)
                  Text(
                    'Anda memiliki $unreadCount notifikasi baru',
                    style: AppTextStyles.interBody.copyWith(
                      color: AppColors.warning,
                    ),
                  )
                else
                  Text(
                    'Anda sudah melihat semua notifikasi',
                    style: AppTextStyles.interBody,
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Tab Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingL,
            ),
            child: Row(
              children: [
                _buildTabButton('Semua', 0),
                const SizedBox(width: 12),
                _buildTabButton('Belum Dibaca', 1, unreadCount),
                const SizedBox(width: 12),
                _buildTabButton('Sudah Dibaca', 2),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // List
          Expanded(
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
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final notification = filteredNotifications[index];
                          return _buildNotificationCard(notification);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index, [int count = 0]) {
    final isSelected = selectedTabIndex == index;
    final displayLabel = count > 0 ? '$label ($count)' : label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingM,
          vertical: AppConstants.paddingS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.inputBorder,
            width: 1,
          ),
        ),
        child: Text(
          displayLabel,
          style: AppTextStyles.interBodyMedium.copyWith(
            color: isSelected ? AppColors.buttonText : AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _showNotificationDetails(Notification notification) {
    _markAsRead(notification.id);

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
                style: AppTextStyles.interLink.copyWith(color: AppColors.primary),
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
              : AppColors.backgroundCard.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(
            color: notification.isRead
                ? AppColors.inputBorder
                : typeColor.withValues(alpha: 0.3),
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
                          color: typeColor.withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusM),
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
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusM),
                    side: const BorderSide(color: AppColors.inputBorder),
                  ),
                  itemBuilder: (context) => [
                    if (!notification.isRead)
                      PopupMenuItem(
                        onTap: () => _markAsRead(notification.id),
                        child: Text(
                          'Tandai Terbaca',
                          style: AppTextStyles.interBody,
                        ),
                      ),
                    PopupMenuItem(
                      onTap: () => _deleteNotification(notification.id),
                      child: Text(
                        'Hapus',
                        style: AppTextStyles.interBody.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
            if (notification.actionLabel != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    notification.onAction?.call();
                    _markAsRead(notification.id);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: typeColor,
                    side: BorderSide(color: typeColor.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusM),
                    ),
                  ),
                  child: Text(
                    notification.actionLabel!,
                    style: AppTextStyles.interBodyMedium.copyWith(
                      color: typeColor,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada notifikasi',
            style: AppTextStyles.poppinsTitleSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Anda sudah menangani semua notifikasi',
            style: AppTextStyles.interBody,
          ),
        ],
      ),
    );
  }
}
