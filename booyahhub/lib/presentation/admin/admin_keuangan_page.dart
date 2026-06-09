import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import 'daftar_klaim_aktif_page.dart';

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
  double _totalDanaKeluar = 0;
  int _klaimPendingCount = 0;

  List<Map<String, dynamic>> _urgentGroups = [];
  List<Map<String, dynamic>> _completedGroups = [];

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

      // 2. Ambil semua scrim milik admin ini (termasuk biaya_pendaftaran)
      final scrimsRaw = await _supabase
          .from('scrim')
          .select('id_scrim, nama_scrim, maks_peserta, biaya_pendaftaran')
          .eq('id_admin', idAkun);
      final scrims = List<Map<String, dynamic>>.from(scrimsRaw);
      final scrimIds = scrims.map((s) => s['id_scrim'] as int).toList();

      if (scrimIds.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final biayaPerScrim = <int, double>{
        for (var s in scrims)
          s['id_scrim'] as int: (s['biaya_pendaftaran'] as num? ?? 0).toDouble()
      };

      // 3. Ambil id_sesi + id_scrim
      final scrimMap = <int, Map<String, dynamic>>{
        for (var s in scrims) s['id_scrim'] as int: Map<String, dynamic>.from(s)
      };
      final sesiRaw = await _supabase
          .from('sesi_scrim')
          .select('id_sesi, id_scrim')
          .inFilter('id_scrim', scrimIds);
      final sesiToScrim = <int, int>{
        for (var s in sesiRaw as List) s['id_sesi'] as int: s['id_scrim'] as int
      };
      final sesiIds = sesiToScrim.keys.toList();

      if (sesiIds.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // 4. Ambil pendaftaran + status_pembayaran untuk hitung pendapatan
      final pendaftaranRaw = await _supabase
          .from('pendaftaran_tim')
          .select('id_pendaftaran, id_sesi, status_pembayaran')
          .inFilter('id_sesi', sesiIds);
      final pendaftaranToScrim = <int, int>{};
      double totalPendapatan = 0;
      for (final p in pendaftaranRaw as List) {
        final scrimId = sesiToScrim[p['id_sesi'] as int];
        if (scrimId == null) continue;
        pendaftaranToScrim[p['id_pendaftaran'] as int] = scrimId;
        if ((p['status_pembayaran'] as String? ?? '') == 'dikonfirmasi') {
          totalPendapatan += biayaPerScrim[scrimId] ?? 0;
        }
      }
      // Dana keluar = sisa setelah fee platform 5% dan admin 10%
      const double feeTotal = 0.15;
      _totalPendapatan = totalPendapatan;
      _totalDanaKeluar = totalPendapatan * (1 - feeTotal);

      final pendaftaranIds = pendaftaranToScrim.keys.toList();

      if (pendaftaranIds.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // 6. Ambil semua klaim_hadiah untuk pendaftaran tersebut
      final klaimRaw = await _supabase
          .from('klaim_hadiah')
          .select('''
            id_klaim, id_pendaftaran, status_klaim, jumlah_klaim,
            diajukan_pada, dibayar_pada,
            pendaftaran_tim(
              nama_kapten, id_sesi,
              sesi_scrim(nama_sesi, scrim(nama_scrim, maks_peserta))
            )
          ''')
          .inFilter('id_pendaftaran', pendaftaranIds)
          .order('diajukan_pada', ascending: false);

      final allKlaim = List<Map<String, dynamic>>.from(klaimRaw);

      // Group klaim by scrim
      final pendingByScrim = <int, List<Map<String, dynamic>>>{};
      final completedByScrim = <int, List<Map<String, dynamic>>>{};
      for (final k in allKlaim) {
        final pendId = k['id_pendaftaran'] as int? ?? 0;
        final scrimId = pendaftaranToScrim[pendId];
        if (scrimId == null) continue;
        final status = k['status_klaim'] as String? ?? '';
        if (status == 'diajukan' || status == 'disetujui_admin' || status == 'diteruskan_owner') {
          pendingByScrim.putIfAbsent(scrimId, () => []).add(Map<String, dynamic>.from(k));
        } else if (status == 'dibayar') {
          completedByScrim.putIfAbsent(scrimId, () => []).add(Map<String, dynamic>.from(k));
        }
      }

      _urgentGroups = [];
      pendingByScrim.forEach((scrimId, items) {
        final scrim = scrimMap[scrimId];
        if (scrim == null) return;
        final total = items.fold<double>(0, (s, k) => s + ((k['jumlah_klaim'] as num?)?.toDouble() ?? 0));
        final tgl = items.first['diajukan_pada'] as String?;
        _urgentGroups.add({
          'nama_event': scrim['nama_scrim'] ?? '-',
          'tanggal': tgl != null ? _formatTanggal(tgl) : '-',
          'jumlah_pending': items.length,
          'jumlah_tim': scrim['maks_peserta'] as int? ?? 0,
          'nominal': total,
        });
      });

      _completedGroups = [];
      completedByScrim.forEach((scrimId, items) {
        if (pendingByScrim.containsKey(scrimId)) return;
        final scrim = scrimMap[scrimId];
        if (scrim == null) return;
        final total = items.fold<double>(0, (s, k) => s + ((k['jumlah_klaim'] as num?)?.toDouble() ?? 0));
        final tgl = items.first['dibayar_pada'] as String? ?? items.first['diajukan_pada'] as String?;
        _completedGroups.add({
          'nama_event': scrim['nama_scrim'] ?? '-',
          'tanggal': tgl != null ? _formatTanggal(tgl) : '-',
          'nominal': total,
        });
      });

      _klaimPendingCount = _urgentGroups.fold(0, (s, g) => s + (g['jumlah_pending'] as int));
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

            // ── DAFTAR KLAIM AKTIF ──
            Text(
              'Daftar Klaim Aktif',
              style: AppTextStyles.poppinsSectionTitle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 14),
            if (_urgentGroups.isEmpty && _completedGroups.isEmpty)
              Container(
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
              )
            else ...[
              ..._urgentGroups.map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildUrgentCard(context, g),
                  )),
              ..._completedGroups.map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildCompletedCard(context, g),
                  )),
            ],
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
            'TOTAL PENDAPATAN',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatRupiah(_totalPendapatan),
            style: AppTextStyles.poppinsMoneyLarge.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.arrow_upward, color: AppColors.success, size: 14),
              const SizedBox(width: 4),
              Text(
                'Dari semua scrim aktif',
                style: AppTextStyles.interCaption.copyWith(color: AppColors.success),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDanaKeluarButton() {
    final pct = _totalPendapatan > 0
        ? ((_totalDanaKeluar / _totalPendapatan) * 100).toStringAsFixed(0)
        : '0';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DANA KELUAR',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatRupiah(_totalDanaKeluar),
            style: AppTextStyles.poppinsMoneyLarge.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            '$pct% Terverifikasi',
            style: TextStyle(
              color: AppColors.success,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKlaimPendingButton(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(
            color: _klaimPendingCount > 0
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.divider.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KLAIM PENDING',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$_klaimPendingCount',
              style: TextStyle(
                color: _klaimPendingCount > 0 ? AppColors.primary : AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Segera Proses',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildUrgentCard(BuildContext context, Map<String, dynamic> g) {
    final namaEvent = g['nama_event'] as String? ?? '-';
    final tanggal = g['tanggal'] as String? ?? '-';
    final jumlah = (g['nominal'] as num? ?? 0).toDouble();
    final int pending = g['jumlah_pending'] as int? ?? 0;
    final int tim = g['jumlah_tim'] as int? ?? 0;

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
                    '$pending Pending',
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
                  '$tim Tim',
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
                  MaterialPageRoute(builder: (_) => const DaftarKlaimAktifPage()),
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

  Widget _buildCompletedCard(BuildContext context, Map<String, dynamic> g) {
    final namaEvent = g['nama_event'] as String? ?? '-';
    final tanggal = g['tanggal'] as String? ?? '-';
    final jumlah = (g['nominal'] as num? ?? 0).toDouble();

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
                  MaterialPageRoute(builder: (_) => const DaftarKlaimAktifPage()),
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
