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
  bool _isPremium = false;
  DateTime? _premiumExpiry;
  String? _activePaketName;
  List<PaketPremiumModel> _pakets = [];
  Map<String, dynamic>? _pendingTx;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() { _isLoading = true; _loadError = null; });
    try {
      final email = _supabase.sessionEmail;
      if (email == null) return;

      final akun = await _supabase
          .from('akun')
          .select('id_akun, is_premium')
          .eq('email', email)
          .single();

      _isPremium = (akun['is_premium'] ?? false) as bool;
      final akunId = akun['id_akun'] as int;

      // Fetch ALL packages (no status filter) to diagnose what's in the table
      final pkgData = await _supabase
          .from('paket_premium')
          .select()
          .order('harga', ascending: true);
      final all = (pkgData as List);
      debugPrint('Total pakets in DB: ${all.length}, statuses: ${all.map((e) => e['status']).toList()}');
      _pakets = all
          .where((e) => (e['status'] as String? ?? '').toUpperCase() == 'AKTIF')
          .map((e) => PaketPremiumModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Latest premium transaction for this admin
      final txData = await _supabase
          .from('transaksi_premium')
          .select()
          .eq('akun_id', akunId)
          .order('dibuat_pada', ascending: false)
          .limit(1);

      if ((txData as List).isNotEmpty) {
        final latest = Map<String, dynamic>.from(txData.first as Map);
        final status = latest['status'] as String? ?? '';
        if (status == 'menunggu') {
          _pendingTx = latest;
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

  @override
  Widget build(BuildContext context) {
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
                    Text('Pilih Paket', style: AppTextStyles.poppinsSectionTitle),
                    const SizedBox(height: 16),
                    if (_loadError != null)
                      Container(
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
                      )
                    else if (_pakets.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppConstants.paddingXL),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(AppConstants.radiusL),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.star_outline, size: 48, color: AppColors.textHint),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada paket tersedia',
                              style: AppTextStyles.interBody.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
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
    if (_pendingTx != null) {
      return _buildStatusWidget(
        icon: Icons.hourglass_top_rounded,
        iconColor: AppColors.warning,
        title: 'Menunggu Verifikasi',
        subtitle: 'Pembayaran paket "${_pendingTx!['nama_paket']}" sedang diverifikasi oleh owner.',
        borderColor: AppColors.warning,
        badgeText: 'PENDING',
        badgeColor: AppColors.warning,
      );
    }
    if (_isPremium) {
      String expText = 'Aktif';
      if (_premiumExpiry != null) {
        expText = 'Berlaku s/d ${_premiumExpiry!.day}/${_premiumExpiry!.month}/${_premiumExpiry!.year}';
      }
      return _buildStatusWidget(
        icon: Icons.star_rounded,
        iconColor: const Color(0xFFFFD700),
        title: _activePaketName ?? 'Premium Aktif',
        subtitle: expText,
        borderColor: const Color(0xFFFFD700),
        badgeText: 'PREMIUM',
        badgeColor: const Color(0xFFFFD700),
      );
    }
    return _buildStatusWidget(
      icon: Icons.star_outline_rounded,
      iconColor: AppColors.textSecondary,
      title: 'Admin Standar',
      subtitle: 'Upgrade ke premium untuk membuka fitur eksklusif.',
      borderColor: AppColors.inputBorder,
      badgeText: 'STANDAR',
      badgeColor: AppColors.textSecondary,
    );
  }

  Widget _buildStatusWidget({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color borderColor,
    required String badgeText,
    required Color badgeColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 28),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        badgeText,
                        style: AppTextStyles.interCaption.copyWith(
                          color: badgeColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(title, style: AppTextStyles.poppinsTitleSmall),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.interBody.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaketCard(PaketPremiumModel paket) {
    final bool hasPending = _pendingTx != null;
    final bool isActive = _isPremium && _activePaketName == paket.namaPaket;

    final Color accentColor = _tierColor(paket.tierLevel);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: isActive ? const Color(0xFFFFD700) : AppColors.inputBorder,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colored top strip
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
                // Header row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(paket.namaPaket, style: AppTextStyles.poppinsTitleSmall),
                          const SizedBox(height: 2),
                          Text(
                            paket.tierLabel,
                            style: AppTextStyles.interCaption.copyWith(color: accentColor),
                          ),
                        ],
                      ),
                    ),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          'AKTIF',
                          style: AppTextStyles.interCaption.copyWith(
                            color: const Color(0xFFFFD700),
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Price + duration
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      paket.formattedHarga,
                      style: AppTextStyles.poppinsMoneyLarge.copyWith(
                        fontSize: 22,
                        color: accentColor,
                      ),
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
                // Features
                if (paket.fiturPaket != null && paket.fiturPaket!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  ...paket.fiturPaket!.take(5).map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle, color: AppColors.accent, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                f,
                                style: AppTextStyles.interBody.copyWith(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
                const SizedBox(height: 20),
                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (hasPending || isActive)
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
                      backgroundColor: isActive ? const Color(0xFFFFD700) : AppColors.primary,
                      disabledBackgroundColor: AppColors.surfaceVariant,
                      foregroundColor: AppColors.buttonText,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      ),
                    ),
                    child: Text(
                      isActive
                          ? 'Paket Aktif'
                          : hasPending
                              ? 'Menunggu Verifikasi'
                              : 'Upgrade Sekarang',
                      style: AppTextStyles.poppinsButton.copyWith(
                        color: (hasPending && !isActive)
                            ? AppColors.textSecondary
                            : AppColors.buttonText,
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
