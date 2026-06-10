// lib/presentation/admin/admin_bayar_tagihan_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_session.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/services/admin_utang_service.dart';

class AdminBayarTagihanPage extends StatefulWidget {
  const AdminBayarTagihanPage({super.key});

  @override
  State<AdminBayarTagihanPage> createState() => _AdminBayarTagihanPageState();
}

class _AdminBayarTagihanPageState extends State<AdminBayarTagihanPage> {
  final _supabase = Supabase.instance.client;
  final _adminUtangService = AdminUtangService();
  
  bool _isLoading = true;
  double _totalUtang = 0;
  double _limitUtang = 0;
  String _statusAkun = '';
  int? _adminId;
  
  // Data Owner (rekening)
  Map<String, dynamic>? _ownerData;
  bool _isLoadingOwner = true;
  
  final _nominalController = TextEditingController();
  String? _selectedMetode; // 'bank' atau 'qris'
  String? _selectedBank;
  Uint8List? _buktiBytes;
  bool _isSubmitting = false;

  // Daftar bank yang tersedia
  final List<Map<String, String>> _bankOptions = [
    {'value': 'bca', 'label': 'BCA', 'logo': '🏦'},
    {'value': 'mandiri', 'label': 'Mandiri', 'logo': '🏦'},
    {'value': 'bri', 'label': 'BRI', 'logo': '🏦'},
    {'value': 'bni', 'label': 'BNI', 'logo': '🏦'},
    {'value': 'cimb', 'label': 'CIMB Niaga', 'logo': '🏦'},
    {'value': 'danamon', 'label': 'Danamon', 'logo': '🏦'},
    {'value': 'permata', 'label': 'Permata Bank', 'logo': '🏦'},
    {'value': 'other', 'label': 'Bank Lainnya', 'logo': '🏦'},
  ];

  // Data QRIS Owner
  String? _qrisUrl;
  bool _showQris = false;

  final List<Map<String, String>> _metodeOptions = [
    {'value': 'bank', 'label': 'Transfer Bank'},
    {'value': 'qris', 'label': 'QRIS'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadOwnerData();
  }

  @override
  void dispose() {
    _nominalController.dispose();
    super.dispose();
  }

  Future<void> _loadOwnerData() async {
    setState(() => _isLoadingOwner = true);
    try {
      // Ambil data owner (profil_owner)
      final ownerData = await _supabase
          .from('akun')
          .select('''
            id_akun,
            profil_owner (
              bank_owner,
              nomor_rekening,
              kode_qris
            )
          ''')
          .eq('role', 'owner')
          .maybeSingle();
      
      if (ownerData != null) {
        final profil = ownerData['profil_owner'] as Map<String, dynamic>?;
        setState(() {
          _ownerData = profil;
          _qrisUrl = profil?['kode_qris'];
        });
      }
    } catch (e) {
      debugPrint('Error load owner data: $e');
    } finally {
      setState(() => _isLoadingOwner = false);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final email = _supabase.sessionEmail;
      if (email == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Silakan login terlebih dahulu')),
          );
          context.go('/login');
        }
        return;
      }
      
      final data = await _supabase
          .from('akun')
          .select('''
            id_akun,
            status_akun,
            profil_admin (
              total_utang,
              limit_utang
            )
          ''')
          .eq('email', email!)
          .maybeSingle();
      
      if (data == null) {
        throw Exception('Data admin tidak ditemukan');
      }
      
      final profil = data['profil_admin'] as Map<String, dynamic>?;
      
      setState(() {
        _adminId = data['id_akun'];
        _totalUtang = (profil?['total_utang'] ?? 0).toDouble();
        _limitUtang = (profil?['limit_utang'] ?? 100000).toDouble();
        _statusAkun = data['status_akun'] ?? 'aktif';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error load data: $e');
      setState(() {
        _isLoading = false;
      });
      _showMessage('Gagal memuat data: $e', isError: true);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showMessage('$label berhasil disalin');
  }

  Future<void> _submitPembayaran() async {
    if (_nominalController.text.isEmpty) {
      _showMessage('Masukkan nominal pembayaran', isError: true);
      return;
    }
    
    final nominal = double.tryParse(_nominalController.text) ?? 0;
    if (nominal <= 0) {
      _showMessage('Nominal tidak valid', isError: true);
      return;
    }
    
    if (nominal > _totalUtang) {
      _showMessage('Nominal melebihi total utang', isError: true);
      return;
    }
    
    if (_selectedMetode == null) {
      _showMessage('Pilih metode pembayaran', isError: true);
      return;
    }
    
    if (_selectedMetode == 'bank' && _selectedBank == null) {
      _showMessage('Pilih bank tujuan', isError: true);
      return;
    }
    
    if (_buktiBytes == null) {
      _showMessage('Upload bukti pembayaran', isError: true);
      return;
    }
    
    setState(() => _isSubmitting = true);
    
    try {
      if (_adminId == null) throw Exception('Admin ID tidak ditemukan');
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = 'admin/pelunasan_${_adminId}_$timestamp.jpg';
      
      print('Uploading to: $filePath');
      
      await _supabase.storage
          .from('bukti_bayar')
          .uploadBinary(filePath, _buktiBytes!);
      
      print('Upload success!');
      
      final metodeDisplay = _selectedMetode == 'bank' 
          ? 'Transfer Bank ${_selectedBank?.toUpperCase()}' 
          : 'QRIS';
      final result = await _adminUtangService.ajukanPelunasan(
        adminId: _adminId!,
        nominal: nominal,
        buktiBayarUrl: filePath,
        metodeBayar: metodeDisplay,
        catatan: 'Pelunasan tagihan utang admin via $metodeDisplay',
      );
      
      if (result['success']) {
        _showMessage(result['message']);
        _nominalController.clear();
        setState(() {
          _buktiBytes = null;
          _selectedMetode = null;
          _selectedBank = null;
          _showQris = false;
        });
        await _loadData();
      } else {
        _showMessage(result['message'], isError: true);
      }
    } catch (e) {
      print('Upload error: $e');
      _showMessage('Gagal mengirim pembayaran: $e', isError: true);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bayar Tagihan', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading || _isLoadingOwner
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 24),
                  _buildUtangCard(),
                  const SizedBox(height: 24),
                  _buildFormTitle(),
                  const SizedBox(height: 16),
                  _buildNominalField(),
                  const SizedBox(height: 16),
                  _buildMetodeDropdown(),
                  const SizedBox(height: 16),
                  if (_selectedMetode == 'bank') _buildBankDropdown(),
                  if (_selectedMetode == 'bank' && _selectedBank != null) _buildRekeningInfo(),
                  if (_selectedMetode == 'qris') _buildQrisInfo(),
                  const SizedBox(height: 16),
                  _buildUploadBukti(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                  const SizedBox(height: 20),
                  _buildInfoFooter(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final isSuspended = _statusAkun == 'suspended';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSuspended 
            ? Colors.red.withOpacity(0.1) 
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSuspended ? Colors.red : Colors.green,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuspended ? Icons.warning_amber_rounded : Icons.check_circle,
            color: isSuspended ? Colors.red : Colors.green,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSuspended ? 'Akun Ditangguhkan' : 'Akun Aktif',
                  style: AppTextStyles.poppinsTitleSmall.copyWith(
                    color: isSuspended ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSuspended
                      ? 'Silakan lunasi tagihan untuk mengaktifkan akun kembali'
                      : 'Anda dapat membuat scrim baru',
                  style: AppTextStyles.interCaption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUtangCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildInfoRow('Total Utang', _adminUtangService.formatRupiah(_totalUtang)),
          const SizedBox(height: 12),
          _buildInfoRow('Limit Utang', _adminUtangService.formatRupiah(_limitUtang)),
          const SizedBox(height: 12),
          _buildInfoRow('Sisa Limit', _adminUtangService.formatRupiah(_limitUtang - _totalUtang)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.interBody),
        Text(
          value,
          style: AppTextStyles.interBodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: label == 'Total Utang' && _totalUtang > 0 
                ? Colors.orange 
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildFormTitle() {
    return Text(
      'Form Pembayaran',
      style: AppTextStyles.poppinsTitleSmall,
    );
  }

  Widget _buildNominalField() {
    return TextFormField(
      controller: _nominalController,
      keyboardType: TextInputType.number,
      style: AppTextStyles.interInput,
      decoration: InputDecoration(
        labelText: 'Nominal Pembayaran',
        hintText: 'Masukkan nominal yang akan dibayar',
        prefixIcon: const Icon(Icons.money, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildMetodeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pilih Metode Pembayaran', style: AppTextStyles.interLabel),
        const SizedBox(height: 8),
        Row(
          children: _metodeOptions.map((option) {
            final isSelected = _selectedMetode == option['value'];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMetode = option['value'];
                      _selectedBank = null;
                      _showQris = _selectedMetode == 'qris';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.inputFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        option['label']!,
                        style: TextStyle(
                          color: isSelected ? Colors.black : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBankDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Pilih Bank Tujuan', style: AppTextStyles.interLabel),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedBank,
              isExpanded: true,
              hint: Text('Pilih Bank', style: AppTextStyles.interHint),
              dropdownColor: AppColors.backgroundCard,
              style: AppTextStyles.interInput,
              items: _bankOptions.map((bank) {
                return DropdownMenuItem<String>(
                  value: bank['value'],
                  child: Row(
                    children: [
                      Text(bank['logo']!),
                      const SizedBox(width: 12),
                      Text(bank['label']!),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBank = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRekeningInfo() {
    if (_ownerData == null) return const SizedBox();
    
    final bankLabel = _selectedBank != null
        ? _bankOptions.firstWhere(
            (b) => b['value'] == _selectedBank,
            orElse: () => {'label': _selectedBank?.toUpperCase() ?? 'Bank'},
          )['label'] ?? _selectedBank!.toUpperCase()
        : 'Bank';
    final namaPemilik = _ownerData?['nama_pemilik'] as String? ?? 'BooyahHub Official';
    final nomorRekening = _ownerData?['nomor_rekening'] as String? ?? '-';
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Rekening Tujuan',
                style: AppTextStyles.interBodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRekeningRow('Bank', bankLabel),
          const SizedBox(height: 8),
          _buildRekeningRow('Atas Nama', namaPemilik),
          const SizedBox(height: 8),
          _buildRekeningRow('Nomor Rekening', nomorRekening, canCopy: true),
        ],
      ),
    );
  }

  Widget _buildRekeningRow(String label, String value, {bool canCopy = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.interCaption.copyWith(color: AppColors.textSecondary)),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(value, style: AppTextStyles.interBodyMedium),
              if (canCopy && value != '-') ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _copyToClipboard(value, 'Nomor rekening'),
                  child: const Icon(Icons.copy, size: 16, color: AppColors.primary),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQrisInfo() {
    if (_qrisUrl == null || _qrisUrl!.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.qr_code, color: Colors.red, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'QRIS belum tersedia. Silakan hubungi owner untuk informasi pembayaran.',
                style: AppTextStyles.interBody.copyWith(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.qr_code_scanner, size: 80, color: Colors.black),
          const SizedBox(height: 12),
          Text(
            'Scan QRIS di atas',
            style: AppTextStyles.interBodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Gunakan aplikasi mobile banking atau e-wallet untuk scan QRIS',
            style: AppTextStyles.interCaption.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadBukti() {
    return GestureDetector(
      onTap: () async {
        final picker = ImagePicker();
        final image = await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          final bytes = await image.readAsBytes();
          setState(() => _buktiBytes = bytes);
        }
      },
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _buktiBytes != null ? AppColors.primary : AppColors.inputBorder,
            width: _buktiBytes != null ? 2 : 1,
          ),
        ),
        child: _buktiBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_buktiBytes!, fit: BoxFit.cover, width: double.infinity),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'Upload Bukti Pembayaran',
                    style: AppTextStyles.interLabel.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Format: JPG, PNG (Max. 5MB)',
                    style: AppTextStyles.interCaption.copyWith(color: AppColors.textHint),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitPembayaran,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
              )
            : Text('Kirim Pembayaran', style: AppTextStyles.poppinsButton),
      ),
    );
  }

  Widget _buildInfoFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Setelah mengirim bukti pembayaran, owner akan melakukan verifikasi. Akun akan aktif kembali setelah verifikasi selesai.',
              style: AppTextStyles.interCaption.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}