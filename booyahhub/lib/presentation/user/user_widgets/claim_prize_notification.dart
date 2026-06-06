import 'package:flutter/material.dart';
import '../../../config/app_color.dart';
import '../../../config/app_text_styles.dart';

/// Widget notifikasi popup generik yang muncul dari atas layar.
/// Gunakan [NotificationPopup.show(context)] untuk menampilkan notifikasi dari database.
class NotificationPopup {
  /// Tampilkan popup notifikasi dari atas layar.
  ///
  /// [title]    : Judul notifikasi (dari kolom `judul` di tabel notifikasi)
  /// [message]  : Pesan notifikasi (dari kolom `pesan` di tabel notifikasi)
  /// [icon]     : Icon yang ditampilkan (default: notifications_rounded)
  /// [iconColor]: Warna icon dan aksen (default: AppColors.primary)
  /// [onTap]    : Callback saat notifikasi ditekan
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.notifications_rounded,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _NotificationOverlay(
        title: title,
        message: message,
        icon: icon,
        iconColor: iconColor ?? AppColors.primary,
        onTap: () {
          entry.remove();
          onTap?.call();
        },
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }

  // ─── Backward-compat helper khusus klaim hadiah ───
  /// @deprecated Gunakan [NotificationPopup.show] langsung.
  static void showClaimPrize(
    BuildContext context, {
    String scrimTitle = 'Scrim',
    String prizeAmount = 'Rp 0',
    VoidCallback? onClaim,
  }) {
    show(
      context,
      title: 'Klaim Hadiah Tersedia!',
      message: 'Hadiah $prizeAmount dari $scrimTitle siap dicarikan!',
      icon: Icons.monetization_on_rounded,
      iconColor: AppColors.primary,
      onTap: onClaim,
    );
  }
}

// ─── OVERLAY WIDGET INTERNAL ───
class _NotificationOverlay extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationOverlay({
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<_NotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: _buildCard(context),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1E2C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.iconColor.withOpacity(0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: widget.iconColor.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── ICON ───
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.icon,
                color: widget.iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // ─── TEXT ───
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: AppTextStyles.poppinsTitleSmall.copyWith(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // ─── Tombol X ───
                      GestureDetector(
                        onTap: _dismiss,
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.message,
                    style: AppTextStyles.interBody.copyWith(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── BACKWARD COMPAT: alias lama agar tidak perlu ubah import di tempat lain ───
/// @deprecated Gunakan [NotificationPopup] langsung.
class ClaimPrizeNotification {
  static void show(
    BuildContext context, {
    String scrimTitle = 'Scrim',
    String prizeAmount = 'Rp 0',
    VoidCallback? onClaim,
  }) {
    NotificationPopup.showClaimPrize(
      context,
      scrimTitle: scrimTitle,
      prizeAmount: prizeAmount,
      onClaim: onClaim,
    );
  }
}
