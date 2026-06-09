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
  List<Map<String, dynamic>> _prizeList = [];

  @override
  void initState() {
    super.initState();
    _fetchPrizes();
  }

  Future<void> _fetchPrizes() async {
    try {
      final supabase = Supabase.instance.client;
      // Ambil user yang login dari Supabase Auth
      final authUser = supabase.auth.currentUser;
      if (authUser == null) {
        throw 'User belum login';
      }

      // 1. Ambil id_akun dari tabel akun berdasarkan email auth user
      final akunResponse = await supabase
          .from('akun')
          .select('id_akun')
          .eq('email', authUser.email!)
          .maybeSingle();

      if (akunResponse == null) {
        throw 'Akun tidak ditemukan';
      }
      final int akunId = akunResponse['id_akun'];

      // 2. Fetch pendaftaran yang sudah selesai
      var query = supabase
          .from('pendaftaran_tim')
          .select('''
            id_pendaftaran,
            status_pertandingan,
            sesi_scrim (
              id_sesi,
              scrim (
                id_scrim,
                nama_scrim,
                total_hadiah
              )
            ),
            hasil_pertandingan (*),
            klaim_hadiah (*)
          ''')
          .eq('akun_id', akunId)
          .eq('status_pertandingan', 'selesai');
          
      // Jika masuk dari detail spesifik, filter
      if (widget.pendaftaranId != null) {
        query = query.eq('id_pendaftaran', widget.pendaftaranId!);
      }

      final response = await query;
      debugPrint("KLAIM PAGE - Response length: ${response.length}");
      debugPrint("KLAIM PAGE - Response data: $response");
      
      final List<Map<String, dynamic>> loadedPrizes = [];
      for (var item in response) {
        debugPrint("KLAIM PAGE - Processing item: $item");
        final scrimData = item['sesi_scrim']?['scrim'];
        if (scrimData == null) {
          debugPrint("KLAIM PAGE - scrimData is null! Skipping...");
          continue;
        }
        
        final List<dynamic> hasilList = item['hasil_pertandingan'] ?? [];
        final List<dynamic> klaimList = item['klaim_hadiah'] ?? [];
        
        debugPrint("KLAIM PAGE - hasilList: $hasilList");
        debugPrint("KLAIM PAGE - klaimList: $klaimList");

        // Ambil status klaim jika ada
        String statusKlaim = 'belum_diklaim';
        if (klaimList.isNotEmpty) {
           statusKlaim = klaimList[0]['status_klaim'] ?? 'diproses';
        }

        // Ambil rank
        int rank = 0;
        if (hasilList.isNotEmpty) {
           rank = hasilList[0]['peringkat'] ?? 0;
        }

        loadedPrizes.add({
          'id_pendaftaran': item['id_pendaftaran'],
          'nama_scrim': scrimData['nama_scrim'] ?? 'Unnamed Scrim',
          'total_hadiah': scrimData['total_hadiah'] ?? 0,
          'rank': rank,
          'status_klaim': statusKlaim,
        });
      }

      debugPrint("KLAIM PAGE - loadedPrizes length: ${loadedPrizes.length}");

      setState(() {
        _prizeList = loadedPrizes;
        _isLoading = false;
      });
    } catch (e, stacktrace) {
      debugPrint("Error fetching prizes: $e");
      debugPrint(stacktrace.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('DEBUG ERROR: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() {
        _isLoading = false;
      });
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
          style: AppTextStyles.poppinsTitle.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: false,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
        child: Padding(
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
                'Kelola semua hadiah dari turnamen dan scrim yang telah kamu menangkan di arena',
                style: AppTextStyles.interBody,
              ),
              const SizedBox(height: 32),
              
              if (_prizeList.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(
                      'Belum ada hadiah yang bisa diklaim.',
                      style: AppTextStyles.interBody.copyWith(color: AppColors.textHint),
                    ),
                  ),
                )
              else
                ..._prizeList.map((prizeData) => _buildDynamicPrizeCard(context, prizeData)).toList(),
                
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicPrizeCard(BuildContext context, Map<String, dynamic> data) {
    String statusKlaim = data['status_klaim'];
    
    // Status attributes
    String statusText = '';
    Color statusColor = Colors.white;
    String badgeText = '';
    Color badgeColor = Colors.transparent;
    Color badgeTextColor = Colors.white;
    Widget? actionWidget;

    if (statusKlaim == 'belum_diklaim') {
      statusText = 'PERLU TINDAKAN';
      statusColor = AppColors.urgent;
      badgeText = 'Belum Diklaim';
      badgeColor = AppColors.urgent.withOpacity(0.2);
      badgeTextColor = const Color(0xFFF44336);
      
      actionWidget = Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 24),
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => RequestClaimPrizePage(
                  title: data['nama_scrim'],
                  rank: data['rank'] > 0 ? 'Juara ${data['rank']}' : 'Rank -',
                  totalPrize: 'Rp ${data['total_hadiah']}',
                  pendaftaranId: data['id_pendaftaran'],
                ),
              ),
            ).then((_) {
              // Refresh data after back
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
              const Icon(Icons.chevron_right, color: AppColors.black, size: 20),
            ],
          ),
        ),
      );
    } else if (statusKlaim == 'selesai' || statusKlaim == 'sukses') {
      statusText = 'TRANSAKSI SELESAI';
      statusColor = AppColors.textHint;
      badgeText = 'Selesai';
      badgeColor = AppColors.surfaceVariant;
      badgeTextColor = AppColors.textSecondary;
    } else {
      // Menangani 'diajukan', 'diproses', 'pending', dll
      statusText = 'TRANSAKSI SEDANG BERLANGSUNG';
      statusColor = AppColors.textHint;
      badgeText = 'Diproses';
      badgeColor = AppColors.warning.withOpacity(0.15);
      badgeTextColor = AppColors.warning;
      
      actionWidget = Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Center(
          child: Text(
            'Estimasi transfer 1 - 2 hari kerja',
            style: AppTextStyles.interCaption,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: _buildPrizeCard(
        context,
        statusText: statusText,
        statusColor: statusColor,
        title: data['nama_scrim'],
        badgeText: badgeText,
        badgeColor: badgeColor,
        badgeTextColor: badgeTextColor,
        rank: data['rank'] > 0 ? 'Juara ${data['rank']}' : 'Rank -',
        prize: 'Rp ${data['total_hadiah']}',
        actionWidget: actionWidget,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      const Icon(Icons.star, color: AppColors.primary, size: 14),
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

