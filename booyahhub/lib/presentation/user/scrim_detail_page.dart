import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Tambahkan import Supabase
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
  final _supabase = Supabase.instance.client; // Inisialisasi client untuk storage

  @override
  void initState() {
    super.initState();
    _loadScrimData();
  }

  // Menggunakan query awal lu yang super aman dan lancar
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

  // LOGIKA PENGAMBILAN GAMBAR DINAMIS (Sama seperti halaman home & admin detail)
  String _getPosterUrl(String? path, int idScrim) {
    if (path == null || path.isEmpty) {
      return AppImageHelper.posterByIdScrim(idScrim);
    }
    if (path.startsWith('http')) return path;

    // Menangani struktur bucket posters -> folder posters -> file gambar
    final fullPath = path.startsWith('posters/') ? path : 'posters/$path';
    return _supabase.storage.from('posters').getPublicUrl(fullPath);
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

    // Ambil data nominal dari database sesuai kode awal lu
    final double biaya = double.tryParse(_scrimData!['biaya_pendaftaran'].toString()) ?? 0;
    final double hadiah = double.tryParse(_scrimData!['total_hadiah'].toString()) ?? 0;
    final int maksPeserta = _scrimData!['maks_peserta'] ?? 12;
    
    // SEKARANG MENGGUNAKAN LOGIKA URL DINAMIS BARU
    final String posterUrl = _getPosterUrl(_scrimData!['poster'] as String?, widget.scrimId);

    // Ambil string syarat_ketentuan dari database
    final String syaratText = _scrimData!['syarat_ketentuan'] ?? 'Tidak ada syarat khusus.';

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
              // ================= 1. POSTER BESAR =================
              Container(
                width: double.infinity,
                height: 386, 
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  image: DecorationImage(
                    image: NetworkImage(posterUrl),
                    fit: BoxFit.contain, 
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

              // ================= 3. 4 KOTAK INFO EMAS =================
              Row(
                children: [
                  _buildGoldInfoCard('Kapasitas', '$maksPeserta Tim'),
                  const SizedBox(width: 8),
                  _buildGoldInfoCard('Sisa Slot', '$maksPeserta Tim'), // Kembali ke format awal lu yang aman
                  const SizedBox(width: 8),
                  _buildGoldInfoCard('Biaya', txtBiaya),
                  const SizedBox(width: 8),
                  _buildGoldInfoCard('Hadiah', txtHadiah),
                ],
              ),
              const SizedBox(height: AppConstants.paddingL),

              // ================= 4. TEXT SYARAT & KETENTUAN (MURNI TANPA DESKRIPSI) =================
              Text(
                'Syarat & Ketentuan', 
                style: AppTextStyles.poppinsSectionTitle.copyWith(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: AppConstants.paddingS),
              Text(
                syaratText,
                style: AppTextStyles.interBodyMedium.copyWith(
                  color: Colors.grey[400], 
                  height: 1.5,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 40),

              // ================= 5. TOMBOL BOOKING SEKARANG =================
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusL),
                    ),
                  ),
                  onPressed: () {
                    // Disesuaikan persis dengan GoRoute yang udah lu bikin
                    context.pushNamed(
                      'booking_scrim', // <--- Sesuai dengan name di GoRoute lu
                      pathParameters: {
                        'idScrim': widget.scrimId.toString(), // <--- Sesuai dengan :idScrim di path lu
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
              const SizedBox(height: AppConstants.paddingM),
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
          color: AppColors.primary, 
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