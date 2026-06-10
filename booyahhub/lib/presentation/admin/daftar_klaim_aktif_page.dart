import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import 'klaim_hadiah_detail_page.dart';

class DaftarKlaimAktifPage extends StatefulWidget {
  const DaftarKlaimAktifPage({super.key});

  @override
  State<DaftarKlaimAktifPage> createState() => _DaftarKlaimAktifPageState();
}

class _DaftarKlaimAktifPageState extends State<DaftarKlaimAktifPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _klaimAktif = [];
  List<Map<String, dynamic>> _klaimDibayar = [];

  @override
  void initState() {
    super.initState();
    _fetchKlaim();
  }

  Future<void> _fetchKlaim() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = _supabase.auth.currentUser;

      if (currentUser == null || currentUser.email == null) {
        throw Exception('Sesi login habis. Silakan login ulang.');
      }

      final akunData = await _supabase
          .from('akun')
          .select('id_akun')
          .eq('email', currentUser.email!)
          .maybeSingle();

      if (akunData == null) {
        throw Exception('Data akun admin tidak ditemukan.');
      }

      final int idAdmin = akunData['id_akun'] as int;

      final scrimRaw = await _supabase
          .from('scrim')
          .select('id_scrim, nama_scrim')
          .eq('id_admin', idAdmin);

      final scrimList = List<Map<String, dynamic>>.from(scrimRaw);

      if (scrimList.isEmpty) {
        if (!mounted) return;

        setState(() {
          _klaimAktif = [];
          _klaimDibayar = [];
          _isLoading = false;
        });

        return;
      }

      final List<int> scrimIds = scrimList
          .map((item) => item['id_scrim'])
          .whereType<int>()
          .toList();

      final sesiRaw = await _supabase
          .from('sesi_scrim')
          .select('id_sesi, id_scrim, nama_sesi')
          .inFilter('id_scrim', scrimIds);

      final sesiList = List<Map<String, dynamic>>.from(sesiRaw);

      if (sesiList.isEmpty) {
        if (!mounted) return;

        setState(() {
          _klaimAktif = [];
          _klaimDibayar = [];
          _isLoading = false;
        });

        return;
      }

      final List<int> sesiIds = sesiList
          .map((item) => item['id_sesi'])
          .whereType<int>()
          .toList();

      final klaimRaw = await _supabase
          .from('klaim_hadiah')
          .select('''
            id_klaim,
            id_pendaftaran,
            status_klaim,
            jumlah_klaim,
            metode_klaim,
            nama_bank,
            nomor_rekening,
            nama_pemilik_rekening,
            nama_pemilik_qris,
            qris_image,
            bukti_bayar_hadiah,
            diajukan_pada,
            disetujui_admin_pada,
            dibayar_pada,
            pendaftaran_tim!inner(
              id_pendaftaran,
              id_sesi,
              nama_kapten,
              whatsapp_kapten,
              sesi_scrim!inner(
                id_sesi,
                nama_sesi,
                waktu_mulai,
                waktu_selesai,
                id_scrim,
                scrim!inner(
                  id_scrim,
                  nama_scrim
                )
              )
            )
          ''')
          .inFilter('pendaftaran_tim.id_sesi', sesiIds)
          .order('diajukan_pada', ascending: false);

      final klaimList = List<Map<String, dynamic>>.from(klaimRaw);

      final aktif = <Map<String, dynamic>>[];
      final dibayar = <Map<String, dynamic>>[];

      for (final klaim in klaimList) {
        final status = klaim['status_klaim']?.toString() ?? '';

        if (status == 'dibayar') {
          dibayar.add(klaim);
        } else {
          aktif.add(klaim);
        }
      }

      if (!mounted) return;

      setState(() {
        _klaimAktif = aktif;
        _klaimDibayar = dibayar;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Gagal memuat daftar klaim: $e';
        _isLoading = false;
      });

      debugPrint('ERROR FETCH KLAIM AKTIF: $e');
    }
  }

  Future<void> _openDetailKlaim(Map<String, dynamic> klaim) async {
    final idKlaim = klaim['id_klaim'];

    if (idKlaim == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID klaim tidak ditemukan.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => KlaimHadiahDetailPage(
          idKlaim: idKlaim as int,
        ),
      ),
    );

    if (result == true && mounted) {
      _fetchKlaim();
    }
  }

  Map<String, dynamic> _getNestedData(Map<String, dynamic> klaim) {
    final pendaftaran = klaim['pendaftaran_tim'] as Map<String, dynamic>?;
    final sesi = pendaftaran?['sesi_scrim'] as Map<String, dynamic>?;
    final scrim = sesi?['scrim'] as Map<String, dynamic>?;

    return {
      'pendaftaran': pendaftaran,
      'sesi': sesi,
      'scrim': scrim,
    };
  }

  String _formatRupiah(dynamic value) {
    final number = (value as num?)?.toDouble() ?? 0;
    final str = number.toStringAsFixed(0);

    final buffer = StringBuffer();
    int counter = 0;

    for (int i = str.length - 1; i >= 0; i--) {
      if (counter > 0 && counter % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(str[i]);
      counter++;
    }

    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';

    try {
      final date = DateTime.parse(raw).toLocal();

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];

      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return '-';
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'belum_diajukan':
        return 'Belum Diajukan';
      case 'diajukan':
        return 'Diajukan';
      case 'disetujui_admin':
        return 'Disetujui Admin';
      case 'dibayar':
        return 'Dibayar';
      default:
        return status.isEmpty ? '-' : status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'dibayar':
        return Colors.green;
      case 'disetujui_admin':
        return Colors.orange;
      case 'diajukan':
        return AppColors.primary;
      case 'belum_diajukan':
      default:
        return AppColors.textHint;
    }
  }

  String _metodeLabel(String metode) {
    switch (metode) {
      case 'bank_transfer':
        return 'BANK';
      case 'qris':
        return 'QRIS';
      default:
        return metode.isEmpty ? '-' : metode.toUpperCase();
    }
  }

  Widget _buildStatusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: color.withOpacity(0.35),
        ),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildKlaimCard(Map<String, dynamic> klaim) {
    final nested = _getNestedData(klaim);

    final pendaftaran = nested['pendaftaran'] as Map<String, dynamic>?;
    final sesi = nested['sesi'] as Map<String, dynamic>?;
    final scrim = nested['scrim'] as Map<String, dynamic>?;

    final status = klaim['status_klaim']?.toString() ?? '';
    final metode = klaim['metode_klaim']?.toString() ?? '';

    final namaScrim = scrim?['nama_scrim']?.toString() ?? '-';
    final namaSesi = sesi?['nama_sesi']?.toString() ?? '-';
    final namaKapten = pendaftaran?['nama_kapten']?.toString() ?? '-';
    final whatsapp = pendaftaran?['whatsapp_kapten']?.toString() ?? '-';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusBadge(status),
              const Spacer(),
              Text(
                _formatDate(klaim['diajukan_pada']?.toString()),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            namaScrim,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.poppinsTitleSmall.copyWith(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            namaSesi,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.interCaption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      color: AppColors.textSecondary,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        namaKapten,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.interBodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.phone_android_rounded,
                      color: AppColors.textSecondary,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        whatsapp,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.interCaption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.payments_outlined,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatRupiah(klaim['jumlah_klaim']),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.poppinsTitleSmall.copyWith(
                          color: AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _metodeLabel(metode),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _openDetailKlaim(klaim),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Detail Klaim',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.black,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: AppTextStyles.poppinsTitleSmall.copyWith(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 28,
          vertical: 80,
        ),
        child: Column(
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 62,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Klaim',
              style: AppTextStyles.poppinsTitleSmall.copyWith(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Klaim hadiah dari user akan muncul di halaman ini.',
              textAlign: TextAlign.center,
              style: AppTextStyles.interBody.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.error,
              size: 54,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Terjadi kesalahan.',
              textAlign: TextAlign.center,
              style: AppTextStyles.interBody.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: _fetchKlaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Coba Lagi',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_klaimAktif.isEmpty && _klaimDibayar.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _fetchKlaim,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: _buildEmptyState(),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchKlaim,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_klaimAktif.isNotEmpty) ...[
              _buildSectionTitle(
                'Klaim Menunggu Proses',
                _klaimAktif.length,
              ),
              ..._klaimAktif.map(_buildKlaimCard),
              const SizedBox(height: 14),
            ],
            if (_klaimDibayar.isNotEmpty) ...[
              _buildSectionTitle(
                'Klaim Dibayar',
                _klaimDibayar.length,
              ),
              ..._klaimDibayar.map(_buildKlaimCard),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          'Daftar Klaim Aktif',
          style: AppTextStyles.poppinsTitle.copyWith(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _fetchKlaim,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }
}