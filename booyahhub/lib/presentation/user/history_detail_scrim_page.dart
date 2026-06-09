import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../user/request_claim_prize_page.dart';

class HistoryDetailScrimPage extends StatefulWidget {
  final int idPendaftaran; // Dikirim dinamis dari halaman riwayat

  const HistoryDetailScrimPage({
    super.key,
    required this.idPendaftaran,
  });

  @override
  State<HistoryDetailScrimPage> createState() => _HistoryDetailScrimPageState();
}

class _HistoryDetailScrimPageState extends State<HistoryDetailScrimPage> {
  Future<Map<String, dynamic>>? _scrimDetailFuture;

  @override
  void initState() {
    super.initState();
    _scrimDetailFuture = _fetchDetailScrim();
  }

  Future<Map<String, dynamic>> _fetchDetailScrim() async {
    try {
      final supabase = Supabase.instance.client;

      // Fetch detail join antar tabel di Supabase
      final response = await supabase
          .from('pendaftaran_tim')
          .select('''
            id_pendaftaran,
            status_pertandingan,
            dibuat_pada,
            akun(
              profil_pengguna(
                nama_tim
              )
            ),
            sesi_scrim(
              id_sesi,
              scrim(
                nama_scrim
              )
            ),
            hasil_pertandingan(*)
          ''')
          .eq('id_pendaftaran', widget.idPendaftaran)
          .maybeSingle();

      if (response == null) {
        throw 'Data detail scrim tidak ditemukan bray.';
      }

      // Parsing Relasi Sesi & Scrim
      final Map<String, dynamic>? sesiScrimData = response['sesi_scrim'] as Map<String, dynamic>?;
      final Map<String, dynamic>? scrimData = sesiScrimData?['scrim'] as Map<String, dynamic>?;
      final List<dynamic> hasilList = response['hasil_pertandingan'] ?? [];
      
      // Mengambil nama_tim dari relasi akun -> profil_pengguna
      String namaTim = 'No Team Name';
      final akunData = response['akun'] as Map<String, dynamic>?;
      final profilPenggunaData = akunData?['profil_pengguna'];
      if (profilPenggunaData is List && profilPenggunaData.isNotEmpty) {
        namaTim = profilPenggunaData[0]['nama_tim'] ?? 'No Team Name';
      } else if (profilPenggunaData is Map) {
        namaTim = profilPenggunaData['nama_tim'] ?? 'No Team Name';
      }

      // Parsing Tanggal & Waktu otomatis dari dibuat_pada
      String bulan = '---';
      String tanggalAngka = '--';
      String jam = '--:--';
      String zonaWaktu = 'WIB';

      if (response['dibuat_pada'] != null) {
        DateTime dateParsed = DateTime.parse(response['dibuat_pada']);
        bulan = DateFormat('MMM').format(dateParsed).toUpperCase();
        tanggalAngka = DateFormat('dd').format(dateParsed);
        jam = DateFormat('HH.mm').format(dateParsed);
      }

      // Parsing Data Hasil Pertandingan
      String peringkatAkhir = 'BELUM MULAI';
      int totalPoin = 0;
      int totalKills = 0;

      if (hasilList.isNotEmpty) {
        final int rank = hasilList[0]['peringkat'] ?? 0;
        peringkatAkhir = rank == 1 ? 'JUARA 1' : rank == 2 ? 'JUARA 2' : rank == 3 ? 'JUARA 3' : 'RANK $rank';
        totalPoin = hasilList[0]['total_poin'] ?? 0;
        totalKills = hasilList[0]['total_kill'] ?? 0;
      }

      return {
        'nama_scrim': scrimData?['nama_scrim'] ?? 'Scrim Match #${response['id_pendaftaran']}',
        'bulan': bulan,
        'tanggal_angka': tanggalAngka,
        'jam': jam,
        'zona_waktu': zonaWaktu,
        'nama_tim': namaTim,
        'peringkat_akhir': peringkatAkhir,
        'total_poin': totalPoin,
        'total_kills': totalKills,
        'status': response['status_pertandingan'] ?? 'belum_mulai',
        'id_sesi': sesiScrimData?['id_sesi'] ?? 0,
        'id_pendaftaran': response['id_pendaftaran'],
      };
    } catch (e) {
      print('Eror ambil detail bray: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Detail Riwayat Scrim',
          style: AppTextStyles.poppinsTitle.copyWith(fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _scrimDetailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  child: Text(
                    'Gagal memuat detail scrim bray: ${snapshot.error}',
                    style: AppTextStyles.interBody.copyWith(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            final bool isCancelled = data['status'] == 'dibatalkan';

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _scrimDetailFuture = _fetchDetailScrim();
                });
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppConstants.paddingM),

                    // ─── 1. CARD INFO SESI SCRIM ──────────────────────────────────
                    _buildScrimInfoCard(data),

                    const SizedBox(height: AppConstants.paddingXL),

                    // ─── 2. SECTION HEADER "Hasil Scrim" ──────────────────────────
                    Text(
                      'Hasil Scrim',
                      style: AppTextStyles.poppinsSectionTitle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: AppConstants.paddingM),

                    // ─── 3. PERINGKAT AKHIR CARD ──────────────────────────────────
                    _buildPeringkatCard(data, isCancelled),

                    const SizedBox(height: AppConstants.paddingM),

                    // ─── 4. TOTAL POIN & KILLS ────────────────────────────────────
                    _buildStatsRow(data),

                    const SizedBox(height: AppConstants.paddingXL),

                    // ─── 5. TOMBOL AJUKAN KLAIM & LEADERBOARD ──────────────────────
                    if (!isCancelled) ...[
                      _buildClaimButton(context, data),
                      const SizedBox(height: AppConstants.paddingM),
                      _buildLeaderboardButton(context, data),
                      const SizedBox(height: AppConstants.paddingXL),
                    ],

                    if (isCancelled) ...[
                      _buildCancelledInfo(),
                      const SizedBox(height: AppConstants.paddingXL),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGET: SCRIM INFO CARD (Bagian Atas)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildScrimInfoCard(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.inputBorder.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SESI SCRIM',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data['nama_scrim'],
                        style: AppTextStyles.poppinsHeadline.copyWith(fontSize: 22),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    border: Border.all(color: AppColors.inputBorder, width: 1),
                  ),
                  child: Column(
                    children: [
                      Text(
                        data['bulan'],
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data['tanggal_angka'],
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
            child: Divider(color: AppColors.inputBorder.withOpacity(0.5), thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.access_time_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TIME',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${data['jam']}',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            data['zona_waktu'],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'YOUR TEAM',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data['nama_tim'],
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET: PERINGKAT AKHIR CARD
  Widget _buildPeringkatCard(Map<String, dynamic> data, bool isCancelled) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        gradient: isCancelled
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2A1A1A), Color(0xFF1A0F0F)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2A2308), Color(0xFF1A1605), Color(0xFF0F0D03)],
              ),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PERINGKAT AKHIR',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isCancelled ? AppColors.error : AppColors.primary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isCancelled ? 'DIBATALKAN' : data['peringkat_akhir'],
                  style: GoogleFonts.poppins(
                    fontSize: isCancelled ? 28 : 40,
                    fontWeight: FontWeight.w900,
                    color: isCancelled ? AppColors.error.withOpacity(0.8) : AppColors.primary,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isCancelled ? AppColors.error.withOpacity(0.15) : AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isCancelled ? Icons.cancel_outlined : Icons.keyboard_double_arrow_up_rounded,
              color: isCancelled ? AppColors.error.withOpacity(0.6) : AppColors.primary,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET: STATS ROW (Total Poin & Total Kills)
  Widget _buildStatsRow(Map<String, dynamic> data) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
              border: Border.all(color: AppColors.inputBorder.withOpacity(0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL POIN',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${data['total_poin']}',
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PTS',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppConstants.paddingM),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
              border: Border.all(color: AppColors.inputBorder.withOpacity(0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL KILLS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${data['total_kills']}',
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'KILL',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // WIDGET: TOMBOL AJUKAN KLAIM
  Widget _buildClaimButton(BuildContext context, Map<String, dynamic> data) {
    return SizedBox(
      width: double.infinity,
      height: AppConstants.buttonHeight,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RequestClaimPrizePage(
                title: data['nama_scrim'],
                rank: data['peringkat_akhir'],
                totalPrize: 'Rp 150.000', // Sesuai prize pool database lu nanti bray
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.buttonText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Ajukan Klaim',
              style: AppTextStyles.poppinsButton.copyWith(fontSize: 16),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    );
  }

  // WIDGET: TOMBOL LIHAT LEADERBOARD
  Widget _buildLeaderboardButton(BuildContext context, Map<String, dynamic> data) {
    return SizedBox(
      width: double.infinity,
      height: AppConstants.buttonHeight,
      child: OutlinedButton(
        onPressed: () {
          context.push('/user/leaderboard/${data['id_sesi']}');
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.inputBorder, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart_rounded, color: AppColors.textPrimary, size: 22),
            const SizedBox(width: 10),
            Text(
              'Lihat Leaderboard',
              style: AppTextStyles.poppinsButton.copyWith(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET: INFO DIBATALKAN
  Widget _buildCancelledInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1A1A),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.error, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Scrim ini telah dibatalkan. Tidak ada data hasil yang tersedia.',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}