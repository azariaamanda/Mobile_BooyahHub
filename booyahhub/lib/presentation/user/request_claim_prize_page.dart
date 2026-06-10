import 'package:flutter/material.dart';
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
  final _noHpController = TextEditingController();

  bool _isBankSelected = true;
  bool _isLoading = false;
  bool _isFetchingMethods = true;

  bool _isBankAvailable = true;
  bool _isQrisAvailable = false;

  List<String> _bankOptions = [];
  String? _selectedBank;

  @override
  void initState() {
    super.initState();
    _loadClaimOptions();
  }

  Future<void> _loadClaimOptions() async {
    setState(() => _isFetchingMethods = true);

    try {
      final supabase = Supabase.instance.client;

      /*
        Untuk klaim hadiah:
        - Pilihan bank user diambil dari enum Supabase nama_bank_enum.
        - Bukan dari metode_pembayaran_penyelenggara milik admin.
        - Kalau enum gagal dibaca lewat RPC/SQL schema, fallback tetap dipakai.
      */
      final enumBanks = await _fetchNamaBankEnumValues();

      bool hasQris = false;

      if (widget.pendaftaranId != null) {
        try {
          final pendaftaranRes = await supabase
              .from('pendaftaran_tim')
              .select('''
                id_sesi,
                sesi_scrim!inner(
                  id_scrim,
                  scrim!inner(id_admin)
                )
              ''')
              .eq('id_pendaftaran', widget.pendaftaranId!)
              .maybeSingle();

          if (pendaftaranRes != null) {
            final adminAkunId =
                pendaftaranRes['sesi_scrim']['scrim']['id_admin'];

            final metodeRes = await supabase
                .from('metode_pembayaran_penyelenggara')
                .select('jenis_metode')
                .eq('akun_id', adminAkunId)
                .eq('is_active', true);

            for (final metode in metodeRes as List) {
              if (metode['jenis_metode'] == 'qris') {
                hasQris = true;
              }
            }
          }
        } catch (e) {
          debugPrint('Gagal cek QRIS admin: $e');
        }
      }

      if (!mounted) return;

      setState(() {
        _bankOptions = enumBanks;
        _isBankAvailable = _bankOptions.isNotEmpty;
        _isQrisAvailable = hasQris;

        if (_isBankAvailable) {
          _isBankSelected = true;
          _selectedBank = _bankOptions.first;
        } else if (_isQrisAvailable) {
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
        _isQrisAvailable = false;
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
    _noHpController.dispose();
    super.dispose();
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

      await supabase.from('klaim_hadiah').insert({
        'id_pendaftaran': widget.pendaftaranId,
        'jumlah_klaim': totalPrizeValue,
        'status_klaim': 'diajukan',
        'metode_klaim': _isBankSelected ? 'bank_transfer' : 'qris',
        'nama_bank': _isBankSelected ? _selectedBank : null,
        'nomor_rekening': _isBankSelected
            ? _rekeningController.text.trim()
            : _noHpController.text.trim(),
        'nama_pemilik_rekening': _namaPemilikController.text.trim(),
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

  Widget _buildQrisForm() {
    return Column(
      children: [
        _buildInputField(
          controller: _noHpController,
          label: 'Nomor Handphone Terdaftar',
          hint: '081234567890',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _namaPemilikController,
          label: 'Nama Pemilik QRIS',
          hint: 'Nama merchant QRIS / pemilik',
        ),
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
                  'Proses verifikasi klaim membutuhkan waktu maksimal 2 x 24 jam hari kerja.\nPastikan data rekening yang anda masukkan sudah benar',
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitClaim,
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
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(
          'Ajukan Klaim Hadiah',
          style: AppTextStyles.poppinsTitle.copyWith(
            color: AppColors.textPrimary,
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