import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import 'detail_klaim_page.dart';

class AdminKeuanganPage extends StatefulWidget {
  const AdminKeuanganPage({super.key});

  @override
  State<AdminKeuanganPage> createState() => _AdminKeuanganPageState();
}

class _AdminKeuanganPageState extends State<AdminKeuanganPage> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _error;

  double _totalPendapatan = 0;
  int _klaimPendingCount = 0;

  List<Map<String, dynamic>> _recentKlaim = [];
  Map<String, dynamic>? _urgentKlaim;
  Map<String, dynamic>? _completedKlaim;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userEmail = _supabase.auth.currentUser?.email;
      if (userEmail == null) throw Exception('Sesi habis, silakan login ulang');

      // 1. Ambil id_akun admin yang sedang login
      final akunData = await _supabase
          .from('akun')
          .select('id_akun')
          .eq('email', userEmail)
          .single();
      final int idAkun = akunData['id_akun'] as int;

      // 2. Ambil semua scrim milik admin ini
      final scrimsRaw = await _supabase
          .from('scrim')
          .select('id_scrim, nama_scrim, maks_peserta')
          .eq('id_admin', idAkun);
      final scrims = List<Map<String, dynamic>>.from(scrimsRaw);
      final scrimIds = scrims.map((s) => s['id_scrim'] as int).toList();

      if (scrimIds.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // 3. Ambil keuangan_scrim untuk scrim admin ini → hitung total pendapatan
      final keuanganRaw = await _supabase
          .from('keuangan_scrim')
          .select('total_pendaftaran, fee_admin_10persen, sisa_hadiah, id_scrim')
          .inFilter('id_scrim', scrimIds);

      double totalPendapatan = 0;
      for (final k in keuanganRaw) {
        totalPendapatan += (k['total_pendaftaran'] as num? ?? 0).toDouble();
      }
      _totalPendapatan = totalPendapatan;

      // 4. Ambil id_sesi dari scrim-scrim tersebut
      final sesiRaw = await _supabase
          .from('sesi_scrim')
          .select('id_sesi')
          .inFilter('id_scrim', scrimIds);
      final sesiIds = (sesiRaw as List).map((s) => s['id_sesi'] as int).toList();

      if (sesiIds.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // 5. Ambil id_pendaftaran dari sesi-sesi tersebut
      final pendaftaranRaw = await _supabase
          .from('pendaftaran_tim')
          .select('id_pendaftaran')
          .inFilter('id_sesi', sesiIds);
      final pendaftaranIds = (pendaftaranRaw as List)
          .map((p) => p['id_pendaftaran'] as int)
          .toList();

      if (pendaftaranIds.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // 6. Ambil semua klaim_hadiah untuk pendaftaran tersebut
      final klaimRaw = await _supabase
          .from('klaim_hadiah')
          .select('''
            id_klaim, status_klaim, jumlah_klaim,
            diajukan_pada, dibayar_pada,
            pendaftaran_tim(
              nama_kapten, id_sesi,
              sesi_scrim(
                nama_sesi,
                scrim(nama_scrim, maks_peserta)
              )
            )
          ''')
          .inFilter('id_pendaftaran', pendaftaranIds)
          .order('diajukan_pada', ascending: false);

      final allKlaim = List<Map<String, dynamic>>.from(klaimRaw);

      // Hitung klaim pending
      _klaimPendingCount =
          allKlaim.where((k) => k['status_klaim'] == 'diajukan').length;

      // Recent klaim untuk riwayat (max 5)
      _recentKlaim = allKlaim.take(5).toList();

      // Klaim urgent = yang paling baru dengan status diajukan
      final pendingList =
          allKlaim.where((k) => k['status_klaim'] == 'diajukan').toList();
      _urgentKlaim = pendingList.isNotEmpty ? pendingList.first : null;

      // Klaim completed = yang paling baru dengan status dibayar/disetujui
      final doneList = allKlaim
          .where((k) =>
              k['status_klaim'] == 'dibayar' ||
              k['status_klaim'] == 'disetujui_admin')
          .toList();
      _completedKlaim = doneList.isNotEmpty ? doneList.first : null;
    } catch (e) {
      _error = 'Gagal memuat data: ${e.toString()}';
      debugPrint('Error keuangan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatRupiah(double value) {
    if (value >= 1000000000) {
      return 'Rp ${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value >= 1000000) {
      return 'Rp ${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return 'Rp ${(value / 1000).toStringAsFixed(0)}K';
    }
    return 'Rp ${value.toStringAsFixed(0)}';
  }

  String _formatRupiahFull(double value) {
    final str = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    int counter = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (counter > 0 && counter % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
      counter++;
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  String _formatTanggal(String? raw) {
    if (raw == null) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      const bulan = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      return '${dt.day} ${bulan[dt.month]} ${dt.year}';
    } catch (_) {
      return '-';
    }
  }

  String _namaScrimFromKlaim(Map<String, dynamic> klaim) {
    try {
      return klaim['pendaftaran_tim']['sesi_scrim']['scrim']['nama_scrim']
              as String? ??
          'Scrim';
    } catch (_) {
      return 'Scrim';
    }
  }

  String _namaKaptenFromKlaim(Map<String, dynamic> klaim) {
    try {
      return klaim['pendaftaran_tim']['nama_kapten'] as String? ?? '-';
    } catch (_) {
      return '-';
    }
  }

  int _maksPesertaFromKlaim(Map<String, dynamic> klaim) {
    try {
      return klaim['pendaftaran_tim']['sesi_scrim']['scrim']['maks_peserta']
              as int? ??
          0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Keuangan',
          style: AppTextStyles.poppinsHeadline.copyWith(fontSize: 24),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: _error != null ? _buildError() : _buildBody(context),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(_error!, style: AppTextStyles.interBody, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
              ),
              onPressed: _fetchData,
              child: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── CARD TOTAL SALDO ──
            _buildTotalCard(),
            const SizedBox(height: 20),

            // ── AKSI CEPAT ──
            Row(
              children: [
                Expanded(child: _buildDanaKeluarButton()),
                const SizedBox(width: 16),
                Expanded(child: _buildKlaimPendingButton(context)),
              ],
            ),
            const SizedBox(height: 28),

            // ── RIWAYAT KLAIM ──
            Text(
              'Riwayat Klaim',
              style: AppTextStyles.poppinsSectionTitle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 10),
            _buildRiwayatKlaim(),
            const SizedBox(height: 28),

            // ── DAFTAR KLAIM AKTIF ──
            Text(
              'Daftar Klaim Aktif',
              style: AppTextStyles.poppinsSectionTitle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 14),
            _buildUrgentCard(context),
            const SizedBox(height: 12),
            _buildCompletedCard(context),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Saldo Keuangan',
            style: AppTextStyles.interLabel.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            _formatRupiah(_totalPendapatan),
            style: AppTextStyles.poppinsMoneyLarge.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.arrow_upward, color: AppColors.success, size: 16),
              const SizedBox(width: 4),
              Text(
                'Dari ${_klaimPendingCount > 0 ? "$_klaimPendingCount klaim menunggu" : "semua scrim aktif"}',
                style: AppTextStyles.interCaption.copyWith(color: AppColors.success),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDanaKeluarButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          const Icon(Icons.money_off, color: AppColors.primary, size: 28),
          const SizedBox(height: 8),
          Text('Dana Keluar', style: AppTextStyles.interBody.copyWith(fontSize: 13)),
          const SizedBox(height: 2),
          Text(
            _completedKlaim != null
                ? _formatRupiah(
                    (_completedKlaim!['jumlah_klaim'] as num? ?? 0).toDouble())
                : 'Rp 0',
            style: AppTextStyles.interCaption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKlaimPendingButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DetailKlaimPage()),
      ),
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$_klaimPendingCount',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text('Klaim Pending', style: AppTextStyles.interBody.copyWith(fontSize: 13)),
            const SizedBox(height: 2),
            Text(
              'Segera Proses',
              style: AppTextStyles.interCaption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayatKlaim() {
    if (_recentKlaim.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              const Icon(Icons.receipt_long_outlined,
                  size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                'Belum ada klaim',
                style: AppTextStyles.interBody.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentKlaim.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final klaim = _recentKlaim[index];
        final status = klaim['status_klaim'] as String? ?? '';
        final isPaid = status == 'dibayar';
        final Color color = isPaid ? AppColors.success : AppColors.primary;
        final double jumlah =
            (klaim['jumlah_klaim'] as num? ?? 0).toDouble();
        final tanggal = _formatTanggal(klaim['diajukan_pada'] as String?);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(
                  isPaid ? Icons.call_received : Icons.pending_actions,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _namaScrimFromKlaim(klaim),
                      style: AppTextStyles.interBodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _namaKaptenFromKlaim(klaim),
                      style: AppTextStyles.interCaption.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(tanggal, style: AppTextStyles.interCaption),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatRupiahFull(jumlah),
                    style: AppTextStyles.poppinsMoneySmall.copyWith(
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusChip(status),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    late String label;
    late Color color;
    switch (status) {
      case 'diajukan':
        label = 'Menunggu';
        color = AppColors.primary;
        break;
      case 'disetujui_admin':
        label = 'Disetujui';
        color = AppColors.success;
        break;
      case 'dibayar':
        label = 'Dibayar';
        color = AppColors.success;
        break;
      default:
        label = status;
        color = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildUrgentCard(BuildContext context) {
    if (_urgentKlaim == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Center(
          child: Text(
            'Tidak ada klaim menunggu proses',
            style: AppTextStyles.interBody.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final klaim = _urgentKlaim!;
    final namaEvent = _namaScrimFromKlaim(klaim);
    final tanggal = _formatTanggal(klaim['diajukan_pada'] as String?);
    final jumlah = (klaim['jumlah_klaim'] as num? ?? 0).toDouble();
    final maksPeserta = _maksPesertaFromKlaim(klaim);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0B141C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=600',
          ),
          fit: BoxFit.cover,
          opacity: 0.15,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'URGENT',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(tanggal, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    namaEvent,
                    style: AppTextStyles.poppinsTitleSmall.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_klaimPendingCount Pending',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.people, color: Colors.grey, size: 14),
                const SizedBox(width: 4),
                Text(
                  '$maksPeserta Tim',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(width: 8),
                const Text('•', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 8),
                Text(
                  _formatRupiahFull(jumlah),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DetailKlaimPage()),
                ),
                child: const Text(
                  'Detail Klaim',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedCard(BuildContext context) {
    if (_completedKlaim == null) {
      return const SizedBox.shrink();
    }

    final klaim = _completedKlaim!;
    final namaEvent = _namaScrimFromKlaim(klaim);
    final tanggal = _formatTanggal(
      (klaim['dibayar_pada'] ?? klaim['diajukan_pada']) as String?,
    );
    final jumlah = (klaim['jumlah_klaim'] as num? ?? 0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0B141C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(tanggal,
                      style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(width: 6),
                  const Text('•', style: TextStyle(color: Colors.grey)),
                  const SizedBox(width: 6),
                  const Text(
                    'COMPLETED',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.history, color: Colors.grey, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            namaEvent,
            style: AppTextStyles.poppinsTitleSmall.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatRupiahFull(jumlah),
            style: AppTextStyles.poppinsMoneyLarge.copyWith(fontSize: 20),
          ),
          const Divider(color: Colors.white10, height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Klaim sudah diselesaikan',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24, width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DetailKlaimPage()),
                ),
                child: const Text(
                  'Lihat Riwayat',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
