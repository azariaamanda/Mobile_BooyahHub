  import 'package:flutter/material.dart';
  import 'package:go_router/go_router.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';
  import '../../config/app_color.dart';
  import 'package:image_picker/image_picker.dart';
  import 'dart:io';

  class PaymentCheckoutPage extends StatefulWidget {
    final int pendaftaranId;

    const PaymentCheckoutPage({super.key, required this.pendaftaranId});

    @override
    State<PaymentCheckoutPage> createState() => _PaymentCheckoutPageState();
  }

  class _PaymentCheckoutPageState extends State<PaymentCheckoutPage> {
    late Future<Map<String, dynamic>> _pendaftaranData;
    File? _buktiFile;

    @override
    void initState() {
      super.initState();
      _pendaftaranData = _fetchDataPendaftaran();
    }

    Future<Map<String, dynamic>> _fetchDataPendaftaran() async {
      try {
        print('Mencari id_pendaftaran: ${widget.pendaftaranId}');

        final data = await Supabase.instance.client
            .from('pendaftaran_tim')
            .select('''
              id_pendaftaran, 
              nama_kapten, 
              whatsapp_kapten,
              metode_pembayaran_daftar,
              sesi_scrim (
                nama_sesi,
                scrim (
                  nama_scrim,
                  biaya_pendaftaran
                )
              )
            ''')
            .eq('id_pendaftaran', widget.pendaftaranId)
            .single();
        
        print('Data berhasil didapat: $data');
        return data;
      } catch (e) {
        print('EROR DI SUPABASE PAYMENT: $e');
        throw Exception(e);
      }
    }

    // Helper pemformatan uang Rupiah
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

    // Helper untuk mengubah value enum DB jadi text rapi di UI Ringkasan
    String _getPaymentLabel(String? value) {
      switch (value) {
        case 'bank_transfer':
          return 'Transfer Bank (BCA)';
        case 'qris':
          return 'QRIS Otomatis';
        case 'ewallet':
          return 'E-Wallet (Dana/OVO)';
        default:
          return value ?? 'Belum Dipilih';
      }
    }

    Future<void> _kirimBuktiPembayaran() async {
      if (_buktiFile == null) return;

      try {
        final supabase = Supabase.instance.client;
        final pendaftaranId = widget.pendaftaranId;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'bukti_${pendaftaranId}_$timestamp.jpg';
        
        print('Uploading: $fileName'); // Debug

        // Tentukan content type
        String contentType = 'image/jpeg';
        if (_buktiFile!.path.endsWith('.png')) {
          contentType = 'image/png';
        }
        await supabase.storage
            .from('bukti_bayar')
            .upload(
              fileName,
              _buktiFile!,
              fileOptions: FileOptions(contentType: contentType),
            );

        // Buat signed URL (karena bucket tidak public)
        final signedUrl = await supabase.storage
            .from('bukti_bayar')
            .createSignedUrl(fileName, 3600);

        // Update database dengan signed URL
        await supabase
            .from('pendaftaran_tim')
            .update({
              'bukti_pembayaran': signedUrl,
              'status_pembayaran': 'menunggu',
            })
            .eq('id_pendaftaran', pendaftaranId);

        print('Upload success: $signedUrl');

        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bukti transfer berhasil dikirim! Menunggu verifikasi admin.'),
            backgroundColor: AppColors.success,
          ),
        );

        context.go('/user/home');
      } catch (e) {
        print('Upload error: $e');
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
          future: _pendaftaranData,
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

            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(
                child: Text(
                  'Data pendaftaran kosong bray.',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final pendaftaran = snapshot.data!;
            
            final sesiScrim = pendaftaran['sesi_scrim'] as Map<String, dynamic>?;
            final scrim = sesiScrim?['scrim'] as Map<String, dynamic>?;

            final String namaScrimDinamis = scrim?['nama_scrim'] ?? 'Scrim By Kelompok 2';
            final String namaSesiDinamis = sesiScrim?['nama_sesi'] != null ? ' (${sesiScrim?['nama_sesi']})' : '';
            final dynamic biayaDinamis = scrim?['biaya_pendaftaran'];
            
            // Ambil value metode pembayaran dari DB bray
            final String metodePembayaran = pendaftaran['metode_pembayaran_daftar'] ?? '';

            // Logika Penentuan Konten Info Transfer Dinamis bray
            String infoTitle = 'Info Transfer';
            String namaMetode = 'Bank BCA';
            String nomorTujuan = '0022000A1A26';
            String atasNama = 'BooyahHub Official';
            bool isQris = false;

            if (metodePembayaran == 'qris') {
              infoTitle = 'Scan QRIS';
              namaMetode = 'QRIS All Payment';
              nomorTujuan = 'LINK_QRIS_BOOYAHHUB'; 
              atasNama = 'Nanti bisa lu ganti gambar QR Code bray';
              isQris = true;
            } else if (metodePembayaran == 'ewallet') {
              infoTitle = 'Info E-Wallet';
              namaMetode = 'Dana';
              nomorTujuan = '081234567890';
              atasNama = 'A/N Admin BooyahHub';
            }

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
                          _buildRowDetail('Scrim', '$namaScrimDinamis$namaSesiDinamis'),
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
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _formatRupiah(biayaDinamis),
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

                    // ─── KARTU 2: INFO TRANSFER (SEKARANG DINAMIS) ────────────
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
                            infoTitle,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            namaMetode,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            atasNama,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Kalau pilih QRIS, bisa tampilin placeholder/gambar QR bray
                          if (isQris)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.qr_code_2, size: 150, color: Colors.black),
                                  SizedBox(height: 4),
                                  Text(
                                    'Silahkan Scan QRIS Diatas',
                                    style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold),
                                  )
                                ],
                              ),
                            )
                          else
                            // Selain QRIS (BCA/E-wallet), tampilin row nomer rekening + tombol salin bray
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
                                      nomorTujuan,
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
                                        // Opsional: Bisa dipasang Clipboard.setData buat fungsi salin bray
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
                            setState(() {
                              _buktiFile = File(image.path);
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
                            if (_buktiFile != null) ...[
                            const SizedBox(height: 12),
                            Image.file(
                              _buktiFile!,
                              height: 150,
                              fit: BoxFit.cover,
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
                          if (_buktiFile == null) {
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
                          'Kirim',
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
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
  }