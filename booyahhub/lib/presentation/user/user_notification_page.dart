import 'package:flutter/material.dart';
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
  late List<Notification> notifications;
  int selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    notifications = [
      Notification(
        id: '1',
        title: 'Scrim Dimulai',
        message: 'Scrim "Ganteng Squad" akan dimulai dalam 15 menit',
        type: NotificationType.info,
        timestamp: DateTime.now(),
        isRead: false,
        actionLabel: 'Lihat Detail',
      ),
      Notification(
        id: '2',
        title: 'Hasil Pertandingan',
        message:
            'Hasil scrim Anda sudah tersedia. Cek performa tim Anda sekarang!',
        type: NotificationType.success,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      Notification(
        id: '3',
        title: 'Hadiah Selesai',
        message:
            'Hadiah Rp 250.000 dari scrim terakhir telah berhasil ditransfer',
        type: NotificationType.success,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: true,
      ),
      Notification(
        id: '4',
        title: 'Pembayaran Tertunda',
        message:
            'Verifikasi pembayaran Anda masih menunggu. Segera lengkapi proses verifikasi',
        type: NotificationType.warning,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
        actionLabel: 'Verifikasi Sekarang',
      ),
      Notification(
        id: '5',
        title: 'Peserta Belum Konfirmasi',
        message:
            'Ada 3 peserta yang belum mengkonfirmasi kehadiran di scrim besok',
        type: NotificationType.warning,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
      Notification(
        id: '6',
        title: 'Registrasi Diterima',
        message: 'Registrasi Anda untuk Tournament Mega telah diterima',
        type: NotificationType.success,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
      ),
      Notification(
        id: '7',
        title: 'Sistem Gangguan',
        message:
            'Sistem sedang dalam pemeliharaan. Beberapa fitur mungkin tidak tersedia',
        type: NotificationType.error,
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        isRead: true,
      ),
    ];
  }

  List<Notification> get filteredNotifications {
    switch (selectedTabIndex) {
      case 0: // Semua
        return notifications;
      case 1: // Belum dibaca
        return notifications.where((n) => !n.isRead).toList();
      case 2: // Sudah dibaca
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

  void _markAsRead(String id) {
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
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      notifications.removeWhere((n) => n.id == id);
    });
  }

  void _markAllAsRead() {
    setState(() {
      notifications = notifications
          .map(
            (n) => Notification(
              id: n.id,
              title: n.title,
              message: n.message,
              type: n.type,
              timestamp: n.timestamp,
              isRead: true,
              actionLabel: n.actionLabel,
              onAction: n.onAction,
            ),
          )
          .toList();
    });
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
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingL,
              ),
              child: Center(
                child: GestureDetector(
                  onTap: _markAllAsRead,
                  child: Text(
                    'Tandai Semua',
                    style: AppTextStyles.interLink.copyWith(fontSize: 13),
                  ),
                ),
              ),
            ),
          if (notifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingL,
              ),
              child: Center(
                child: GestureDetector(
                  onTap: _clearAll,
                  child: Text(
                    'Hapus',
                    style: AppTextStyles.interLink.copyWith(
                      fontSize: 13,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ),
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
            child: filteredNotifications.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingL,
                    ),
                    itemCount: filteredNotifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
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

  Widget _buildNotificationCard(Notification notification) {
    final typeColor = _getTypeColor(notification.type);
    final typeIcon = _getTypeIcon(notification.type);

    return Container(
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
                  side: BorderSide(color: typeColor.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
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
