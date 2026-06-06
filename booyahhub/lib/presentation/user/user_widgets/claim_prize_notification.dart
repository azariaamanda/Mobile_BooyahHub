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
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── HEADER ROW ───
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon notifikasi
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.iconColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label kategori kecil
                    Text(
                      'NOTIFIKASI BARU',
                      style: AppTextStyles.interCaption.copyWith(
                        color: widget.iconColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Judul notifikasi
                    Text(
                      widget.title,
                      style: AppTextStyles.poppinsTitleSmall.copyWith(
                        fontSize: 15,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Pesan notifikasi
                    Text(
                      widget.message,
                      style: AppTextStyles.interBody.copyWith(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ─── ACTION BUTTONS ───
          Row(
            children: [
              // Tombol Lihat Notifikasi
              Expanded(
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: widget.iconColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Lihat Notifikasi',
                      style: AppTextStyles.poppinsButton.copyWith(
                        color: AppColors.black,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Tombol Tutup
              GestureDetector(
                onTap: _dismiss,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.inputBorder,
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Tutup',
                    style: AppTextStyles.poppinsButton.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
