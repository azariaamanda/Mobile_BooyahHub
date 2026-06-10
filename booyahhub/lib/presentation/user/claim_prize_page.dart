import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';
import 'request_claim_prize_page.dart';

class ClaimPrizePage extends StatefulWidget {
  final int? pendaftaranId;

  const ClaimPrizePage({
    super.key,
    this.pendaftaranId,
  });

  @override
  State<ClaimPrizePage> createState() => _ClaimPrizePageState();
}

class _ClaimPrizePageState extends State<ClaimPrizePage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _prizeList = [];

  static const String _bucketBuktiBayar = 'bukti_bayar';

  @override
  void initState() {
    super.initState();
    _fetchPrizes();
  }

  Future<void> _fetchPrizes() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authUser = _supabase.auth.currentUser;

      if (authUser == null || authUser.email == null) {
        throw Exception('User belum login.');
      }

      final akunResponse = await _supabase
          .from('akun')
          .select('id_akun')
          .eq('email', authUser.email!)
          .maybeSingle();

      if (akunResponse == null) {
        throw Exception('Akun tidak ditemukan.');
      }

      final int akunId = akunResponse['id_akun'] as int;

      var query = _supabase.from('pendaftaran_tim').select('''
        id_pendaftaran,
        status_pertandingan,
        sesi_scrim (
          id_sesi,
          nama_sesi,
          waktu_mulai,
          waktu_selesai,
          scrim (
            id_scrim,
            nama_scrim,
            total_hadiah
          )
        ),
        hasil_pertandingan (
          id_hasil,
          match_ke,
          placement,
          total_kill,
          total_poin
        ),
        klaim_hadiah (
          id_klaim,
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
          dibayar_pada
        )
      ''').eq('akun_id', akunId).eq('status_pertandingan', 'selesai');

      if (widget.pendaftaranId != null) {
        query = query.eq('id_pendaftaran', widget.pendaftaranId!);
      }

      final response = await query;
      final List<Map<String, dynamic>> loadedPrizes = [];

      for (final itemRaw in response) {
        final item = Map<String, dynamic>.from(itemRaw);

        final sesiData = item['sesi_scrim'] as Map<String, dynamic>?;
        final scrimData = sesiData?['scrim'] as Map<String, dynamic>?;

        if (scrimData == null) continue;

        final hasilList =
            List<Map<String, dynamic>>.from(item['hasil_pertandingan'] ?? []);

        final klaimList =
            List<Map<String, dynamic>>.from(item['klaim_hadiah'] ?? []);

        final hasilTerbaik = _getHasilTerbaik(hasilList);

        final int placement = _parseInt(hasilTerbaik?['placement']);
        final int totalPoin = _parseInt(hasilTerbaik?['total_poin']);
        final int totalKill = _parseInt(hasilTerbaik?['total_kill']);

        final Map<String, dynamic>? klaim = klaimList.isNotEmpty
            ? Map<String, dynamic>.from(klaimList.first)
            : null;

        final String statusKlaim =
            klaim?['status_klaim']?.toString() ?? 'belum_diklaim';

        final num totalHadiahScrim = _parseNum(scrimData['total_hadiah']);

        final num nominalHadiah = klaim != null
            ? _parseNum(klaim['jumlah_klaim'])
            : _hitungNominalHadiah(totalHadiahScrim, placement);

        loadedPrizes.add({
          'id_pendaftaran': item['id_pendaftaran'],
          'id_klaim': klaim?['id_klaim'],
          'nama_scrim': scrimData['nama_scrim']?.toString() ?? 'Unnamed Scrim',
          'nama_sesi': sesiData?['nama_sesi']?.toString() ?? '-',
          'total_hadiah_scrim': totalHadiahScrim,
          'nominal_hadiah': nominalHadiah,
          'rank': placement,
          'rank_label': _rankLabel(placement),
          'total_poin': totalPoin,
          'total_kill': totalKill,
          'status_klaim': statusKlaim,
          'diajukan_pada': klaim?['diajukan_pada'],
          'disetujui_admin_pada': klaim?['disetujui_admin_pada'],
          'dibayar_pada': klaim?['dibayar_pada'],
          'bukti_bayar_hadiah': klaim?['bukti_bayar_hadiah'],
        });
      }

      if (!mounted) return;

      setState(() {
        _prizeList = loadedPrizes;
        _isLoading = false;
      });
    } catch (e, stacktrace) {
      debugPrint('Error fetching prizes: $e');
      debugPrint(stacktrace.toString());

      if (!mounted) return;

      setState(() {
        _error = 'Gagal memuat hadiah: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic>? _getHasilTerbaik(List<Map<String, dynamic>> hasilList) {
    if (hasilList.isEmpty) return null;

    hasilList.sort((a, b) {
      final poinA = _parseInt(a['total_poin']);
      final poinB = _parseInt(b['total_poin']);

      if (poinA != poinB) {
        return poinB.compareTo(poinA);
      }

      final placementA = _parseInt(a['placement']);
      final placementB = _parseInt(b['placement']);

      if (placementA == 0 && placementB == 0) return 0;
      if (placementA == 0) return 1;
      if (placementB == 0) return -1;

      return placementA.compareTo(placementB);
    });

    return hasilList.first;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  num _parseNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }

  num _hitungNominalHadiah(num totalHadiah, int rank) {
    if (rank == 1) return totalHadiah * 0.5;
    if (rank == 2) return totalHadiah * 0.3;
    if (rank == 3) return totalHadiah * 0.2;
    return 0;
  }

  String _rankLabel(int rank) {
    if (rank == 1) return 'Juara 1';
    if (rank == 2) return 'Juara 2';
    if (rank == 3) return 'Juara 3';
    if (rank > 0) return 'Rank $rank';
    return 'Belum Ada Peringkat';
  }

  String _formatRupiah(dynamic value) {
    final number = _parseNum(value).round();
    final str = number.toString();

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
      final dt = DateTime.parse(raw).toLocal();

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

      return '${dt.day} ${months[dt.month - 1]} ${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '-';
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'belum_diklaim':
        return 'Belum Diklaim';
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

  String _statusHeader(String status) {
    switch (status) {
      case 'belum_diklaim':
      case 'belum_diajukan':
        return 'PERLU TINDAKAN';
      case 'diajukan':
        return 'KLAIM DIAJUKAN';
      case 'disetujui_admin':
        return 'KLAIM DISETUJUI';
      case 'dibayar':
        return 'TRANSAKSI SELESAI';
      default:
        return 'STATUS KLAIM';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'belum_diklaim':
      case 'belum_diajukan':
        return AppColors.error;
      case 'diajukan':
        return Colors.orange;
      case 'disetujui_admin':
        return Colors.amber;
      case 'dibayar':
        return Colors.green;
      default:
        return AppColors.textHint;
    }
  }

  Color _statusBadgeBackground(String status) {
    return _statusColor(status).withOpacity(0.16);
  }

  bool _canClaim(String status, num nominalHadiah, int rank) {
    return (status == 'belum_diklaim' || status == 'belum_diajukan') &&
        nominalHadiah > 0 &&
        rank >= 1 &&
        rank <= 3;
  }

  String _statusDescription(Map<String, dynamic> data) {
    final status = data['status_klaim']?.toString() ?? '';

    switch (status) {
      case 'diajukan':
        return 'Klaim kamu sudah diajukan dan menunggu proses admin.';
      case 'disetujui_admin':
        return 'Klaim sudah disetujui admin dan menunggu pembayaran hadiah.';
      case 'dibayar':
        return 'Hadiah sudah dibayarkan oleh admin. Ketuk card untuk melihat bukti pembayaran.';
      case 'belum_diklaim':
      case 'belum_diajukan':
        return 'Hadiah tersedia. Silakan ajukan klaim.';
      default:
        return 'Status klaim sedang diperbarui.';
    }
  }

  String _extractStoragePath(String value, String bucketName) {
    if (value.isEmpty) return value;

    if (!value.startsWith('http')) {
      return value;
    }

    final publicMarker = '/storage/v1/object/public/$bucketName/';
    final signMarker = '/storage/v1/object/sign/$bucketName/';

    if (value.contains(publicMarker)) {
      final path = value.split(publicMarker).last.split('?').first;
      return Uri.decodeComponent(path);
    }

    if (value.contains(signMarker)) {
      final path = value.split(signMarker).last.split('?').first;
      return Uri.decodeComponent(path);
    }

    return value;
  }

  Future<String> _createSignedImageUrl({
    required String? value,
    required String bucketName,
  }) async {
    if (value == null || value.trim().isEmpty) {
      throw Exception('Path gambar kosong.');
    }

    final raw = value.trim();
    final path = _extractStoragePath(raw, bucketName);

    if (path.startsWith('http') && !path.contains('/storage/v1/object/')) {
      return path;
    }

    final signedUrl = await _supabase.storage.from(bucketName).createSignedUrl(
          path,
          60 * 60,
        );

    return signedUrl;
  }

  Future<void> _openRequestClaim(Map<String, dynamic> data) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => RequestClaimPrizePage(
          title: data['nama_scrim'],
          rank: data['rank_label'],
          totalPrize: _formatRupiah(data['nominal_hadiah']),
          pendaftaranId: data['id_pendaftaran'],
        ),
      ),
    );

    if (result == true || result == null) {
      _fetchPrizes();
    }
  }

  Future<void> _showBuktiPembayaranDialog(Map<String, dynamic> data) async {
    final status = data['status_klaim']?.toString() ?? '';
    final buktiBayar = data['bukti_bayar_hadiah']?.toString();
    final dibayarPada = data['dibayar_pada']?.toString();

    if (status != 'dibayar') {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AppColors.backgroundCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Bukti Pembayaran',
              style: AppTextStyles.poppinsTitleSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
            content: Text(
              'Bukti pembayaran belum tersedia karena klaim belum dibayar oleh admin.',
              style: AppTextStyles.interBody.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          );
        },
      );
      return;
    }

    if (buktiBayar == null || buktiBayar.trim().isEmpty) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AppColors.backgroundCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Bukti Pembayaran',
              style: AppTextStyles.poppinsTitleSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
            content: Text(
              'Status sudah dibayar, tetapi bukti pembayaran belum tersedia.',
              style: AppTextStyles.interBody.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          );
        },
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.backgroundCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<String>(
              future: _createSignedImageUrl(
                value: buktiBayar,
                bucketName: _bucketBuktiBayar,
              ),
              builder: (context, snapshot) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.receipt_long_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bukti Pembayaran Admin',
                              style: AppTextStyles.poppinsTitleSmall.copyWith(
                                color: AppColors.primary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['nama_scrim']?.toString() ?? '-',
                        style: AppTextStyles.interBodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dibayar pada: ${_formatDate(dibayarPada)}',
                        style: AppTextStyles.interCaption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        Container(
                          height: 260,
                          width: double.infinity,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: const CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      else if (snapshot.hasError || !snapshot.hasData)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.error),
                          ),
                          child: Text(
                            'Gagal memuat bukti pembayaran: ${snapshot.error ?? '-'}',
                            style: const TextStyle(
                              color: AppColors.error,
                            ),
                          ),
                        )
                      else
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: InteractiveViewer(
                            minScale: 0.8,
                            maxScale: 4,
                            child: Image.network(
                              snapshot.data!,
                              width: double.infinity,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.error),
                                  ),
                                  child: const Text(
                                    'Gagal menampilkan gambar bukti pembayaran.',
                                    style: TextStyle(
                                      color: AppColors.error,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _onPrizeCardTap(Map<String, dynamic> data) {
    _showBuktiPembayaranDialog(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.primary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Klaim Hadiah',
          style: AppTextStyles.poppinsTitle.copyWith(
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _fetchPrizes,
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
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _fetchPrizes,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'Penghargaan Kamu',
                          style: AppTextStyles.poppinsHeadline.copyWith(
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kelola semua hadiah dari scrim yang telah kamu menangkan.',
                          style: AppTextStyles.interBody,
                        ),
                        const SizedBox(height: 32),
                        if (_prizeList.isEmpty)
                          _buildEmptyState()
                        else
                          ..._prizeList.map(
                            (prizeData) => _buildDynamicPrizeCard(
                              context,
                              prizeData,
                            ),
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
            ElevatedButton(
              onPressed: _fetchPrizes,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Text(
          'Belum ada hadiah yang bisa diklaim.',
          style: AppTextStyles.interBody.copyWith(
            color: AppColors.textHint,
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicPrizeCard(BuildContext context, Map<String, dynamic> data) {
    final String statusKlaim = data['status_klaim']?.toString() ?? '';
    final int rank = _parseInt(data['rank']);
    final num nominalHadiah = _parseNum(data['nominal_hadiah']);

    final bool canClaim = _canClaim(statusKlaim, nominalHadiah, rank);

    Widget? actionWidget;

    if (canClaim) {
      actionWidget = Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 24),
        child: ElevatedButton(
          onPressed: () => _openRequestClaim(data),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ajukan Klaim',
                style: AppTextStyles.poppinsButton.copyWith(
                  color: AppColors.black,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.black,
                size: 20,
              ),
            ],
          ),
        ),
      );
    } else {
      actionWidget = Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Row(
          children: [
            Icon(
              statusKlaim == 'dibayar'
                  ? Icons.receipt_long_rounded
                  : Icons.info_outline,
              size: 16,
              color: _statusColor(statusKlaim),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _statusDescription(data),
                style: AppTextStyles.interCaption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () => _onPrizeCardTap(data),
        child: _buildPrizeCard(
          context,
          statusText: _statusHeader(statusKlaim),
          statusColor: _statusColor(statusKlaim),
          title: data['nama_scrim']?.toString() ?? '-',
          badgeText: _statusLabel(statusKlaim),
          badgeColor: _statusBadgeBackground(statusKlaim),
          badgeTextColor: _statusColor(statusKlaim),
          rank: data['rank_label']?.toString() ?? _rankLabel(rank),
          prize: _formatRupiah(nominalHadiah),
          totalPoin: _parseInt(data['total_poin']),
          totalKill: _parseInt(data['total_kill']),
          actionWidget: actionWidget,
        ),
      ),
    );
  }

  Widget _buildPrizeCard(
    BuildContext context, {
    required String statusText,
    required Color statusColor,
    required String title,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required String rank,
    required String prize,
    required int totalPoin,
    required int totalKill,
    Widget? actionWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: AppTextStyles.interCaption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.poppinsTitleSmall.copyWith(
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: AppTextStyles.interCaption.copyWith(
                    color: badgeTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniInfo(
                icon: Icons.star,
                label: 'Rank',
                value: rank,
                alignEnd: false,
              ),
              _buildMiniInfo(
                icon: Icons.emoji_events_outlined,
                label: 'Nominal Hadiah',
                value: prize,
                alignEnd: true,
                valueColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSmallStat(
                  label: 'Total Poin',
                  value: '$totalPoin',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSmallStat(
                  label: 'Total Kill',
                  value: '$totalKill',
                ),
              ),
            ],
          ),
          if (actionWidget != null) actionWidget,
        ],
      ),
    );
  }

  Widget _buildMiniInfo({
    required IconData icon,
    required String label,
    required String value,
    required bool alignEnd,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.interCaption,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.poppinsTitleSmall.copyWith(
            fontSize: 16,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallStat({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.interCaption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.poppinsTitleSmall.copyWith(
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}