import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

class EditScrimPage extends StatefulWidget {
  final int scrimId;
  const EditScrimPage({super.key, required this.scrimId});

  @override
  State<EditScrimPage> createState() => _EditScrimPageState();
}

class _EditScrimPageState extends State<EditScrimPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  final _namaScrimController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _syaratController = TextEditingController();
  final _biayaController = TextEditingController();
  final _maksPesertaController = TextEditingController();
  final _jumlahMatchController = TextEditingController();

  int? _selectedModeId;
  String? _posterUrl;
  Uint8List? _newPosterBytes;
  bool _isLoading = false;
  bool _isLoadingModes = true;
  List<Map<String, dynamic>> _modes = [];
  String _statusScrim = 'aktif';

  // Fee settings from database
  int _feePlatformPersen = 25;
  int _nominalMinimumPlatform = 5000;
  int _feeAdminPersen = 10;
  int _feeAdminTetap = 10000;
  bool _isPersentaseAdmin = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchModes();
    _fetchFeeSettings();
  }

  Future<void> _fetchFeeSettings() async {
    try {
      final feeSetting = await _supabase
          .from('pengaturan_fee')
          .select()
          .maybeSingle();
      
      if (feeSetting != null && mounted) {
        setState(() {
          _feePlatformPersen = feeSetting['fee_platform_persen'] ?? 25;
          _nominalMinimumPlatform = feeSetting['nominal_minimum_platform'] ?? 5000;
          _feeAdminPersen = feeSetting['fee_admin_persen'] ?? 10;
          _feeAdminTetap = feeSetting['fee_admin_tetap'] ?? 10000;
          _isPersentaseAdmin = feeSetting['is_persentase_admin'] ?? true;
        });
      }
    } catch (e) {
      print('Error fetch fee settings: $e');
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final scrimData = await _supabase
          .from('scrim')
          .select()
          .eq('id_scrim', widget.scrimId)
          .single();

      _namaScrimController.text = scrimData['nama_scrim'] ?? '';
      _deskripsiController.text = scrimData['deskripsi'] ?? '';
      _syaratController.text = scrimData['syarat_ketentuan'] ?? '';
      _biayaController.text = scrimData['biaya_pendaftaran'].toString();
      _maksPesertaController.text = scrimData['maks_peserta'].toString();
      _jumlahMatchController.text = scrimData['jumlah_match'].toString();
      _selectedModeId = scrimData['id_mode'];
      _posterUrl = scrimData['poster'];
      _statusScrim = scrimData['status_scrim'] ?? 'aktif';
    } catch (e) {
      print('Error fetch data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchModes() async {
    setState(() => _isLoadingModes = true);
    try {
      final response = await _supabase
          .from('master_mode_pertandingan')
          .select('id_mode, nama_mode')
          .order('id_mode', ascending: true);

      setState(() => _modes = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat mode: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingModes = false);
    }
  }

  Future<void> _pickPoster() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _newPosterBytes = bytes);
    }
  }

  Future<String?> _uploadPoster() async {
    if (_newPosterBytes == null) return _posterUrl;

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'posters/$fileName';

    await _supabase.storage.from('posters').uploadBinary(path, _newPosterBytes!);
    return _supabase.storage.from('posters').getPublicUrl(path);
  }

  String _formatRupiah(int amount) {
    if (amount == 0) return 'Rp 0';
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  Future<void> _updateScrim() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedModeId == null) {
      _showSnackBar('Pilih mode pertandingan', isError: true);
      return;
    }
    final cekPeserta = int.tryParse(_maksPesertaController.text) ?? 0;
    if (cekPeserta < 2 || cekPeserta > 12) {
      _showSnackBar('Maks peserta harus antara 2–12 tim', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final posterUrl = await _uploadPoster();
      final biaya = int.tryParse(_biayaController.text) ?? 0;
      final maksPeserta = int.tryParse(_maksPesertaController.text) ?? 12;
      final totalPendaftaran = biaya * maksPeserta;

      int feePlatform = totalPendaftaran * _feePlatformPersen ~/ 100;
      if (feePlatform < _nominalMinimumPlatform) feePlatform = _nominalMinimumPlatform;
      
      int feeAdmin = _isPersentaseAdmin 
          ? (totalPendaftaran * _feeAdminPersen ~/ 100)
          : _feeAdminTetap;
          
      final totalHadiah = totalPendaftaran - (feePlatform + feeAdmin);

      await _supabase
          .from('scrim')
          .update({
            'id_mode': _selectedModeId,
            'nama_scrim': _namaScrimController.text,
            'biaya_pendaftaran': biaya,
            'total_hadiah': totalHadiah,
            'maks_peserta': maksPeserta,
            'jumlah_match': int.tryParse(_jumlahMatchController.text) ?? 3,
            'deskripsi': _deskripsiController.text,
            'syarat_ketentuan': _syaratController.text,
            'poster': posterUrl,
            'status_scrim': _statusScrim,
          })
          .eq('id_scrim', widget.scrimId);

      _showSnackBar('Scrim berhasil diperbarui!');
      if (mounted) context.go('/admin/dashboard');
    } catch (e) {
      _showSnackBar('Gagal: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.interBody),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final biaya = int.tryParse(_biayaController.text) ?? 0;
    final peserta = int.tryParse(_maksPesertaController.text) ?? 0;
    final totalPendaftaran = biaya * peserta;
    
    int feePlatform = totalPendaftaran * _feePlatformPersen ~/ 100;
    if (feePlatform < _nominalMinimumPlatform) feePlatform = _nominalMinimumPlatform;
    
    int feeAdmin = _isPersentaseAdmin 
        ? (totalPendaftaran * _feeAdminPersen ~/ 100)
        : _feeAdminTetap;
        
    final totalHadiah = totalPendaftaran - (feePlatform + feeAdmin);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Edit Scrim',
          style: AppTextStyles.poppinsTitle.copyWith(color: AppColors.primary),
        ),
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => context.go('/admin/dashboard'),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildSection('IDENTITAS UTAMA', [
                      _buildTextField(
                        'NAMA SCRIM',
                        _namaScrimController,
                        hint: 'Contoh: Ultimate Pro League S3',
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(),
                      const SizedBox(height: 16),
                      _buildUploadPoster(),
                      const SizedBox(height: 16),
                      _buildStatusDropdown(),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('KONTEN', [
                      _buildTextField(
                        'DESKRIPSI SCRIM',
                        _deskripsiController,
                        maxLines: 4,
                        hint: 'Jelaskan mengenai format dan tujuan turnamen...',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'SYARAT & KETENTUAN',
                        _syaratController,
                        maxLines: 5,
                        hint:
                            '1. Dilarang menggunakan emulator\n2. Dilarang cheat\n3. Harus tepat waktu...',
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('KEUANGAN & PESERTA', [
                      _buildTextField(
                        'BIAYA PENDAFTARAN',
                        _biayaController,
                        hint: '50000',
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'MAKS PESERTA',
                        _maksPesertaController,
                        hint: '12',
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'JUMLAH MATCH',
                        _jumlahMatchController,
                        hint: '3',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildTotalHadiahInfo(
                        totalPendaftaran,
                        totalHadiah,
                        feePlatform,
                        feeAdmin,
                      ),
                    ]),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateScrim,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
                                'SIMPAN PERUBAHAN',
                                style: AppTextStyles.poppinsButton,
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.poppinsTitleSmall.copyWith(
            color: AppColors.primary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.interLabel.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppTextStyles.interInput,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.interHint,
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: (v) =>
              v == null || v.isEmpty ? '$label wajib diisi' : null,
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    if (_isLoadingModes) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MODE PERTANDINGAN',
            style: AppTextStyles.interLabel.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Memuat mode pertandingan...',
                  style: AppTextStyles.interHint,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MODE PERTANDINGAN',
          style: AppTextStyles.interLabel.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          initialValue: _selectedModeId,
          dropdownColor: AppColors.backgroundCard,
          style: AppTextStyles.interInput,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          items: _modes.map((mode) {
            final id = mode['id_mode'] as int;
            final name = mode['nama_mode'] as String;
            return DropdownMenuItem<int>(
              value: id,
              child: Text(name, style: AppTextStyles.interInput),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedModeId = v),
          validator: (v) => v == null ? 'Pilih mode pertandingan' : null,
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STATUS SCRIM',
          style: AppTextStyles.interLabel.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _statusScrim,
          dropdownColor: AppColors.backgroundCard,
          style: AppTextStyles.interInput,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          items: ['aktif', 'selesai', 'dibatalkan'].map((status) {
            String label;
            switch (status) {
              case 'aktif':
                label = 'AKTIF';
                break;
              case 'selesai':
                label = 'SELESAI';
                break;
              case 'dibatalkan':
                label = 'DIBATALKAN';
                break;
              default:
                label = status.toUpperCase();
            }
            return DropdownMenuItem<String>(
              value: status,
              child: Text(label, style: AppTextStyles.interInput),
            );
          }).toList(),
          onChanged: (v) => setState(() => _statusScrim = v!),
        ),
      ],
    );
  }

  Widget _buildUploadPoster() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MEDIA POSTER',
          style: AppTextStyles.interLabel.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickPoster,
          child: Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _newPosterBytes != null || _posterUrl != null
                    ? AppColors.primary
                    : AppColors.inputBorder,
              ),
            ),
            child: _newPosterBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _newPosterBytes!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                : _posterUrl != null && _posterUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _posterUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, _, _) => _uploadPlaceholder(),
                    ),
                  )
                : _uploadPlaceholder(),
          ),
        ),
      ],
    );
  }

  Widget _uploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 32),
        const SizedBox(height: 8),
        Text(
          'GANTI POSTER',
          style: AppTextStyles.interLabel.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 4),
        Text(
          'Klik untuk mengganti poster',
          style: AppTextStyles.interCaption.copyWith(color: AppColors.textHint),
        ),
      ],
    );
  }

  Widget _buildTotalHadiahInfo(
    int totalPendaftaran,
    int totalHadiah,
    int feePlatform,
    int feeAdmin,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Pendaftaran', style: AppTextStyles.interBody),
              Text(
                _formatRupiah(totalPendaftaran),
                style: AppTextStyles.poppinsMoney.copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                feePlatform == _nominalMinimumPlatform 
                    ? 'Fee Platform (Min. Rp${_nominalMinimumPlatform ~/ 1000}K)' 
                    : 'Fee Platform ($_feePlatformPersen%)', 
                style: AppTextStyles.interBody
              ),
              Text(
                '- ${_formatRupiah(feePlatform)}',
                style: AppTextStyles.interBody.copyWith(color: AppColors.error),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isPersentaseAdmin ? 'Fee Admin ($_feeAdminPersen%)' : 'Fee Admin (Tetap)', 
                style: AppTextStyles.interBody
              ),
              Text(
                '- ${_formatRupiah(feeAdmin)}',
                style: AppTextStyles.interBody.copyWith(color: AppColors.error),
              ),
            ],
          ),
          const Divider(height: 16, color: AppColors.divider),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL HADIAH (NET)', style: AppTextStyles.goldHighlight),
              Text(
                _formatRupiah(totalHadiah),
                style: AppTextStyles.poppinsMoneyLarge.copyWith(fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
