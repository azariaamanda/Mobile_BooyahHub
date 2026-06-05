import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';
import 'request_claim_prize_page.dart';

class ClaimPrizePage extends StatefulWidget {
  final int? pendaftaranId;
  const ClaimPrizePage({super.key, this.pendaftaranId});

  @override
  State<ClaimPrizePage> createState() => _ClaimPrizePageState();
}

class _ClaimPrizePageState extends State<ClaimPrizePage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _prizes = [];

  @override
  void initState() {
    super.initState();
    _fetchPrizes();
  }

  Future<void> _fetchPrizes() async {
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final akunResponse = await supabase
          .from('akun')
          .select('id_akun')
          .eq('email', currentUser.email!)
          .maybeSingle();

      if (akunResponse == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      final int akunId = akunResponse['id_akun'];

      final response = await supabase
          .from('pendaftaran_tim')
          .select('''
            id_pendaftaran,
            dibuat_pada,
            sesi_scrim!inner (
              scrim!inner (
                nama_scrim,
                total_hadiah
              )
            ),
            hasil_pertandingan (
              peringkat
            ),
            klaim_hadiah (
              id_klaim,
              status_klaim,
              jumlah_klaim
            )
          ''')
          .eq('akun_id', akunId)
          .order('dibuat_pada', ascending: false);

      List<Map<String, dynamic>> validPrizes = [];
      for (var item in response) {
        final hasilList = item['hasil_pertandingan'] as List?;
        if (hasilList != null && hasilList.isNotEmpty) {
          final int peringkat = hasilList[0]['peringkat'] ?? 99;
          if (peringkat <= 3) {
            validPrizes.add(item);
          }
        }
      }

      setState(() {
        _prizes = validPrizes;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _isLoading = false);
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
          'Klaim Hadiah',
          style: AppTextStyles.poppinsTitle.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPrizes,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Memastikan bisa di-pull walau item sedikit
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Penghargaan Kamu',
                  style: AppTextStyles.poppinsHeadline.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kelola semua hadiah dari turnamen dan scrim yang telah kamu menangkan di arena',
                  style: AppTextStyles.interBody,
                ),
                const SizedBox(height: 32),
                _buildContent(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    
    if (_prizes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Icon(Icons.emoji_events_outlined, size: 64, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text('Belum Ada Hadiah', style: AppTextStyles.poppinsTitleSmall),
            const SizedBox(height: 8),
            Text(
              'Menangkan turnamen untuk mendapatkan hadiah',
              style: AppTextStyles.interBody,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: _prizes.map((prizeData) {
        final sesi = prizeData['sesi_scrim'] as Map<String, dynamic>;
        final scrim = sesi['scrim'] as Map<String, dynamic>;
        final hasilList = prizeData['hasil_pertandingan'] as List;
        final rank = hasilList[0]['peringkat'];
        
        final klaimList = prizeData['klaim_hadiah'] as List?;
        final hasKlaim = klaimList != null && klaimList.isNotEmpty;
        final statusKlaim = hasKlaim ? klaimList[0]['status_klaim'] : 'belum_diajukan';

        String title = scrim['nama_scrim'] ?? 'No Title';
        // Format rupiah sederhana
        double nominal = double.tryParse(scrim['total_hadiah']?.toString() ?? '0') ?? 0;
        String formattedPrize = 'Rp ${nominal.toInt().toString().replaceAllMapped(RegExp(r'\\B(?=(\\d{3})+(?!\\d))'), (match) => '.')}';
        
        String rankStr = 'Juara $rank';

        if (!hasKlaim || statusKlaim == 'belum_diajukan' || statusKlaim == 'ditolak') {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildPrizeCard(
              context,
              statusText: 'PERLU TINDAKAN',
              statusColor: AppColors.urgent,
              title: title,
              badgeText: statusKlaim == 'ditolak' ? 'Ditolak' : 'Belum Diklaim',
              badgeColor: AppColors.urgent.withOpacity(0.2),
              badgeTextColor: const Color(0xFFF44336), // error / bright red
              rank: rankStr,
              prize: formattedPrize,
              actionWidget: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 24),
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to RequestClaimPrizePage
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RequestClaimPrizePage(
                          title: title,
                          rank: rankStr,
                          totalPrize: formattedPrize,
                          pendaftaranId: prizeData['id_pendaftaran'], // Luluskan ID
                        ),
                      ),
                    ).then((_) {
                      // Refresh setelah kembali
                      _fetchPrizes();
                    });
                  },
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
              ),
            ),
          );
        } else if (statusKlaim == 'dibayar') {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildPrizeCard(
              context,
              statusText: 'TRANSAKSI SELESAI',
              statusColor: AppColors.textHint,
              title: title,
              badgeText: 'Selesai',
              badgeColor: AppColors.surfaceVariant,
              badgeTextColor: AppColors.textSecondary,
              rank: rankStr,
              prize: formattedPrize,
            ),
          );
        } else {
          // Status lain (diajukan, disetujui_admin, diteruskan_owner)
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildPrizeCard(
              context,
              statusText: 'TRANSAKSI SEDANG BERLANGSUNG',
              statusColor: AppColors.textHint,
              title: title,
              badgeText: 'Diproses',
              badgeColor: AppColors.warning.withOpacity(0.15),
              badgeTextColor: AppColors.warning,
              rank: rankStr,
              prize: formattedPrize,
              actionWidget: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Center(
                  child: Text(
                    'Estimasi transfer 1 - 2 hari kerja',
                    style: AppTextStyles.interCaption,
                  ),
                ),
              ),
            ),
          );
        }
      }).toList(),
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
    Widget? actionWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
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
                      style: AppTextStyles.poppinsTitleSmall.copyWith(
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
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
                    fontWeight: FontWeight.w600,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppColors.primary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text('Rank', style: AppTextStyles.interCaption),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rank,
                    style: AppTextStyles.poppinsTitleSmall.copyWith(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Total Hadiah', style: AppTextStyles.interCaption),
                  const SizedBox(height: 4),
                  Text(
                    prize,
                    style: AppTextStyles.poppinsMoneySmall.copyWith(
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (actionWidget != null) actionWidget,
        ],
      ),
    );
  }
}
