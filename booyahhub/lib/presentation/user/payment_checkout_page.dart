import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import 'package:image_picker/image_picker.dart';

class PaymentCheckoutPage extends StatefulWidget {
  final int pendaftaranId;

  const PaymentCheckoutPage({super.key, required this.pendaftaranId});

  @override
  State<PaymentCheckoutPage> createState() => _PaymentCheckoutPageState();
}

class _PaymentCheckoutPageState extends State<PaymentCheckoutPage> {
  late Future<Map<String, dynamic>> _allData;
  Uint8List? _buktiBytes;

  @override
  void initState() {
    super.initState();
    _allData = _fetchAllData();
  }

  Future<Map<String, dynamic>> _fetchAllData() async {
    final supabase = Supabase.instance.client;

    // 1. Ambil data pendaftaran + sesi + scrim
    final pendaftaran = await supabase
        .from('pendaftaran_tim')
        .select('''
          id_pendaftaran,
          nama_kapten,
          whatsapp_kapten,
          metode_pembayaran_daftar,
          sesi_scrim (
            id_sesi,
            nama_sesi,
            scrim (
              id_scrim,
              id_admin,
              nama_scrim,
              biaya_pendaftaran
            )
          )
        ''')
        .eq('id_pendaftaran', widget.pendaftaranId)
        .single();

    final sesiScrim = pendaftaran['sesi_scrim'] as Map<String, dynamic>?;
    final scrim = sesiScrim?['scrim'] as Map<String, dynamic>?;
    final int? adminId = scrim?['id_admin'];
    final String metodePembayaran = pendaftaran['metode_pembayaran_daftar'] ?? '';

    // 2. Ambil metode pembayaran penyelenggara yang sesuai
    Map<String, dynamic>? metodePenyelenggara;
    String? qrisSignedUrl;
    if (adminId != null) {
      final metodeList = await supabase
          .from('metode_pembayaran_penyelenggara')
          .select('*')
          .eq('akun_id', adminId)
          .eq('jenis_metode', metodePembayaran == 'bank_transfer' ? 'bank_transfer' : 'qris')
          .eq('is_active', true)
          .limit(1);

      if (metodeList.isNotEmpty) {
        metodePenyelenggara = metodeList[0];

        // Generate signed URL jika ada gambar QRIS
        final String? qrisPath = metodePenyelenggara['qris_image'] as String?;
        if (qrisPath != null && qrisPath.isNotEmpty) {
          try {
            qrisSignedUrl = await supabase.storage
                .from('qr_qris')
                .createSignedUrl(qrisPath, 3600);
            debugPrint('QRIS signed URL: $qrisSignedUrl');
          } catch (e) {
            debugPrint('Gagal generate signed URL QRIS: $e');
          }
        }
      }
    }

    return {
      'pendaftaran': pendaftaran,
      'metode_penyelenggara': metodePenyelenggara,
      'qris_signed_url': qrisSignedUrl,
    };
  }

  String _formatRupiah(dynamic nominal) {
    if (nominal == null) return 'Rp 0';
    int value;
    if (nominal is int) {
      value = nominal;
    } else if (nominal is double) {
      value = nominal.toInt();
    } else {
      value = double.parse(nominal.toString()).toInt();
    }
    return 'Rp ${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
  }

  String _getPaymentLabel(String? value) {
    switch (value) {
      case 'bank_transfer':
        return 'Transfer Bank';
      case 'qris':
        return 'QRIS Otomatis';
      default:
        return value ?? 'Belum Dipilih';
    }
  }

  Future<void> _kirimBuktiPembayaran() async {
    if (_buktiBytes == null) return;

    try {
      final supabase = Supabase.instance.client;
      final pendaftaranId = widget.pendaftaranId;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = 'user/bukti_${pendaftaranId}_$timestamp.jpg';

      await supabase.storage
          .from('bukti_bayar')
          .uploadBinary(filePath, _buktiBytes!);

      await supabase
          .from('pendaftaran_tim')
          .update({
            'bukti_pembayaran': filePath,
            'status_pembayaran': 'menunggu',
          })
          .eq('id_pendaftaran', pendaftaranId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bukti transfer berhasil dikirim! Menunggu verifikasi admin.'),
          backgroundColor: AppColors.success,
        ),
      );

      context.go('/user/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal upload bukti pembayaran: $e'),
          backgroundColor: AppColors.error,
        ),
      );
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
        title: const Text(
          'Pembayaran Scrim',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _allData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal Memuat Halaman Pembayaran:\n${snapshot.error}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('Data pendaftaran kosong.', style: TextStyle(color: Colors.white)),
            );
          }

          final pendaftaran = snapshot.data!['pendaftaran'] as Map<String, dynamic>;
          final metodePenyelenggara = snapshot.data!['metode_penyelenggara'] as Map<String, dynamic>?;
          final String? qrisSignedUrl = snapshot.data!['qris_signed_url'] as String?;

          final sesiScrim = pendaftaran['sesi_scrim'] as Map<String, dynamic>?;
          final scrim = sesiScrim?['scrim'] as Map<String, dynamic>?;

          final String namaScrim = scrim?['nama_scrim'] ?? 'Scrim';
          final String namaSesi = sesiScrim?['nama_sesi'] != null ? ' (${sesiScrim?['nama_sesi']})' : '';
          final dynamic biaya = scrim?['biaya_pendaftaran'];
          final String metodePembayaran = pendaftaran['metode_pembayaran_daftar'] ?? '';
          final bool isQris = metodePembayaran == 'qris';

          // Data dari metode penyelenggara
          final String namaBank = metodePenyelenggara?['nama_bank'] ?? '';
          final String namaPemilik = metodePenyelenggara?['nama_pemilik'] ?? '-';
          final String nomorRekening = metodePenyelenggara?['nomor_rekening'] ?? '-';
          final String? qrisImageUrl = qrisSignedUrl;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // ─── KARTU 1: RINGKASAN BOOKING ──────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ringkasan Booking',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildRowDetail('Scrim', '$namaScrim$namaSesi'),
                        _buildRowDetail('ID Daftar', '#${pendaftaran['id_pendaftaran']}'),
                        _buildRowDetail('Kapten', '${pendaftaran['nama_kapten']}'),
                        _buildRowDetail('WhatsApp', '${pendaftaran['whatsapp_kapten']}'),
                        _buildRowDetail('Metode', _getPaymentLabel(metodePembayaran)),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Divider(color: AppColors.divider, thickness: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            ),
                            Text(
                              _formatRupiah(biaya),
                              style: const TextStyle(
                                color: AppColors.textGold,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── KARTU 2: INFO TRANSFER / QRIS (DARI DATABASE) ─────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isQris ? 'Scan QRIS' : 'Info Transfer Bank',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (metodePenyelenggara == null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Data metode pembayaran penyelenggara tidak ditemukan',
                                    style: TextStyle(color: Colors.orange, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (isQris) ...[
                          // ── QRIS: Tampilkan nama pemilik + gambar QR ──
                          if (namaPemilik != '-' && namaPemilik.isNotEmpty)
                            Text(
                              'QRIS $namaPemilik',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else
                            const Text(
                              'QRIS All Payment',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                if (qrisImageUrl != null && qrisImageUrl.isNotEmpty)
                                  Image.network(
                                    qrisImageUrl,
                                    height: 200,
                                    fit: BoxFit.contain,
                                    loadingBuilder: (context, child, progress) =>
                                        progress == null ? child : const CircularProgressIndicator(color: AppColors.primary),
                                    errorBuilder: (context, error, stack) =>
                                        const Icon(Icons.qr_code_2, size: 150, color: Colors.black),
                                  )
                                else
                                  const Icon(Icons.qr_code_2, size: 150, color: Colors.black),
                                const SizedBox(height: 8),
                                const Text(
                                  'Silahkan Scan QRIS Di Atas',
                                  style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // ── BANK TRANSFER: Tampilkan nama bank + rekening ──
                          Text(
                            namaBank.isNotEmpty ? 'Bank $namaBank' : 'Transfer Bank',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'A/N $namaPemilik',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundInput,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    nomorRekening,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 36,
                                  width: 80,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: nomorRekening));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Nomor rekening disalin!'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.buttonPrimary,
                                      foregroundColor: AppColors.buttonText,
                                      elevation: 0,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Salin',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── KARTU 3: UNGGAH BUKTI TRANSFER ───────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.buttonPrimary.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: InkWell(
                      onTap: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          final bytes = await image.readAsBytes();
                          setState(() {
                            _buktiBytes = bytes;
                          });
                        }
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.buttonPrimary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.file_upload_outlined,
                              color: AppColors.buttonText,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Ketuk untuk Unggah Bukti Transfer',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_buktiBytes != null) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _buktiBytes!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '✓ Foto terpilih',
                              style: TextStyle(color: AppColors.success, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ─── TOMBOL UTAMA: KIRIM ──────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_buktiBytes == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Silakan unggah bukti transfer terlebih dahulu.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        await _kirimBuktiPembayaran();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonPrimary,
                        foregroundColor: AppColors.buttonText,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Kirim Bukti Pembayaran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRowDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}