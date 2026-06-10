import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

class KlaimHadiahDetailPage extends StatefulWidget {
  final int idKlaim;

  const KlaimHadiahDetailPage({
    super.key,
    required this.idKlaim,
  });

  @override
  State<KlaimHadiahDetailPage> createState() => _KlaimHadiahDetailPageState();
}

class _KlaimHadiahDetailPageState extends State<KlaimHadiahDetailPage> {
  final _supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  Map<String, dynamic>? _klaim;

  XFile? _selectedBuktiBayar;
  Uint8List? _selectedBuktiBayarBytes;

  static const String _bucketQris = 'qr_qris';
  static const String _bucketBuktiBayar = 'bukti_bayar';

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _supabase
          .from('klaim_hadiah')
          .select('''
            id_klaim,
            id_pendaftaran,
            status_klaim,
            jumlah_klaim,
            metode_klaim,
            nama_bank,
            nomor_rekening,
            nama_pemilik_rekening,
            nama_pemilik_qris,
            qris_image,
            id_transaksi_qris,
            bukti_bayar_hadiah,
            diajukan_pada,
            disetujui_admin_pada,
            dibayar_pada,
            pendaftaran_tim!inner(
              id_pendaftaran,
              nama_kapten,
              whatsapp_kapten,
              id_sesi,
              sesi_scrim!inner(
                nama_sesi,
                waktu_mulai,
                waktu_selesai,
                scrim!inner(
                  nama_scrim
                )
              )
            )
          ''')
          .eq('id_klaim', widget.idKlaim)
          .maybeSingle();

      if (data == null) {
        throw Exception('Data klaim tidak ditemukan.');
      }

      if (!mounted) return;

      setState(() {
        _klaim = Map<String, dynamic>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Gagal memuat detail klaim: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickBuktiBayar() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      final Uint8List bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _selectedBuktiBayar = image;
        _selectedBuktiBayarBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih foto bukti transfer: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _getImageExtension(String fileName) {
    final lower = fileName.toLowerCase();

    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.webp')) return 'webp';
    if (lower.endsWith('.jpg')) return 'jpg';
    if (lower.endsWith('.jpeg')) return 'jpg';

    return 'jpg';
  }

  String _getImageContentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }

  String _extractStoragePath(String value, String bucketName) {
    if (value.isEmpty) return value;

    if (!value.startsWith('http')) {
      return value;
    }

    final publicMarker = '/storage/v1/object/public/$bucketName/';
    final signMarker = '/storage/v1/object/sign/$bucketName/';

    if (value.contains(publicMarker)) {
      final path = value.split(publicMarker).last.split('?').first;
      return Uri.decodeComponent(path);
    }

    if (value.contains(signMarker)) {
      final path = value.split(signMarker).last.split('?').first;
      return Uri.decodeComponent(path);
    }

    return value;
  }

  Future<String> _createSignedImageUrl({
    required String? value,
    required String bucketName,
  }) async {
    if (value == null || value.trim().isEmpty) {
      throw Exception('Path gambar kosong.');
    }

    final raw = value.trim();
    final path = _extractStoragePath(raw, bucketName);

    if (path.startsWith('http') && !path.contains('/storage/v1/object/')) {
      return path;
    }

    final signedUrl = await _supabase.storage.from(bucketName).createSignedUrl(
          path,
          60 * 60,
        );

    return signedUrl;
  }

  Future<String> _uploadBuktiBayarHadiah() async {
    if (_selectedBuktiBayar == null || _selectedBuktiBayarBytes == null) {
      throw 'Foto bukti transfer wajib diupload.';
    }

    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw 'Sesi login habis. Silakan login ulang.';
    }

    final extension = _getImageExtension(_selectedBuktiBayar!.name);
    final contentType = _getImageContentType(extension);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final filePath =
        'admin_claim/${user.id}_${widget.idKlaim}_$timestamp.$extension';

    await _supabase.storage.from(_bucketBuktiBayar).uploadBinary(
          filePath,
          _selectedBuktiBayarBytes!,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );

    return filePath;
  }

  Future<void> _tandaiDibayar() async {
    if (_klaim == null) return;

    if (_selectedBuktiBayar == null || _selectedBuktiBayarBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto bukti transfer wajib diupload.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: Text(
            'Tandai Sudah Dibayar?',
            style: AppTextStyles.poppinsTitleSmall,
          ),
          content: Text(
            'Pastikan hadiah sudah benar-benar ditransfer ke user.',
            style: AppTextStyles.interBody,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Ya, Dibayar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      final buktiBayarPath = await _uploadBuktiBayarHadiah();

      await _supabase.from('klaim_hadiah').update({
        'status_klaim': 'dibayar',
        'bukti_bayar_hadiah': buktiBayarPath,
        'dibayar_pada': DateTime.now().toIso8601String(),
        'id_transaksi_qris': null,
      }).eq('id_klaim', widget.idKlaim);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Klaim berhasil ditandai sudah dibayar.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal update klaim: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatRupiah(dynamic value) {
    final number = (value as num?)?.toDouble() ?? 0;
    final str = number.toStringAsFixed(0);

    final buffer = StringBuffer();
    int counter = 0;

    for (int i = str.length - 1; i >= 0; i--) {
      if (counter > 0 && counter % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(str[i]);
      counter++;
    }

    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  String _formatDate(String? raw) {
    if (raw == null) return '-';

    try {
      final dt = DateTime.parse(raw).toLocal();

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];

      return '${dt.day} ${months[dt.month - 1]} ${dt.year} ${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '-';
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'belum_diajukan':
        return 'Belum Diajukan';
      case 'diajukan':
        return 'Diajukan';
      case 'disetujui_admin':
        return 'Disetujui Admin';
      case 'dibayar':
        return 'Dibayar';
      default:
        return status.isEmpty ? '-' : status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'dibayar':
        return Colors.green;
      case 'disetujui_admin':
        return Colors.orange;
      case 'diajukan':
        return AppColors.primary;
      case 'belum_diajukan':
      default:
        return AppColors.textHint;
    }
  }

  Map<String, dynamic> get _nested {
    final pendaftaran = _klaim?['pendaftaran_tim'] as Map<String, dynamic>?;
    final sesi = pendaftaran?['sesi_scrim'] as Map<String, dynamic>?;
    final scrim = sesi?['scrim'] as Map<String, dynamic>?;

    return {
      'pendaftaran': pendaftaran,
      'sesi': sesi,
      'scrim': scrim,
    };
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: AppTextStyles.interCaption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.interBodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.poppinsTitleSmall.copyWith(
              color: AppColors.primary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPrivateImagePreview({
    required String? value,
    required String bucketName,
  }) {
    if (value == null || value.trim().isEmpty) {
      return Text(
        'Belum ada gambar.',
        style: AppTextStyles.interCaption.copyWith(
          color: AppColors.textHint,
        ),
      );
    }

    return FutureBuilder<String>(
      future: _createSignedImageUrl(
        value: value,
        bucketName: bucketName,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            height: 220,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: const CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error),
            ),
            child: Text(
              'Gagal membuat akses gambar: ${snapshot.error ?? '-'}',
              style: const TextStyle(color: AppColors.error),
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            snapshot.data!,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;

              return Container(
                width: double.infinity,
                height: 220,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: const CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            },
            errorBuilder: (_, __, ___) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error),
                ),
                child: const Text(
                  'Gagal memuat gambar. Pastikan policy SELECT bucket sudah benar.',
                  style: TextStyle(color: AppColors.error),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildUploadBuktiBox({required bool disabled}) {
    final hasSelected = _selectedBuktiBayar != null;

    return GestureDetector(
      onTap: disabled ? null : _pickBuktiBayar,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundInput,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasSelected ? AppColors.primary : AppColors.divider,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasSelected ? Icons.check_circle : Icons.upload_file,
              color: hasSelected ? AppColors.primary : AppColors.textHint,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasSelected
                    ? _selectedBuktiBayar!.name
                    : 'Upload foto bukti transfer hadiah',
                style: AppTextStyles.interBodyMedium.copyWith(
                  color:
                      hasSelected ? AppColors.textPrimary : AppColors.textHint,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              hasSelected ? 'Ganti' : 'Upload',
              style: AppTextStyles.interCaption.copyWith(
                color: disabled ? AppColors.textHint : AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final klaim = _klaim!;
    final nested = _nested;

    final pendaftaran = nested['pendaftaran'] as Map<String, dynamic>?;
    final sesi = nested['sesi'] as Map<String, dynamic>?;
    final scrim = nested['scrim'] as Map<String, dynamic>?;

    final status = klaim['status_klaim']?.toString() ?? '';
    final metode = klaim['metode_klaim']?.toString() ?? '-';
    final isDibayar = status == 'dibayar';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _statusColor(status).withOpacity(0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatRupiah(klaim['jumlah_klaim']),
                  style: AppTextStyles.poppinsMoneyLarge.copyWith(
                    fontSize: 30,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      color: _statusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildCard(
            title: 'Data Scrim',
            children: [
              _buildInfoRow(
                'Nama Scrim',
                scrim?['nama_scrim']?.toString() ?? '-',
              ),
              _buildInfoRow(
                'Sesi',
                sesi?['nama_sesi']?.toString() ?? '-',
              ),
              _buildInfoRow(
                'Kapten',
                pendaftaran?['nama_kapten']?.toString() ?? '-',
              ),
              _buildInfoRow(
                'WhatsApp',
                pendaftaran?['whatsapp_kapten']?.toString() ?? '-',
              ),
              _buildInfoRow(
                'Diajukan',
                _formatDate(klaim['diajukan_pada']?.toString()),
              ),
              if (klaim['dibayar_pada'] != null)
                _buildInfoRow(
                  'Dibayar Pada',
                  _formatDate(klaim['dibayar_pada']?.toString()),
                ),
            ],
          ),
          _buildCard(
            title: 'Data Pencairan User',
            children: [
              _buildInfoRow('Metode', metode.toUpperCase()),
              if (metode == 'bank_transfer') ...[
                _buildInfoRow(
                  'Bank',
                  klaim['nama_bank']?.toString() ?? '-',
                ),
                _buildInfoRow(
                  'Nomor Rekening',
                  klaim['nomor_rekening']?.toString() ?? '-',
                ),
                _buildInfoRow(
                  'Nama Pemilik',
                  klaim['nama_pemilik_rekening']?.toString() ?? '-',
                ),
              ] else ...[
                _buildInfoRow(
                  'Nama QRIS',
                  klaim['nama_pemilik_qris']?.toString() ?? '-',
                ),
                const SizedBox(height: 8),
                Text(
                  'QRIS User',
                  style: AppTextStyles.interLabel.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPrivateImagePreview(
                  value: klaim['qris_image']?.toString(),
                  bucketName: _bucketQris,
                ),
              ],
            ],
          ),
          _buildCard(
            title: 'Bukti Pembayaran Hadiah',
            children: [
              if (isDibayar) ...[
                Text(
                  'Bukti Transfer Admin',
                  style: AppTextStyles.interLabel.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPrivateImagePreview(
                  value: klaim['bukti_bayar_hadiah']?.toString(),
                  bucketName: _bucketBuktiBayar,
                ),
              ] else ...[
                Text(
                  'Upload Bukti Transfer',
                  style: AppTextStyles.interLabel.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildUploadBuktiBox(disabled: isDibayar),
                const SizedBox(height: 10),
                Text(
                  'Upload bukti transfer setelah hadiah dibayarkan ke user.',
                  style: AppTextStyles.interCaption.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        isDibayar || _isSubmitting ? null : _tandaiDibayar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.surfaceVariant,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Tandai Sudah Dibayar',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Terjadi kesalahan',
              style: AppTextStyles.interBody,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
              ),
              onPressed: _fetchDetail,
              child: const Text(
                'Coba Lagi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Detail Klaim',
          style: AppTextStyles.poppinsTitle.copyWith(
            color: AppColors.primary,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.primary,
          ),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : _error != null
              ? _buildError()
              : _buildBody(),
    );
  }
}