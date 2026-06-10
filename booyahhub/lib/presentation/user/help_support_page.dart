import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoadingOwnerContact = true;
  String _ownerPhone = '-';

  @override
  void initState() {
    super.initState();
    _fetchOwnerContact();
  }

  Future<void> _fetchOwnerContact() async {
    try {
      final data = await _supabase
          .from('profil_owner')
          .select('no_handphone')
          .order('id_profil_owner', ascending: true)
          .limit(1)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _ownerPhone = data?['no_handphone']?.toString() ?? '-';
        _isLoadingOwnerContact = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _ownerPhone = '-';
        _isLoadingOwnerContact = false;
      });

      debugPrint('Gagal mengambil kontak owner: $e');
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
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.primary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'BANTUAN & DUKUNGAN',
          style: AppTextStyles.poppinsTitle.copyWith(
            color: AppColors.primary,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _fetchOwnerContact,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),

              const SizedBox(height: 28),

              _buildSectionTitle('Pertanyaan Umum'),
              const SizedBox(height: 16),

              _buildFaqItem(
                'Apa itu BooyahHub?',
                'BooyahHub adalah aplikasi untuk membantu pemain game online, khususnya Free Fire, dalam mencari, mendaftar, dan mengikuti scrim secara lebih mudah. Melalui aplikasi ini, user bisa melihat jadwal scrim, melakukan booking slot, upload bukti pembayaran, melihat leaderboard, riwayat pertandingan, sampai mengajukan klaim hadiah.',
              ),

              _buildFaqItem(
                'Bagaimana cara mendaftar scrim?',
                'Buka menu Scrim, pilih event yang tersedia, lalu pilih sesi atau jam pertandingan yang masih memiliki slot kosong. Setelah itu isi data tim, data kapten, ID player, pilih metode pembayaran, lalu lanjutkan ke halaman pembayaran.',
              ),

              _buildFaqItem(
                'Bagaimana cara pembayaran pendaftaran?',
                'Setelah melakukan booking scrim, user akan diarahkan ke halaman pembayaran. Pilih metode pembayaran yang tersedia dari penyelenggara, seperti bank transfer, e-wallet, atau QRIS jika admin menyediakannya. Setelah membayar, upload bukti pembayaran agar admin bisa melakukan verifikasi.',
              ),

              _buildFaqItem(
                'Kenapa status pembayaran saya masih menunggu?',
                'Status pembayaran akan tetap menunggu sampai admin penyelenggara memeriksa dan memverifikasi bukti pembayaran kamu. Jika bukti pembayaran valid, status akan berubah menjadi dikonfirmasi. Jika bukti tidak sesuai, admin dapat menolak pembayaran.',
              ),

              _buildFaqItem(
                'Kapan Room ID dan password dibagikan?',
                'Room ID dan password akan dibagikan oleh admin sebelum pertandingan dimulai. Jika Room ID sudah tersedia, kamu bisa melihatnya melalui detail scrim, riwayat pertandingan, atau notifikasi yang dikirim oleh sistem.',
              ),

              _buildFaqItem(
                'Bagaimana sistem leaderboard bekerja?',
                'Leaderboard menampilkan hasil pertandingan berdasarkan data yang diinput oleh admin, seperti placement, jumlah kill, dan total poin. Setelah pertandingan selesai, user dapat melihat posisi tim dan performa pertandingan melalui halaman leaderboard atau riwayat scrim.',
              ),

              _buildFaqItem(
                'Bagaimana cara klaim hadiah?',
                'Jika tim kamu masuk posisi juara sesuai ketentuan hadiah, buka menu Riwayat Scrim atau Klaim Hadiah. Pilih scrim yang dimenangkan, lalu ajukan klaim dengan mengisi data pencairan seperti rekening bank atau QRIS. Setelah diajukan, admin akan memproses klaim tersebut.',
              ),

              _buildFaqItem(
                'Kenapa nominal hadiah saya berbeda dari total hadiah scrim?',
                'Total hadiah scrim adalah jumlah hadiah keseluruhan dalam satu event atau sesi. Nominal hadiah yang diterima user akan dihitung berdasarkan peringkat. Contohnya, Juara 1 mendapatkan bagian hadiah lebih besar dibanding Juara 2 dan Juara 3.',
              ),

              _buildFaqItem(
                'Apa arti status klaim hadiah?',
                'Status belum diajukan berarti hadiah belum diklaim. Status diajukan berarti klaim sudah dikirim ke admin. Status disetujui admin berarti klaim sudah diterima dan menunggu pembayaran. Status dibayar berarti hadiah sudah dibayarkan oleh admin.',
              ),

              _buildFaqItem(
                'Bagaimana jika bukti pembayaran hadiah belum muncul?',
                'Bukti pembayaran hadiah hanya akan muncul jika admin sudah mengupload bukti transfer dan menandai klaim sebagai dibayar. Jika status sudah dibayar tetapi bukti belum muncul, coba refresh halaman atau hubungi dukungan BooyahHub.',
              ),

              _buildFaqItem(
                'Apakah saya bisa membatalkan booking scrim?',
                'Untuk saat ini, pembatalan booking mengikuti kebijakan masing-masing penyelenggara scrim. Jika kamu sudah melakukan pembayaran, hubungi admin penyelenggara melalui kontak yang tersedia untuk menanyakan proses pembatalan atau pengembalian dana.',
              ),

              _buildFaqItem(
                'Bagaimana jika saya salah mengisi data tim?',
                'Jika data tim, ID player, atau nomor WhatsApp salah, segera hubungi admin penyelenggara sebelum pertandingan dimulai. Data yang salah dapat menyebabkan kesalahan dalam verifikasi peserta, pembagian Room ID, atau pencatatan hasil pertandingan.',
              ),

              _buildFaqItem(
                'Apakah BooyahHub hanya untuk Free Fire?',
                'BooyahHub dibuat dengan fokus utama pada scrim Free Fire. Namun konsep aplikasi ini tetap dapat dikembangkan untuk mendukung game online lain yang memiliki sistem scrim, turnamen, atau pertandingan kompetitif.',
              ),

              _buildFaqItem(
                'Bagaimana jika aplikasi mengalami error?',
                'Jika aplikasi mengalami error, coba tutup dan buka kembali aplikasi, pastikan koneksi internet stabil, lalu refresh halaman. Jika error masih terjadi, simpan screenshot error dan hubungi dukungan BooyahHub agar masalah bisa diperiksa lebih lanjut.',
              ),

              const SizedBox(height: 28),

              _buildSectionTitle('Panduan Singkat Pengguna'),
              const SizedBox(height: 16),

              _buildGuideCard(
                icon: Icons.search_rounded,
                title: '1. Cari Scrim',
                description:
                    'Masuk ke menu Scrim untuk melihat daftar scrim yang tersedia, jadwal pertandingan, biaya pendaftaran, kuota peserta, dan detail event.',
              ),

              _buildGuideCard(
                icon: Icons.event_available_rounded,
                title: '2. Pilih Sesi',
                description:
                    'Pilih sesi atau jam pertandingan yang masih tersedia. Pastikan jadwal tidak bentrok dan slot belum penuh.',
              ),

              _buildGuideCard(
                icon: Icons.group_add_rounded,
                title: '3. Daftarkan Tim',
                description:
                    'Isi data tim, nama kapten, nomor WhatsApp, dan ID player dengan benar agar admin mudah melakukan verifikasi.',
              ),

              _buildGuideCard(
                icon: Icons.payment_rounded,
                title: '4. Upload Bukti Pembayaran',
                description:
                    'Lakukan pembayaran sesuai metode yang disediakan admin, lalu upload bukti pembayaran melalui halaman checkout.',
              ),

              _buildGuideCard(
                icon: Icons.emoji_events_rounded,
                title: '5. Cek Hasil dan Klaim Hadiah',
                description:
                    'Setelah pertandingan selesai, cek leaderboard dan riwayat scrim. Jika tim kamu menang, ajukan klaim hadiah melalui halaman Klaim Hadiah.',
              ),

              const SizedBox(height: 28),

              _buildSectionTitle('Kebijakan & Syarat Ketentuan'),
              const SizedBox(height: 16),

              _buildTermsCard(),

              const SizedBox(height: 28),

              _buildSectionTitle('Hubungi Dukungan'),
              const SizedBox(height: 16),

              _buildContactCard(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Butuh bantuan?',
                  style: AppTextStyles.poppinsTitleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Temukan panduan penggunaan BooyahHub, mulai dari daftar scrim, pembayaran, leaderboard, sampai klaim hadiah.',
                  style: AppTextStyles.interCaption.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.poppinsTitleSmall.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: AppTextStyles.interBody.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: AppTextStyles.interCaption.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.interBody.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: AppTextStyles.interCaption.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Text(
        '1. Ketentuan Pengguna\n'
        'Pengguna wajib mengisi data tim, data kapten, ID player, dan kontak WhatsApp dengan benar. Kesalahan data dapat memengaruhi proses verifikasi, pembagian Room ID, dan pencatatan hasil pertandingan.\n\n'
        '2. Pembayaran dan Verifikasi\n'
        'Setiap booking scrim yang berbayar wajib disertai bukti pembayaran. Admin penyelenggara berhak menyetujui atau menolak pembayaran berdasarkan kesesuaian bukti yang dikirimkan.\n\n'
        '3. Pertandingan dan Hasil\n'
        'Hasil pertandingan, placement, kill, dan total poin akan dicatat oleh admin. Leaderboard akan mengikuti data yang sudah diverifikasi oleh penyelenggara scrim.\n\n'
        '4. Klaim Hadiah\n'
        'Hadiah hanya dapat diklaim oleh peserta yang memenuhi syarat sebagai pemenang. Proses pencairan hadiah dilakukan setelah user mengajukan klaim dan admin memverifikasi data pencairan.\n\n'
        '5. Pelanggaran\n'
        'Peserta yang melakukan kecurangan, memberikan data palsu, atau melanggar aturan scrim dapat ditolak pendaftarannya, dibatalkan hasilnya, atau tidak memperoleh hadiah sesuai keputusan penyelenggara.\n\n'
        '6. Tanggung Jawab Penyelenggara\n'
        'Admin penyelenggara bertanggung jawab terhadap jadwal scrim, verifikasi pembayaran, pembagian Room ID, input hasil pertandingan, serta pembayaran hadiah kepada pemenang.',
        style: AppTextStyles.interCaption.copyWith(
          color: AppColors.textSecondary,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _buildContactRow(
            icon: Icons.email_outlined,
            text: 'support@booyahhub.com',
          ),
          const SizedBox(height: 16),
          _buildContactRow(
            icon: Icons.phone_outlined,
            text: _isLoadingOwnerContact
                ? 'Memuat nomor dukungan...'
                : _ownerPhone,
          ),
          const SizedBox(height: 16),
          _buildContactRow(
            icon: Icons.access_time_rounded,
            text: 'Dukungan aktif setiap hari pukul 09.00 - 21.00 WIB',
          ),
          const SizedBox(height: 16),
          _buildContactRow(
            icon: Icons.info_outline_rounded,
            text:
                'Saat menghubungi dukungan, sertakan nama tim, nama scrim, sesi pertandingan, dan screenshot kendala agar proses pengecekan lebih cepat.',
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 22,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.interBody.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}