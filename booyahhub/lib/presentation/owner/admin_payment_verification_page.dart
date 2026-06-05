import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/services/admin_utang_service.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';
import '../../config/app_constants.dart';
import '../../config/app_image_helper.dart';

class AdminPaymentVerificationPage extends StatefulWidget {
  final Map<String, dynamic> admin;

  const AdminPaymentVerificationPage({
    super.key,
    required this.admin,
  });

  @override
  State<AdminPaymentVerificationPage> createState() =>
      _AdminPaymentVerificationPageState();
}

class _AdminPaymentVerificationPageState
    extends State<AdminPaymentVerificationPage> {
  final AdminUtangService _adminService = AdminUtangService();
  List<Map<String, dynamic>> _pendingPayments = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchPendingPayments();
  }

  Future<void> _fetchPendingPayments() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final adminId = widget.admin['id_akun'];

      final response = await supabase
          .from('pelunasan_utang_admin')
          .select('*')
          .eq('admin_id', adminId)
          .eq('status', 'menunggu')
          .order('created_at', ascending: false);

      setState(() {
        _pendingPayments = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error fetching payments: $e');
    }
  }

  String _formatRupiah(double value) {
    return 'Rp ${value.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
  }

  Future<void> _verifyPayment(Map<String, dynamic> payment, bool isApproved) async {
    setState(() => _isProcessing = true);

    final result = await _adminService.verifikasiPelunasan(
      idPelunasan: payment['id_pelunasan'],
      adminId: widget.admin['id_akun'],
      disetujui: isApproved,
      alasanPenolakan: isApproved ? null : 'Bukti transfer tidak valid',
    );

    setState(() => _isProcessing = false);

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppColors.success,
          ),
        );
        
        await _fetchPendingPayments();
        
        if (_pendingPayments.isEmpty) {
          context.pop(true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
    Widget build(BuildContext context) {
      final totalUtang = (widget.admin['total_utang'] ?? 0).toDouble();
      final limitUtang = (widget.admin['limit_utang'] ?? 50000).toDouble();
      final status = widget.admin['status_akun'] ?? 'aktif';

      return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: const Icon(Icons.arrow_back, color: Color(0xFFFFD700), size: 24),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Verifikasi Pembayaran',
                          style: AppTextStyles.poppinsHeadline.copyWith(color: Color(0xFFFFD700), fontSize: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _buildAdminHeader(status, totalUtang, limitUtang),
                    const SizedBox(height: 24),
                    
                    if (totalUtang >= limitUtang) _buildLimitWarning(limitUtang),
                    const SizedBox(height: 24),
                    
                    if (_pendingPayments.isEmpty)
                      _buildEmptyState()
                    else
                      ..._pendingPayments.map((payment) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _buildPaymentCard(payment),
                      )),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAdminHeader(String status, double totalUtang, double limitUtang) {
    // Ambil foto profil dari data admin
    final fotoProfil = widget.admin['foto_profil'];
    String? fotoUrl;
    
    if (fotoProfil != null && fotoProfil.isNotEmpty) {
      fotoUrl = AppImageHelper.fotoProfil(fotoProfil);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Foto Profil
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            backgroundImage: fotoUrl != null ? NetworkImage(fotoUrl) : null,
            child: fotoUrl == null
                ? Text(
                    (widget.admin['nama_lengkap'] ?? 'A')[0],
                    style: AppTextStyles.poppinsTitle.copyWith(
                      color: AppColors.primary,
                      fontSize: 24,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.admin['nama_lengkap'] ?? 'Admin',
                  style: AppTextStyles.poppinsTitleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.admin['email'] ?? '',
                  style: AppTextStyles.interCaption,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'aktif'
                            ? AppColors.success.withOpacity(0.15)
                            : AppColors.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        status == 'aktif' ? 'AKTIF' : 'SUSPENDED',
                        style: AppTextStyles.interStatus.copyWith(
                          color: status == 'aktif' ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'TOTAL UTANG',
                      style: AppTextStyles.interCaption.copyWith(fontSize: 10),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatRupiah(totalUtang),
                      style: AppTextStyles.poppinsMoneySmall.copyWith(
                        color: AppColors.error,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitWarning(double limitUtang) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Admin telah mencapai limit utang (${_formatRupiah(limitUtang)}). Harap verifikasi pembayaran.',
              style: AppTextStyles.interCaption.copyWith(color: AppColors.error, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            'Tidak ada pengajuan pembayaran',
            style: AppTextStyles.interBody.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final nominal = (payment['nominal'] ?? 0).toDouble();
    final createdAt = payment['created_at'] != null
        ? DateTime.parse(payment['created_at'])
        : DateTime.now();
    final metodeBayar = payment['metode_bayar'] ?? 'Transfer Bank';
    final catatan = payment['catatan'] ?? '';
    final buktiBayarPath = payment['bukti_bayar'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bukti Transfer',
            style: AppTextStyles.poppinsTitleSmall.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 12),
          
          // ========== FOTO BUKTI TRANSFER dengan FutureBuilder ==========
          if (buktiBayarPath != null && buktiBayarPath.isNotEmpty)
            FutureBuilder<String?>(
              future: AppImageHelper.buktiBayar(buktiBayarPath),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundInput,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }
                
                if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundInput,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, color: AppColors.textHint, size: 48),
                          const SizedBox(height: 8),
                          Text(
                            'Gagal memuat gambar',
                            style: AppTextStyles.interCaption.copyWith(color: AppColors.textHint),
                          ),
                          Text(
                            'Path: $buktiBayarPath',
                            style: AppTextStyles.interCaption.copyWith(color: AppColors.textHint, fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    snapshot.data!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: AppColors.backgroundInput,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, color: AppColors.error, size: 48),
                              const SizedBox(height: 8),
                              Text(
                                'Error: ${error.toString().substring(0, 50)}',
                                style: AppTextStyles.interCaption.copyWith(color: AppColors.error, fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),          
          const SizedBox(height: 16),
          
          // Detail Transfer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundInput,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildDetailRow('Metode Pembayaran', metodeBayar),
                const Divider(color: AppColors.divider, height: 16),
                _buildDetailRow('Nominal', _formatRupiah(nominal), isBold: true),
                const Divider(color: AppColors.divider, height: 16),
                _buildDetailRow('Tanggal Pengajuan', _formatDateIndonesia(createdAt)),
                const Divider(color: AppColors.divider, height: 16),
                _buildDetailRow('Waktu', _formatTimeIndonesia(createdAt)),
                if (catatan.isNotEmpty) ...[
                  const Divider(color: AppColors.divider, height: 16),
                  _buildDetailRow('Catatan', catatan),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Card Nominal & Tanggal
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NOMINAL', style: AppTextStyles.interCaption.copyWith(fontSize: 10)),
                    const SizedBox(height: 4),
                    Text(
                      _formatRupiah(nominal),
                      style: AppTextStyles.poppinsMoney.copyWith(fontSize: 18),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('TANGGAL', style: AppTextStyles.interCaption.copyWith(fontSize: 10)),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateIndonesia(createdAt),
                      style: AppTextStyles.poppinsTitleSmall.copyWith(fontSize: 13),
                    ),
                    Text(
                      _formatTimeIndonesia(createdAt),
                      style: AppTextStyles.interCaption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Tombol
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : () => _showVerificationDialog(payment, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Text(
                          'Setujui Pembayaran',
                          style: AppTextStyles.poppinsButton.copyWith(fontSize: 12),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isProcessing ? null : () => _showVerificationDialog(payment, false),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Tolak',
                    style: AppTextStyles.poppinsButton.copyWith(
                      color: AppColors.error,
                      fontSize: 12,
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

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.interCaption.copyWith(color: AppColors.textHint),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: isBold
                  ? AppTextStyles.poppinsMoneySmall.copyWith(color: AppColors.primary)
                  : AppTextStyles.interBody,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showVerificationDialog(Map<String, dynamic> payment, bool isApproved) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.backgroundCard,
        title: Row(
          children: [
            Icon(
              isApproved ? Icons.check_circle : Icons.cancel,
              color: isApproved ? AppColors.success : AppColors.error,
            ),
            const SizedBox(width: 8),
            Text(
              isApproved ? 'Setujui Pembayaran?' : 'Tolak Pembayaran?',
              style: AppTextStyles.poppinsTitleSmall,
            ),
          ],
        ),
        content: Text(
          isApproved
              ? 'Setelah disetujui, utang admin akan berkurang dan akun akan otomatis aktif kembali.'
              : 'Yakin ingin menolak pembayaran ini? Admin akan tetap dalam status suspend.',
          style: AppTextStyles.interBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: AppTextStyles.interLink),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _verifyPayment(payment, isApproved);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproved ? AppColors.success : AppColors.error,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(isApproved ? 'Ya, Setujui' : 'Ya, Tolak'),
          ),
        ],
      ),
    );
  }

  String _formatDateIndonesia(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTimeIndonesia(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} WIB';
  }
}