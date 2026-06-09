import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_session.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/saldo_pengguna_model.dart';
import '../../data/models/services/keuangan_service.dart';

class WithdrawPage extends StatefulWidget {
  final SaldoPengguna saldo;

  const WithdrawPage({super.key, required this.saldo});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final KeuanganService _keuanganService = KeuanganService();
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  int? _idAkun; // Make _idAkun nullable
  // double _amount = 0; // This variable is unused. Can be removed.
  String _selectedBank = 'BRI';
  final TextEditingController _nominalController = TextEditingController();
  final TextEditingController _nomorRekeningController =
      TextEditingController();
  final TextEditingController _namaAtasController = TextEditingController();

  bool _isLoading = false;

  final List<String> _banks = [
    'BRI',
    'BCA',
    'Mandiri',
    'BNI',
    'CIMB Niaga',
    'OVO',
    'Dana',
    'LinkAja',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAkun();
  }

  void _initializeAkun() async {
    try {
      final email = _supabase.sessionEmail;
      if (email == null) throw Exception('User tidak ditemukan');
      // Jika user tidak ditemukan, kita harus mengarahkan atau menampilkan error.
      // Untuk saat ini, pastikan _idAkun tidak digunakan jika belum diatur.

      final akunResponse = await _supabase
          .from('akun')
          .select('id_akun')
          .eq('email', email!)
          .maybeSingle();

      if (akunResponse == null) {
        // Jika data akun tidak ditemukan, kita harus mencegah penarikan.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Data akun tidak ditemukan. Tidak dapat melanjutkan penarikan.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
          // Secara opsional, pop halaman atau redirect.
          context.pop();
        }
        return;
      }

      // Hanya atur _idAkun jika akunResponse tidak null.
      if (akunResponse != null) {
        setState(() {
          _idAkun = akunResponse['id_akun'];
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  String _formatCurrency(double amount) {
    // Pastikan amount bukan null atau negatif sebelum pemformatan
    if (amount.isNaN || amount.isInfinite || amount < 0) {
      return 'Rp 0';
    }
    return 'Rp ${amount.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}';
  }

  Future<void> _submitWithdrawal() async {
    if (!mounted) return; // Tambahkan pemeriksaan ini di awal fungsi async

    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      final nominal = double.parse(_nominalController.text.replaceAll('.', ''));

      if (nominal > widget.saldo.saldoBisaDitarik) {
        throw Exception('Nominal melebihi saldo yang tersedia');
      }

      if (nominal < 50000) {
        throw Exception('Nominal minimum penarikan adalah Rp 50.000');
      }

      if (_idAkun == null) {
        // Periksa jika _idAkun adalah null
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID Akun tidak tersedia. Silakan coba lagi.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final transaksi = await _keuanganService.createPenarikan(
        idAkun:
            _idAkun!, // Gunakan operator null-assertion setelah pemeriksaan null
        nominal: nominal,
        nomorRekening: _nomorRekeningController.text,
        namaBank: _selectedBank,
        namaAtas: _namaAtasController.text,
      );

      if (!mounted) return;

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 48,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppConstants.paddingM),
              Text(
                'Permintaan Penarikan Dibuat',
                style: AppTextStyles.poppinsTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.paddingM),
              Text(
                'Nominal: ${_formatCurrency(nominal)}',
                style: AppTextStyles.poppinsMoney,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.paddingM),
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: Text(
                  'Permintaan Anda sedang diproses. Kami akan mentransfer dana dalam 1-2 hari kerja.',
                  style: AppTextStyles.interCaption,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/user/financial');
                },
                child: const Text('Kembali ke Keuangan'),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nominalController.dispose();
    _nomorRekeningController.dispose();
    _namaAtasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tarik Dana'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.info,
                          size: 20,
                        ),
                        const SizedBox(width: AppConstants.paddingS),
                        Expanded(
                          child: Text(
                            'Saldo Bisa Ditarik',
                            style: AppTextStyles.interCaption,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingS),
                    Text(
                      _formatCurrency(widget.saldo.saldoBisaDitarik),
                      style: AppTextStyles.poppinsMoneyLarge,
                    ),
                    const SizedBox(height: AppConstants.paddingS),
                    Text(
                      'Minimum penarikan: Rp 50.000',
                      style: AppTextStyles.interCaption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.paddingL),

              // Nominal Input
              Text('Nominal Penarikan', style: AppTextStyles.poppinsTitleSmall),
              const SizedBox(height: AppConstants.paddingS),
              TextFormField(
                controller: _nominalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Masukkan nominal',
                  prefixText: 'Rp ',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _nominalController.clear(),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nominal tidak boleh kosong';
                  }
                  try {
                    final nominal = double.parse(
                      value.replaceAll('.', '').replaceAll(',', '.'),
                    );
                    if (nominal < 50000) {
                      return 'Nominal minimum adalah Rp 50.000';
                    }
                    if (nominal > widget.saldo.saldoBisaDitarik) {
                      return 'Nominal melebihi saldo yang tersedia';
                    }
                  } catch (e) {
                    return 'Format nominal tidak valid';
                  }
                  return null;
                },
                onChanged: (value) {
                  final nominal = value.replaceAll('.', '');
                  final formatted = nominal.replaceAllMapped(
                    RegExp(r'\B(?=(\d{3})+(?!\d))'),
                    (Match m) => '.',
                  );
                  if (formatted != value && formatted.isNotEmpty) {
                    _nominalController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(
                        offset: formatted.length,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: AppConstants.paddingL),

              // Bank Selection
              Text(
                'Pilih Bank/E-Wallet',
                style: AppTextStyles.poppinsTitleSmall,
              ),
              const SizedBox(height: AppConstants.paddingS),
              DropdownButtonFormField<String>(
                value: _selectedBank,
                decoration: InputDecoration(
                  hintText: 'Pilih bank',
                  isDense: true,
                ),
                items: _banks
                    .map(
                      (bank) =>
                          DropdownMenuItem(value: bank, child: Text(bank)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedBank = value ?? 'BRI');
                },
              ),
              const SizedBox(height: AppConstants.paddingL),

              // Bank Account Number
              Text(
                'Nomor Rekening/Akun',
                style: AppTextStyles.poppinsTitleSmall,
              ),
              const SizedBox(height: AppConstants.paddingS),
              TextFormField(
                controller: _nomorRekeningController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Contoh: 1234567890',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nomor rekening tidak boleh kosong';
                  }
                  if (value.length < 10) {
                    return 'Nomor rekening tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.paddingL),

              // Account Holder Name
              Text('Atas Nama', style: AppTextStyles.poppinsTitleSmall),
              const SizedBox(height: AppConstants.paddingS),
              TextFormField(
                controller: _namaAtasController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Nama pemilik rekening',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.paddingL),

              // Terms
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Syarat & Ketentuan',
                      style: AppTextStyles.poppinsTitleSmall.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingS),
                    Text(
                      '• Proses penarikan memakan waktu 1-2 hari kerja\n'
                      '• Pastikan nomor rekening dan nama sudah benar\n'
                      '• Tidak dapat dibatalkan setelah diajukan\n'
                      '• Biaya administrasi mungkin akan dipotong',
                      style: AppTextStyles.interCaption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.paddingL),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitWithdrawal,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Ajukan Penarikan'),
                ),
              ),
              const SizedBox(height: AppConstants.paddingM),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(height: AppConstants.paddingL),
            ],
          ),
        ),
      ),
    );
  }
}
