// lib/presentation/admin/peserta_management_page.dart
//
// Isi tab "Peserta" pada AdminMainNavigator.
// PENTING: halaman ini TIDAK punya bottomNavigationBar sendiri —
// bottom nav sudah disediakan oleh AdminMainNavigator. Kalau halaman
// tab juga menaruh bottom nav, akan muncul DUA bar bertumpuk.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_session.dart';

import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/peserta_verifikasi_model.dart';
import 'participant_detail_page.dart';

class PesertaManagementPage extends StatefulWidget {
  const PesertaManagementPage({super.key});

  @override
  State<PesertaManagementPage> createState() => _PesertaManagementPageState();
}

class _PesertaManagementPageState extends State<PesertaManagementPage> {
  final _supabase = Supabase.instance.client;

  int _selectedTab = 0;
  static const _tabs = ['Semua', 'Menunggu', 'Konfirmasi', 'Ditolak'];

  bool _isLoading = true;
  String? _errorMessage;
  String _emptyReason = 'Belum ada peserta';
  List<PesertaVerifikasi> _peserta = [];

  List<PesertaVerifikasi> get _filtered {
    if (_selectedTab == 0) return _peserta;
    final target = _tabs[_selectedTab];
    return _peserta.where((p) => p.status.tab == target).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final email = _supabase.sessionEmail;
      if (email == null) throw Exception('Belum login');

      final akunData = await _supabase
          .from('akun')
          .select('id_akun')
          .eq('email', email!)
          .single();
      final int adminId = akunData['id_akun'];

      final scrims = await _supabase
          .from('scrim')
          .select('id_scrim, nama_scrim, biaya_pendaftaran')
          .eq('id_admin', adminId);

      if ((scrims as List).isEmpty) {
        setState(() { _peserta = []; _isLoading = false; _emptyReason = 'Admin belum memiliki scrim.\nBuat scrim terlebih dahulu di menu tambah (+).'; });
        return;
      }

      final scrimIds = scrims.map((s) => s['id_scrim'] as int).toList();
      final scrimMap = <int, Map<String, dynamic>>{
        for (var s in scrims) s['id_scrim'] as int: Map<String, dynamic>.from(s)
      };

      final sessions = await _supabase
          .from('sesi_scrim')
          .select('id_sesi, id_scrim, nama_sesi, waktu_mulai, waktu_selesai')
          .inFilter('id_scrim', scrimIds);

      if ((sessions as List).isEmpty) {
        setState(() { _peserta = []; _isLoading = false; _emptyReason = 'Scrim ditemukan (${scrims.length}) tapi belum ada sesi.\nTambahkan sesi ke scrim anda.'; });
        return;
      }

      final sesiIds = sessions.map((s) => s['id_sesi'] as int).toList();
      final sesiMap = <int, Map<String, dynamic>>{
        for (var s in sessions) s['id_sesi'] as int: Map<String, dynamic>.from(s)
      };

      final pendaftaran = await _supabase
          .from('pendaftaran_tim')
          .select('id_pendaftaran, id_sesi, akun_id, nama_kapten, whatsapp_kapten, id_player_1, id_player_2, id_player_3, id_player_4, metode_pembayaran_daftar, bukti_pembayaran, status_pembayaran, dibuat_pada')
          .inFilter('id_sesi', sesiIds)
          .order('dibuat_pada', ascending: false);

      if ((pendaftaran as List).isEmpty) {
        setState(() { _peserta = []; _isLoading = false; _emptyReason = 'Scrim & sesi ada, tapi belum ada user yang mendaftar.'; });
        return;
      }

      final akunIds = pendaftaran
          .map((p) => p['akun_id'] as int?)
          .whereType<int>()
          .toSet()
          .toList();

      final profils = akunIds.isNotEmpty
          ? await _supabase
              .from('profil_pengguna')
              .select('akun_id, nama_tim')
              .inFilter('akun_id', akunIds)
          : <dynamic>[];

      final profilMap = <int, String>{
        for (var p in profils)
          (p['akun_id'] as int): (p['nama_tim'] as String? ?? '-')
      };

      final result = <PesertaVerifikasi>[];
      for (final p in pendaftaran) {
        final sesiId = p['id_sesi'] as int?;
        if (sesiId == null) continue;
        final sesi = sesiMap[sesiId];
        if (sesi == null) continue;

        final scrimId = sesi['id_scrim'] as int?;
        if (scrimId == null) continue;
        final scrim = scrimMap[scrimId];
        if (scrim == null) continue;

        final akunId = p['akun_id'] as int?;
        final namaTim = akunId != null ? (profilMap[akunId] ?? 'Tim $akunId') : '-';

        DateTime? waktuMulai, waktuSelesai;
        try {
          waktuMulai = DateTime.parse(sesi['waktu_mulai'] ?? '').toLocal();
          waktuSelesai = DateTime.parse(sesi['waktu_selesai'] ?? '').toLocal();
        } catch (_) {}

        final tanggal = waktuMulai != null
            ? '${waktuMulai.day} ${_bulan(waktuMulai.month)} ${waktuMulai.year}'
            : '-';
        final waktu = (waktuMulai != null && waktuSelesai != null)
            ? '${_dd(waktuMulai.hour)}.${_dd(waktuMulai.minute)} - ${_dd(waktuSelesai.hour)}.${_dd(waktuSelesai.minute)} WIB'
            : '-';

        result.add(PesertaVerifikasi(
          idPendaftaran: p['id_pendaftaran'] as int,
          idScrim: scrimId,
          namaTim: namaTim,
          namaKapten: p['nama_kapten'] as String? ?? '-',
          whatsappKapten: p['whatsapp_kapten'] as String? ?? '-',
          status: StatusPesertaX.fromString(p['status_pembayaran'] as String? ?? 'menunggu'),
          namaScrim: scrim['nama_scrim'] as String? ?? '-',
          slotId: '#${p['id_pendaftaran']}',
          tanggal: tanggal,
          waktu: waktu,
          nominal: (scrim['biaya_pendaftaran'] as num?)?.toInt() ?? 0,
          bankPengirim: p['metode_pembayaran_daftar'] as String? ?? '-',
          namaPengirim: p['nama_kapten'] as String? ?? '-',
          buktiPembayaranUrl: p['bukti_pembayaran'] as String?,
          idPlayer1: p['id_player_1'] as String?,
          idPlayer2: p['id_player_2'] as String?,
          idPlayer3: p['id_player_3'] as String?,
          idPlayer4: p['id_player_4'] as String?,
        ));
      }

      setState(() { _peserta = result; _isLoading = false; });
    } catch (e) {
      setState(() { _errorMessage = 'Gagal memuat data: $e'; _isLoading = false; });
    }
  }

  static String _bulan(int m) =>
      ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'][m - 1];

  static String _dd(int n) => n.toString().padLeft(2, '0');

  Future<void> _openDetail(PesertaVerifikasi peserta) async {
    final updated = await Navigator.of(context).push<PesertaVerifikasi>(
      MaterialPageRoute(
        builder: (_) => ParticipantDetailPage(peserta: peserta),
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        final i = _peserta.indexWhere(
          (p) => p.idPendaftaran == updated.idPendaftaran,
        );
        if (i != -1) _peserta[i] = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          const SizedBox(height: AppConstants.paddingS),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppConstants.paddingM),
            Text(_errorMessage!, style: AppTextStyles.interBody.copyWith(color: AppColors.textHint), textAlign: TextAlign.center),
            const SizedBox(height: AppConstants.paddingM),
            TextButton(onPressed: _fetchData, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }
    final list = _filtered;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchData,
      child: list.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              primary: false,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppConstants.paddingM,
                AppConstants.paddingS,
                AppConstants.paddingM,
                110,
              ),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppConstants.paddingM),
              itemBuilder: (_, i) => _PesertaCard(
                peserta: list[i],
                onTap: () => _openDetail(list[i]),
              ),
            ),
    );
  }

  // ===================== HEADER =====================
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingM,  // 16
        AppConstants.paddingM,  // 16
        AppConstants.paddingM,  // 16
        AppConstants.paddingS,  // 8
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manajemen Peserta',
                  style: AppTextStyles.poppinsHeadline,
                ),
                const SizedBox(height: AppConstants.paddingXS),
                Text(
                  'Kelola peserta & verifikasi pembayaran',
                  style: AppTextStyles.interBody,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== TAB BAR =====================
  Widget _buildTabBar() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final selected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _tabs[i],
                    style: AppTextStyles.interBodyMedium.copyWith(
                      color: selected ? AppColors.primary : AppColors.textHint,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: AppConstants.animationDuration,
                    height: 3,
                    width: selected ? 22 : 0,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ===================== EMPTY STATE =====================
  Widget _buildEmptyState() {
    final isFilteredTab = _selectedTab != 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: AppColors.textDisabled),
            const SizedBox(height: AppConstants.paddingM),
            Text(
              isFilteredTab
                  ? 'Belum ada peserta di tab "${_tabs[_selectedTab]}"'
                  : _emptyReason,
              style: AppTextStyles.interBody.copyWith(color: AppColors.textHint),
              textAlign: TextAlign.center,
            ),
            if (isFilteredTab && _peserta.isNotEmpty) ...[
              const SizedBox(height: AppConstants.paddingS),
              Text(
                'Ada ${_peserta.length} peserta di tab "Semua"',
                style: AppTextStyles.interCaption.copyWith(color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
            ],
            if (isFilteredTab && _peserta.isEmpty) ...[
              const SizedBox(height: AppConstants.paddingS),
              Text(
                _emptyReason,
                style: AppTextStyles.interCaption.copyWith(color: AppColors.textHint),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// KARTU PESERTA
// ============================================================
class _PesertaCard extends StatelessWidget {
  final PesertaVerifikasi peserta;
  final VoidCallback onTap;

  const _PesertaCard({required this.peserta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundCard,
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      peserta.namaTim,
                      style: AppTextStyles.poppinsTitleSmall,
                    ),
                  ),
                  StatusBadge(status: peserta.status),
                ],
              ),
              const SizedBox(height: AppConstants.paddingXS),
              Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Capt: ${peserta.namaKapten}',
                    style: AppTextStyles.interCaption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppConstants.paddingM),
                child: Divider(height: 1, color: AppColors.divider),
              ),
              Row(
                children: [
                  Expanded(child: _miniInfo('SCRIM', peserta.namaScrim)),
                  Expanded(
                    child: _miniInfo(
                      'SESI',
                      '${peserta.tanggal.split(' ').take(2).join(' ')}, '
                          '${peserta.waktu}',
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniInfo(String label, String value, {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.interCaption.copyWith(
            color: AppColors.textHint,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: AppTextStyles.interBodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// BADGE STATUS — dipakai di list & detail peserta
// ============================================================
class StatusBadge extends StatelessWidget {
  final StatusPeserta status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    switch (status) {
      case StatusPeserta.dikonfirmasi:
        color = AppColors.success;
        break;
      case StatusPeserta.ditolak:
        color = AppColors.error;
        break;
      case StatusPeserta.menunggu:
        color = AppColors.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.interStatus.copyWith(color: color),
      ),
    );
  }
}
