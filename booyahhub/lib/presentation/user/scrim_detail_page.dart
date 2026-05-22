import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_image_helper.dart';
import '../../config/app_text_styles.dart';
import '../../config/supabase_client.dart';

class ScrimDetailPage extends StatefulWidget {
  final int scrimId;

  const ScrimDetailPage({super.key, required this.scrimId});

  @override
  State<ScrimDetailPage> createState() => _ScrimDetailPageState();
}

class _ScrimDetailPageState extends State<ScrimDetailPage> {
  Map<String, dynamic>? _scrimData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScrimData();
  }

  // Hanya mengambil data utama dari tabel scrim
  Future<void> _loadScrimData() async {
    try {
      final response = await SupabaseClientHelper.client
          .from('scrim')
          .select()
          .eq('id_scrim', widget.scrimId)
          .single();

      setState(() {
        _scrimData = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat detail scrim: $e')),
      );
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

    if (_scrimData == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent, iconTheme: const IconThemeData(color: Colors.white)),
        body: Center(child: Text('Data scrim tidak ditemukan.', style: AppTextStyles.interBody)),
      );
    }

    // Ambil data nominal dari database
    final double biaya = double.tryParse(_scrimData!['biaya_pendaftaran'].toString()) ?? 0;
    final double hadiah = double.tryParse(_scrimData!['total_hadiah'].toString()) ?? 0;
    final int maksPeserta = _scrimData!['maks_peserta'] ?? 12;
    final String posterUrl = AppImageHelper.posterByIdScrim(widget.scrimId);

    // Format teks untuk box info emas sesuai mockup
    final String txtBiaya = biaya == 0 ? 'Free' : '${(biaya / 1000).toStringAsFixed(0)}k/tim';
    final String txtHadiah = '${(hadiah / 1000).toStringAsFixed(0)}k';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Detail Scrim', style: AppTextStyles.poppinsSectionTitle.copyWith(color: Colors.white)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= 1. POSTER BESAR (Sudah Include List Sesi di Dalam Gambarnya) =================
              Container(
                width: double.infinity,
                height: 386, // Kita set tinggi mendekati aspek rasio mockup lu (350x386)
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  image: DecorationImage(
                    image: NetworkImage(posterUrl),
                    fit: BoxFit.contain, // Memastikan seluruh isi gambar poster tidak terpotong
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingM),

              // ================= 2. JUDUL SCRIM =================
              Text(
                _scrimData!['nama_scrim'] ?? 'Scrim By Kelompok 2',
                style: AppTextStyles.poppinsTitle.copyWith(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppConstants.paddingM),

              // ================= 3. 4 KOTAK INFO EMAS (KAPASITAS, SLOT, BIAYA, HADIAH) =================
              Row(
                children: [
                  _buildGoldInfoCard('Kapasitas', '$maksPeserta Tim'),
                  const SizedBox(width: 8),
                  _buildGoldInfoCard('Sisa Slot', '$maksPeserta Tim'),
                  const SizedBox(width: 8),
                  _buildGoldInfoCard('Biaya', txtBiaya),
                  const SizedBox(width: 8),
                  _buildGoldInfoCard('Hadiah', txtHadiah),
                ],
              ),
              const SizedBox(height: AppConstants.paddingL),

              // ================= 4. TEXT DESKRIPSI & ATURAN =================
              Text(
                'Deskripsi & Aturan', 
                style: AppTextStyles.poppinsSectionTitle.copyWith(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: AppConstants.paddingS),
              Text(
                'Scrim kompetitif untuk semua kalangan. Format Battle Royale, 4v4. Dilarang menggunakan cheat atau exploit. Admin berhak mendiskualifikasi tim yang melanggar aturan.',
                style: AppTextStyles.interBodyMedium.copyWith(
                  color: Colors.grey[400], 
                  height: 1.5,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 30),

              // ================= 5. TOMBOL BOOKING SEKARANG (SELALU AKTIF) =================
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, // Kuning emas melayang BooyahHub
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusL),
                    ),
                  ),
                  onPressed: () {
                    // Karena sesi langsung dipilih di form berikutnya, kita lempar id_scrim bawaan
                    // ke halaman bookingform sesuai alur go_router tim lu
                    context.pushNamed(
                      'booking',
                      pathParameters: {
                        'idSesi': widget.scrimId.toString(), 
                      },
                    );
                  },
                  child: Text(
                    'Booking Sekarang',
                    style: AppTextStyles.poppinsButton.copyWith(
                      color: AppColors.buttonText,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingL),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET UNTUK MEMBUAT KOTAK EMAS INDIVIDU
  Widget _buildGoldInfoCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingS),
        decoration: BoxDecoration(
          color: AppColors.primary, // Warna emas seragam
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label, 
              style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}