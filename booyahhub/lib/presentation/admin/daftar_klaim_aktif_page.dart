import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

class DaftarKlaimAktifPage extends StatefulWidget {
  const DaftarKlaimAktifPage({super.key});

  @override
  State<DaftarKlaimAktifPage> createState() => _DaftarKlaimAktifPageState();
}

class _DaftarKlaimAktifPageState extends State<DaftarKlaimAktifPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  // Scrims with pending klaim (diajukan)
  List<Map<String, dynamic>> _urgentGroups = [];
  // Scrims with all klaim completed (dibayar)
  List<Map<String, dynamic>> _completedGroups = [];

  @override
  void initState() {
    super.initState();
    _fetchKlaim();
  }

  Future<void> _fetchKlaim() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final akunData = await _supabase
          .from('akun')
          .select('id_akun')
          .eq('email', user.email!)
          .maybeSingle();
      if (akunData == null) return;
      final adminId = akunData['id_akun'] as int;

      // 1. Get admin's scrims
      final scrims = await _supabase
          .from('scrim')
          .select('id_scrim, nama_scrim, total_hadiah')
          .eq('id_admin', adminId);
      if ((scrims as List).isEmpty) {
        setState(() { _urgentGroups = []; _completedGroups = []; _isLoading = false; });
        return;
      }

      // 2. Get sessions for those scrims
      final scrimIds = scrims.map((s) => s['id_scrim'] as int).toList();
      final scrimMap = <int, Map<String, dynamic>>{
        for (var s in scrims as List) s['id_scrim'] as int: Map<String, dynamic>.from(s)
      };

      final sessions = await _supabase
          .from('sesi_scrim')
          .select('id_sesi, id_scrim')
          .inFilter('id_scrim', scrimIds);
      if ((sessions as List).isEmpty) {
        setState(() { _urgentGroups = []; _completedGroups = []; _isLoading = false; });
        return;
      }
      final sesiToScrim = <int, int>{
        for (var s in sessions as List) s['id_sesi'] as int: s['id_scrim'] as int
      };
      final sesiIds = sesiToScrim.keys.toList();

      // 3. Get pendaftaran for those sessions
      final pendaftaran = await _supabase
          .from('pendaftaran_tim')
          .select('id_pendaftaran, id_sesi')
          .inFilter('id_sesi', sesiIds);
      if ((pendaftaran as List).isEmpty) {
        setState(() { _urgentGroups = []; _completedGroups = []; _isLoading = false; });
        return;
      }
      final pendaftaranToScrim = <int, int>{};
      for (final p in pendaftaran as List) {
        final sesiId = p['id_sesi'] as int;
        final scrimId = sesiToScrim[sesiId];
        if (scrimId != null) {
          pendaftaranToScrim[p['id_pendaftaran'] as int] = scrimId;
        }
      }
      final pendaftaranIds = pendaftaranToScrim.keys.toList();

      // 4. Get klaim_hadiah for those pendaftaran
      final klaims = await _supabase
          .from('klaim_hadiah')
          .select('id_klaim, id_pendaftaran, status_klaim, jumlah_klaim, diajukan_pada')
          .inFilter('id_pendaftaran', pendaftaranIds)
          .order('diajukan_pada', ascending: false);

      // 5. Group by scrim
      final pendingByScrim = <int, List<Map<String, dynamic>>>{};
      final completedByScrim = <int, List<Map<String, dynamic>>>{};

      for (final k in klaims as List) {
        final pendId = k['id_pendaftaran'] as int;
        final scrimId = pendaftaranToScrim[pendId];
        if (scrimId == null) continue;

        final status = k['status_klaim'] as String? ?? '';
        final isCompleted = status == 'dibayar';

        if (isCompleted) {
          completedByScrim.putIfAbsent(scrimId, () => []).add(Map<String, dynamic>.from(k));
        } else if (status == 'diajukan' || status == 'disetujui_admin' || status == 'diteruskan_owner') {
          pendingByScrim.putIfAbsent(scrimId, () => []).add(Map<String, dynamic>.from(k));
        }
      }

      // Build urgent groups
      final urgent = <Map<String, dynamic>>[];
      pendingByScrim.forEach((scrimId, items) {
        final scrim = scrimMap[scrimId];
        if (scrim == null) return;
        final total = items.fold<double>(0, (sum, k) => sum + ((k['jumlah_klaim'] as num?)?.toDouble() ?? 0));
        final tanggal = items.first['diajukan_pada'] as String?;
        urgent.add({
          'scrim_id': scrimId,
          'nama_event': scrim['nama_scrim'] ?? '-',
          'tanggal': tanggal != null ? _formatDate(DateTime.parse(tanggal)) : '-',
          'jumlah_pending': items.length,
          'jumlah_tim': items.length,
          'nominal': total,
        });
      });

      // Build completed groups
      final completed = <Map<String, dynamic>>[];
      completedByScrim.forEach((scrimId, items) {
        // Skip if also has pending (show as urgent instead)
        if (pendingByScrim.containsKey(scrimId)) return;
        final scrim = scrimMap[scrimId];
        if (scrim == null) return;
        final total = items.fold<double>(0, (sum, k) => sum + ((k['jumlah_klaim'] as num?)?.toDouble() ?? 0));
        final tanggal = items.first['diajukan_pada'] as String?;
        completed.add({
          'scrim_id': scrimId,
          'nama_event': scrim['nama_scrim'] ?? '-',
          'tanggal': tanggal != null ? _formatDate(DateTime.parse(tanggal)) : '-',
          'nominal': total,
        });
      });

      setState(() {
        _urgentGroups = urgent;
        _completedGroups = completed;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching klaim: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatRupiah(double value) {
    final str = value.toInt().toString();
    final buffer = StringBuffer();
    int counter = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (counter > 0 && counter % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
      counter++;
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Daftar Klaim Aktif',
          style: AppTextStyles.poppinsTitle.copyWith(
            color: AppColors.primary,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _fetchKlaim,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _fetchKlaim,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppConstants.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_urgentGroups.isEmpty && _completedGroups.isEmpty)
                      _buildEmpty(),
                    ..._urgentGroups.map((g) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildUrgentCard(context, g),
                        )),
                    ..._completedGroups.map((g) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildCompletedCard(context, g),
                        )),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('Belum ada klaim aktif', style: AppTextStyles.interBody.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgentCard(BuildContext context, Map<String, dynamic> g) {
    final int pending = g['jumlah_pending'] as int;
    final int tim = g['jumlah_tim'] as int;
    final double nominal = g['nominal'] as double;
    final String namaEvent = g['nama_event'] as String;
    final String tanggal = g['tanggal'] as String;

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
                      letterSpacing: 0.5,
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
                Text('$tim Tim', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(width: 8),
                const Text('•', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 8),
                Text(
                  _formatRupiah(nominal),
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
                onPressed: () {
                  // TODO: navigate to detail klaim per scrim
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Detail Klaim',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.account_balance_wallet_outlined, color: Colors.black, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedCard(BuildContext context, Map<String, dynamic> g) {
    final String namaEvent = g['nama_event'] as String;
    final String tanggal = g['tanggal'] as String;
    final double nominal = g['nominal'] as double;

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
                  Text(tanggal, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(width: 6),
                  const Text('•', style: TextStyle(color: Colors.grey)),
                  const SizedBox(width: 6),
                  const Text(
                    'COMPLETED',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
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
            style: AppTextStyles.poppinsTitleSmall.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(_formatRupiah(nominal), style: AppTextStyles.poppinsMoneyLarge.copyWith(fontSize: 20)),
          const Divider(color: Colors.white10, height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Semua klaim telah dibayar',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24, width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () {
                  // TODO: navigate to riwayat klaim
                },
                child: const Text('Lihat Riwayat', style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
