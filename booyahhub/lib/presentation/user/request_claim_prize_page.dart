import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';

class RequestClaimPrizePage extends StatefulWidget {
  final String title;
  final String rank;
  final String totalPrize;
  final int? pendaftaranId;

  const RequestClaimPrizePage({
    super.key,
    required this.title,
    required this.rank,
    required this.totalPrize,
    this.pendaftaranId,
  });

  @override
  State<RequestClaimPrizePage> createState() => _RequestClaimPrizePageState();
}

class _RequestClaimPrizePageState extends State<RequestClaimPrizePage> {
  final _formKey = GlobalKey<FormState>();

  final _rekeningController = TextEditingController();
  final _namaPemilikController = TextEditingController();
  final _namaPemilikQrisController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  bool _isBankSelected = true;
  bool _isLoading = false;
  bool _isFetchingMethods = true;

  bool _isBankAvailable = true;
  bool _isQrisAvailable = true;

  List<String> _bankOptions = [];
  String? _selectedBank;

  XFile? _selectedQrisImage;
  Uint8List? _selectedQrisImageBytes;

  @override
  void initState() {
    super.initState();
    _loadClaimOptions();
  }

  Future<void> _loadClaimOptions() async {
    setState(() => _isFetchingMethods = true);

    try {
      final enumBanks = await _fetchNamaBankEnumValues();

      if (!mounted) return;

      setState(() {
        _bankOptions = enumBanks;
        _isBankAvailable = _bankOptions.isNotEmpty;

        // Untuk klaim hadiah, QRIS adalah data rekening tujuan user,
        // jadi tidak perlu bergantung pada metode pembayaran admin.
        _isQrisAvailable = true;

        if (_isBankAvailable) {
          _isBankSelected = true;
          _selectedBank = _bankOptions.first;
        } else {
          _isBankSelected = false;
        }

        _isFetchingMethods = false;
      });
    } catch (e) {
      debugPrint('Gagal load opsi klaim: $e');

      if (!mounted) return;

      setState(() {
        _bankOptions = _fallbackBankOptions;
        _isBankAvailable = true;
        _isQrisAvailable = true;
        _isBankSelected = true;
        _selectedBank = _bankOptions.first;
        _isFetchingMethods = false;
      });
    }
  }

  Future<List<String>> _fetchNamaBankEnumValues() async {
    try {
      final response = await Supabase.instance.client.rpc(
        'get_nama_bank_enum_values',
      );

      final values = (response as List)
          .map((item) {
            if (item is String) return item;

            if (item is Map && item['value'] != null) {
              return item['value'].toString();
            }

            if (item is Map && item['enum_value'] != null) {
              return item['enum_value'].toString();
            }

            return item.toString();
          })
          .where((value) => value.trim().isNotEmpty)
          .toSet()
          .toList();

      values.sort();

      if (values.isEmpty) return _fallbackBankOptions;

      return values;
    } catch (e) {
      debugPrint('RPC enum bank gagal, pakai fallback: $e');
      return _fallbackBankOptions;
    }
  }

  List<String> get _fallbackBankOptions {
    return [
      'BCA',
      'BNI',
      'BRI',
      'Mandiri',
      'BSI',
    ];
  }

  @override
  void dispose() {
    _rekeningController.dispose();
    _namaPemilikController.dispose();
    _namaPemilikQrisController.dispose();
    super.dispose();
  }

  Future<void> _pickQrisImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _selectedQrisImage = image;
        _selectedQrisImageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih gambar QRIS: $e'),
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

  Future<String> _uploadQrisImage() async {
    if (_selectedQrisImage == null || _selectedQrisImageBytes == null) {
      throw 'Foto QRIS wajib diupload.';
    }

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw 'Sesi login habis. Silakan login ulang.';
    }

    final extension = _getImageExtension(_selectedQrisImage!.name);
    final contentType = _getImageContentType(extension);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final filePath =
        'user_claim/${user.id}_${widget.pendaftaranId}_$timestamp.$extension';

    await supabase.storage.from('qr_qris').uploadBinary(
          filePath,
          _selectedQrisImageBytes!,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );

    final publicUrl = supabase.storage.from('qr_qris').getPublicUrl(filePath);

    return publicUrl;
  }

  Future<void> _submitClaim() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.pendaftaranId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: ID Pendaftaran tidak ditemukan'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_isBankSelected && _selectedQrisImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto QRIS wajib diupload.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      final existingClaim = await supabase
          .from('klaim_hadiah')
          .select('id_klaim')
          .eq('id_pendaftaran', widget.pendaftaranId!)
          .maybeSingle();

      if (existingClaim != null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Klaim sudah pernah diajukan.'),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.of(context).pop(true);
        return;
      }

      final double totalPrizeValue = double.tryParse(
            widget.totalPrize.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0;

      String? qrisImageUrl;

      if (!_isBankSelected) {
        qrisImageUrl = await _uploadQrisImage();
      }

      await supabase.from('klaim_hadiah').insert({
        'id_pendaftaran': widget.pendaftaranId,
        'jumlah_klaim': totalPrizeValue,
        'status_klaim': 'diajukan',
        'metode_klaim': _isBankSelected ? 'bank_transfer' : 'qris',
        'nama_bank': _isBankSelected ? _selectedBank : null,
        'nomor_rekening':
            _isBankSelected ? _rekeningController.text.trim() : null,
        'nama_pemilik_rekening':
            _isBankSelected ? _namaPemilikController.text.trim() : null,
        'nama_pemilik_qris':
            _isBankSelected ? null : _namaPemilikQrisController.text.trim(),
        'qris_image': _isBankSelected ? null : qrisImageUrl,

        'diajukan_pada': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Klaim berhasil diajukan!'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengajukan klaim: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.interLabel.copyWith(
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundInput,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: AppTextStyles.interInput,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Wajib diisi';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.interHint.copyWith(
                color: AppColors.textHint,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodToggle() {
    if (_isFetchingMethods) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (!_isBankAvailable && !_isQrisAvailable) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.error,
            width: 1,
          ),
        ),
        child: const Center(
          child: Text(
            'Metode klaim belum tersedia.',
            style: TextStyle(
              color: AppColors.error,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.info,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          if (_isBankAvailable)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _isBankSelected = true);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _isBankSelected
                        ? AppColors.backgroundInput
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance,
                        color: _isBankSelected
                            ? AppColors.primary
                            : AppColors.textHint,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rekening Bank',
                        style: AppTextStyles.interBodyMedium.copyWith(
                          color: _isBankSelected
                              ? AppColors.white
                              : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_isQrisAvailable)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _isBankSelected = false);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: !_isBankSelected
                        ? AppColors.backgroundInput
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_2,
                        color: !_isBankSelected
                            ? AppColors.primary
                            : AppColors.textHint,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'QRIS',
                        style: AppTextStyles.interBodyMedium.copyWith(
                          color: !_isBankSelected
                              ? AppColors.white
                              : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBankForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Bank',
          style: AppTextStyles.interLabel.copyWith(
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundInput,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: _bankOptions.contains(_selectedBank)
                  ? _selectedBank
                  : (_bankOptions.isNotEmpty ? _bankOptions.first : null),
              hint: Text(
                'Pilih bank tujuan pencairan',
                style: AppTextStyles.interHint.copyWith(
                  color: AppColors.textHint,
                ),
              ),
              dropdownColor: AppColors.backgroundCard,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textHint,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
              style: AppTextStyles.interInput,
              items: _bankOptions.map((bank) {
                return DropdownMenuItem<String>(
                  value: bank,
                  child: Text(bank),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedBank = newValue;
                });
              },
              validator: (value) {
                if (_isBankSelected && value == null) {
                  return 'Wajib dipilih';
                }
                return null;
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _rekeningController,
          label: 'Nomor Rekening',
          hint: 'Masukkan nomor rekening',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _namaPemilikController,
          label: 'Nama Pemilik Rekening',
          hint: 'Nama sesuai rekening',
        ),
      ],
    );
  }

  Widget _buildQrisUploadBox() {
    final hasImage = _selectedQrisImage != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Foto QRIS',
          style: AppTextStyles.interLabel.copyWith(
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickQrisImage,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundInput,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasImage ? AppColors.primary : AppColors.divider,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasImage ? Icons.check_circle : Icons.upload_file,
                  color: hasImage ? AppColors.primary : AppColors.textHint,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasImage
                        ? _selectedQrisImage!.name
                        : 'Pilih foto QRIS dari galeri',
                    style: AppTextStyles.interBodyMedium.copyWith(
                      color: hasImage
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  hasImage ? 'Ganti' : 'Upload',
                  style: AppTextStyles.interCaption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Foto QRIS akan disimpan untuk proses verifikasi klaim hadiah.',
          style: AppTextStyles.interCaption.copyWith(
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }

  Widget _buildQrisForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          controller: _namaPemilikQrisController,
          label: 'Nama Pemilik QRIS',
          hint: 'Nama merchant QRIS / pemilik',
        ),
        const SizedBox(height: 16),
        _buildQrisUploadBox(),
      ],
    );
  }

  Widget _buildPrizeCard() {
    return Container(
      width: double.infinity,
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
                      'CONGRATULATIONS',
                      style: AppTextStyles.interCaption.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.title,
                      style: AppTextStyles.poppinsHeadline.copyWith(
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.rank.toUpperCase(),
                  style: AppTextStyles.interCaption.copyWith(
                    color: AppColors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(
            color: AppColors.divider,
            thickness: 1,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Hadiah',
                    style: AppTextStyles.interCaption,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.totalPrize,
                    style: AppTextStyles.poppinsMoneyLarge.copyWith(
                      fontSize: 26,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.emoji_events,
                color: AppColors.primary,
                size: 32,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarningNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catatan Penting',
                  style: AppTextStyles.interBodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Proses verifikasi klaim membutuhkan waktu maksimal 2 x 24 jam hari kerja.\nPastikan data pencairan hadiah yang anda masukkan sudah benar.',
                  style: AppTextStyles.interCaption.copyWith(
                    color: AppColors.textHint,
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

  Widget _buildSubmitButton() {
    final bool disableButton = _isLoading || _isFetchingMethods;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: disableButton ? null : _submitClaim,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: AppColors.black,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Kirim Pengajuan',
                style: AppTextStyles.poppinsButton.copyWith(
                  color: AppColors.black,
                  fontSize: 18,
                ),
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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.primary,
          ),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(
          'Ajukan Klaim Hadiah',
          style: AppTextStyles.poppinsTitle.copyWith(
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildPrizeCard(),
              const SizedBox(height: 32),
              Text(
                'Metode Pencairan',
                style: AppTextStyles.poppinsTitleSmall,
              ),
              const SizedBox(height: 16),
              _buildMethodToggle(),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isBankSelected) _buildBankForm() else _buildQrisForm(),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              _buildWarningNote(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}