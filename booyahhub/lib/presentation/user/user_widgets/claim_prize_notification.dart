import 'package:flutter/material.dart';
import '../../../config/app_color.dart';
import '../../../config/app_text_styles.dart';

/// Widget notifikasi popup "Klaim Hadiah" yang muncul dari atas layar.
/// Gunakan [ClaimPrizeNotification.show(context)] untuk menampilkan notifikasi.
class ClaimPrizeNotification {
  /// Tampilkan popup notifikasi klaim hadiah dari atas layar.
  ///
  /// [scrimTitle]   : Nama scrim (default hardcode sementara)
  /// [prizeName]    : Nominal hadiah (default hardcode sementara)
  /// [onClaim]      : Callback saat tombol "Klaim Sekarang" ditekan
  static void show(
    BuildContext context, {
    String scrimTitle = 'Rafif Scrim',
    String prizeAmount = 'Rp 250.000',
    VoidCallback? onClaim,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _ClaimPrizeOverlay(
        scrimTitle: scrimTitle,
        prizeAmount: prizeAmount,
        onClaim: () {
          entry.remove();
          onClaim?.call();
        },
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

// ─── OVERLAY WIDGET INTERNAL ───
class _ClaimPrizeOverlay extends StatefulWidget {
  final String scrimTitle;
  final String prizeAmount;
  final VoidCallback onClaim;
  final VoidCallback onDismiss;

  const _ClaimPrizeOverlay({
    required this.scrimTitle,
    required this.prizeAmount,
    required this.onClaim,
    required this.onDismiss,
  });

  @override
  State<_ClaimPrizeOverlay> createState() => _ClaimPrizeOverlayState();
}

class _ClaimPrizeOverlayState extends State<_ClaimPrizeOverlay>
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
          color: AppColors.primary.withOpacity(0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
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
              // Icon uang
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.monetization_on_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KLAIM HADIAH',
                      style: AppTextStyles.interCaption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: AppTextStyles.poppinsTitleSmall.copyWith(
                          fontSize: 15,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: 'Hadiah ',
                          ),
                          TextSpan(
                            text: widget.prizeAmount,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: ' dari ${widget.scrimTitle} siap dicarikan!',
                          ),
                        ],
                      ),
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
              // Tombol Klaim Sekarang
              Expanded(
                child: GestureDetector(
                  onTap: widget.onClaim,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Klaim Sekarang',
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
