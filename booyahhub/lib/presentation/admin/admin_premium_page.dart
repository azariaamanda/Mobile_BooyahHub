import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_session.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/paket_premium_model.dart';
import 'admin_premium_payment_page.dart';

class AdminPremiumPage extends StatefulWidget {
  const AdminPremiumPage({super.key});

  @override
  State<AdminPremiumPage> createState() => _AdminPremiumPageState();
}

class _AdminPremiumPageState extends State<AdminPremiumPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isCancelling = false;
  bool _isPremium = false;
  DateTime? _premiumExpiry;
  String? _activePaketName;
  String? _pendingPaketName;
  List<String> _fiturAktif = [];
  List<PaketPremiumModel> _pakets = [];
  Map<String, dynamic>? _pendingTx;
  int? _akunId;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() { _isLoading = true; _loadError = null; _pendingPaketName = null; _pendingTx = null; });
    try {
      final email = _supabase.sessionEmail;
      if (email == null) return;

      final akun = await _supabase
          .from('akun')
          .select('id_akun, is_premium, fitur_premium')
          .eq('email', email)
          .single();

      _isPremium = (akun['is_premium'] ?? false) as bool;
      _akunId = akun['id_akun'] as int;
      final rawFitur = akun['fitur_premium'];
      _fiturAktif = rawFitur is List ? List<String>.from(rawFitur) : [];

      final pkgData = await _supabase
          .from('paket_premium')
          .select()
          .order('harga', ascending: true);
      _pakets = (pkgData as List)
          .where((e) => (e['status'] as String? ?? '').toUpperCase() == 'AKTIF')
          .map((e) => PaketPremiumModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final txData = await _supabase
          .from('transaksi_premium')
          .select()
          .eq('akun_id', _akunId!)
          .order('dibuat_pada', ascending: false)
          .limit(1);

      if ((txData as List).isNotEmpty) {
        final latest = Map<String, dynamic>.from(txData.first as Map);
        final status = latest['status'] as String? ?? '';
        if (status == 'menunggu') {
          _pendingTx = latest;
          _pendingPaketName = latest['nama_paket'] as String?;
        } else if (status == 'aktif') {
          _activePaketName = latest['nama_paket'] as String?;
          if (latest['tanggal_berakhir'] != null) {
            _premiumExpiry = DateTime.tryParse(latest['tanggal_berakhir'].toString());
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching premium data: $e');
      if (mounted) setState(() => _loadError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelSubscription() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cancel_outlined, color: Colors.red, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'Batalkan Langganan?',
                style: AppTextStyles.poppinsTitle.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 10),
              Text(
                'Semua fitur premium akan langsung dinonaktifkan setelah pembatalan.',
                textAlign: TextAlign.center,
                style: AppTextStyles.interBody.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text(
                        'Kembali',
                        style: AppTextStyles.poppinsButton.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text(
                        'Batalkan',
                        style: AppTextStyles.poppinsButton.copyWith(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true || _akunId == null) return;

    setState(() => _isCancelling = true);
    try {
      await _supabase
          .from('transaksi_premium')
          .update({'status': 'ditolak'})
          .eq('akun_id', _akunId!)
          .eq('status', 'aktif');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Langganan berhasil dibatalkan'),
            backgroundColor: Colors.red,
          ),
        );
        _fetchData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membatalkan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Layanan Premium',
          style: AppTextStyles.poppinsTitle.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildStatusCard(),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        const Icon(Icons.rocket_launch_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('Pilih Paket', style: AppTextStyles.poppinsSectionTitle),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_loadError != null)
                      _buildErrorCard()
                    else if (_pakets.isEmpty)
                      _buildEmptyCard()
                    else
                      ..._pakets.map((paket) => Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _buildPaketCard(paket),
                          )),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    // ── PENDING ──
    if (_pendingTx != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.paddingL),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(color: AppColors.warning, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Status Akun', style: AppTextStyles.interLabel),
                      const SizedBox(width: 8),
                      _badge('PENDING', AppColors.warning),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Menunggu Verifikasi',
                    style: AppTextStyles.poppinsTitleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pembayaran paket "${_pendingTx!['nama_paket']}" sedang diverifikasi owner.',
                    style: AppTextStyles.interBody.copyWith(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── PREMIUM ACTIVE ──
    if (_isPremium) {
      String expText = 'Aktif';
      if (_premiumExpiry != null) {
        final d = _premiumExpiry!;
        final months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
        expText = '${d.day} ${months[d.month - 1]} ${d.year}';
      }

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.08),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Top accent strip
            Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.radiusL),
                  topRight: Radius.circular(AppConstants.radiusL),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Status Akun', style: AppTextStyles.interLabel),
                                const SizedBox(width: 8),
                                _badge('PREMIUM', const Color(0xFFFFD700)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _activePaketName ?? 'Premium Aktif',
                              style: AppTextStyles.poppinsTitleSmall.copyWith(
                                color: const Color(0xFFFFD700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Expiry
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFFFFD700)),
                        const SizedBox(width: 8),
                        Text(
                          'Berlaku hingga $expText',
                          style: AppTextStyles.interCaption.copyWith(
                            color: const Color(0xFFFFD700),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Active features
                  if (_fiturAktif.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Color(0x26FFD700)),
                    const SizedBox(height: 12),
                    Text(
                      'Fitur Aktif',
                      style: AppTextStyles.interLabel.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._fiturAktif.map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFFFFD700)),
                              const SizedBox(width: 10),
                              Text(
                                f,
                                style: AppTextStyles.interBody.copyWith(fontSize: 13),
                              ),
                            ],
                          ),
                        )),
                  ],

                  const SizedBox(height: 20),

                  // Cancel button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isCancelling ? null : _cancelSubscription,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 1.2),
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusM),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      icon: _isCancelling
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                            )
                          : const Icon(Icons.cancel_outlined, size: 18),
                      label: Text(
                        _isCancelling ? 'Membatalkan...' : 'Batalkan Langganan',
                        style: AppTextStyles.poppinsButton.copyWith(
                          color: Colors.red,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── STANDAR ──
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.inputBorder, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.star_outline_rounded, color: AppColors.textSecondary, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Status Akun', style: AppTextStyles.interLabel),
                    const SizedBox(width: 8),
                    _badge('STANDAR', AppColors.textSecondary),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Admin Standar', style: AppTextStyles.poppinsTitleSmall),
                const SizedBox(height: 4),
                Text(
                  'Upgrade ke premium untuk membuka fitur eksklusif.',
                  style: AppTextStyles.interBody.copyWith(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: AppTextStyles.interCaption.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 9,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.error),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Error memuat paket:', style: AppTextStyles.interBody.copyWith(color: AppColors.error, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(_loadError!, style: AppTextStyles.interCaption.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingXL),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.star_outline, size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(
            'Belum ada paket tersedia',
            style: AppTextStyles.interBody.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Hubungi owner untuk informasi paket premium.',
            style: AppTextStyles.interCaption.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildPaketCard(PaketPremiumModel paket) {
    final bool isPendingThis = _pendingTx != null && _pendingPaketName == paket.namaPaket;
    final bool isBlocked = _isPremium || (_pendingTx != null && !isPendingThis);
    final Color accentColor = isBlocked ? AppColors.textHint : _tierColor(paket.tierLevel);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: isPendingThis ? AppColors.warning : isBlocked ? AppColors.divider : AppColors.inputBorder,
          width: isPendingThis ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.radiusL),
                topRight: Radius.circular(AppConstants.radiusL),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                paket.namaPaket,
                                style: AppTextStyles.poppinsTitleSmall.copyWith(
                                  color: isBlocked ? AppColors.textSecondary : AppColors.textPrimary,
                                ),
                              ),
                              if (isBlocked) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.lock_rounded, size: 14, color: AppColors.textHint),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            paket.tierLabel,
                            style: AppTextStyles.interCaption.copyWith(color: accentColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      paket.formattedHarga,
                      style: AppTextStyles.poppinsMoneyLarge.copyWith(fontSize: 22, color: accentColor),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        '/ ${paket.formattedDurasi}',
                        style: AppTextStyles.interCaption.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                if (paket.fiturPaket != null && paket.fiturPaket!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  ...paket.fiturPaket!.take(5).map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: isBlocked ? AppColors.textHint : AppColors.accent,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                f,
                                style: AppTextStyles.interBody.copyWith(
                                  fontSize: 13,
                                  color: isBlocked ? AppColors.textSecondary : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (isPendingThis || isBlocked)
                        ? null
                        : () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AdminPremiumPaymentPage(paket: paket),
                              ),
                            );
                            _fetchData();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      disabledBackgroundColor: isPendingThis
                          ? AppColors.warning.withValues(alpha: 0.6)
                          : AppColors.surfaceVariant,
                      disabledForegroundColor: isPendingThis ? Colors.black87 : AppColors.textSecondary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isPendingThis) ...[
                          const Icon(Icons.hourglass_top_rounded, size: 16),
                          const SizedBox(width: 8),
                        ] else if (isBlocked) ...[
                          const Icon(Icons.lock_rounded, size: 16),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          isPendingThis
                              ? 'Menunggu Verifikasi'
                              : isBlocked
                                  ? 'Terkunci'
                                  : 'Upgrade Sekarang',
                          style: AppTextStyles.poppinsButton.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _tierColor(String? tier) {
    switch (tier?.toUpperCase()) {
      case 'PRO LEVEL':
      case 'PRO':
        return const Color(0xFFFFD700);
      case 'ENTERPRISE':
      case 'TEAM SCALE':
        return const Color(0xFF00E5FF);
      default:
        return AppColors.primary;
    }
  }
}
