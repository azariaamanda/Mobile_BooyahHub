import 'dart:io';
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
  String? _newPosterPath;
  bool _isLoading = false;
  bool _isLoadingModes = true;
  List<Map<String, dynamic>> _modes = [];
  String _statusScrim = 'aktif';

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchModes();
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
      
      if (response.isEmpty) {
        setState(() {
          _modes = [
            {'id_mode': 1, 'nama_mode': 'Clash Squad'},
            {'id_mode': 2, 'nama_mode': 'Battle Royale'},
            {'id_mode': 3, 'nama_mode': 'Ranked BR'},
            {'id_mode': 4, 'nama_mode': 'Solo Vs Squad'},
          ];
        });
      } else {
        setState(() => _modes = List<Map<String, dynamic>>.from(response));
      }
    } catch (e) {
      setState(() {
        _modes = [
          {'id_mode': 1, 'nama_mode': 'Clash Squad'},
          {'id_mode': 2, 'nama_mode': 'Battle Royale'},
          {'id_mode': 3, 'nama_mode': 'Ranked BR'},
          {'id_mode': 4, 'nama_mode': 'Solo Vs Squad'},
        ];
      });
    } finally {
      setState(() => _isLoadingModes = false);
    }
  }

  Future<void> _pickPoster() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() => _newPosterPath = image.path);
    }
  }

  Future<String?> _uploadPoster() async {
    if (_newPosterPath == null) return _posterUrl;
    
    final file = File(_newPosterPath!);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'posters/$fileName';
    
    await _supabase.storage.from('posters').upload(path, file);
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

    setState(() => _isLoading = true);

    try {
      final posterUrl = await _uploadPoster();
      final biaya = int.tryParse(_biayaController.text) ?? 0;
      final maksPeserta = int.tryParse(_maksPesertaController.text) ?? 16;
      final totalHadiah = (biaya * maksPeserta) * 85 ~/ 100;

      await _supabase.from('scrim').update({
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
      }).eq('id_scrim', widget.scrimId);

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
    final totalHadiah = totalPendaftaran * 85 ~/ 100;
    final feePlatform = totalPendaftaran * 5 ~/ 100;
    final feeAdmin = totalPendaftaran * 10 ~/ 100;

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
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildSection('IDENTITAS UTAMA', [
                      _buildTextField('NAMA SCRIM', _namaScrimController, hint: 'Contoh: Ultimate Pro League S3'),
                      const SizedBox(height: 16),
                      _buildDropdown(),
                      const SizedBox(height: 16),
                      _buildUploadPoster(),
                      const SizedBox(height: 16),
                      _buildStatusDropdown(),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('KONTEN', [
                      _buildTextField('DESKRIPSI SCRIM', _deskripsiController, maxLines: 4, hint: 'Jelaskan mengenai format dan tujuan turnamen...'),
                      const SizedBox(height: 16),
                      _buildTextField('SYARAT & KETENTUAN', _syaratController, maxLines: 5, hint: '1. Dilarang menggunakan emulator\n2. Dilarang cheat\n3. Harus tepat waktu...'),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('KEUANGAN & PESERTA', [
                      _buildTextField('BIAYA PENDAFTARAN', _biayaController, hint: '50000', keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
                      const SizedBox(height: 16),
                      _buildTextField('MAKS PESERTA', _maksPesertaController, hint: '16', keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
                      const SizedBox(height: 16),
                      _buildTextField('JUMLAH MATCH', _jumlahMatchController, hint: '3', keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      _buildTotalHadiahInfo(totalPendaftaran, totalHadiah, feePlatform, feeAdmin),
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
                                width: 24, height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : Text('SIMPAN PERUBAHAN', style: AppTextStyles.poppinsButton),
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
        Text(title, style: AppTextStyles.poppinsTitleSmall.copyWith(color: AppColors.primary, fontSize: 14)),
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

  Widget _buildTextField(String label, TextEditingController controller, {String? hint, int maxLines = 1, TextInputType? keyboardType, Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.interLabel.copyWith(color: AppColors.textSecondary)),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (v) => v == null || v.isEmpty ? '$label wajib diisi' : null,
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    if (_isLoadingModes) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MODE PERTANDINGAN', style: AppTextStyles.interLabel.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                const SizedBox(width: 12),
                Text('Memuat mode pertandingan...', style: AppTextStyles.interHint),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MODE PERTANDINGAN', style: AppTextStyles.interLabel.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          value: _selectedModeId,
          dropdownColor: AppColors.backgroundCard,
          style: AppTextStyles.interInput,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        Text('STATUS SCRIM', style: AppTextStyles.interLabel.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _statusScrim,
          dropdownColor: AppColors.backgroundCard,
          style: AppTextStyles.interInput,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: ['aktif', 'selesai', 'dibatalkan'].map((status) {
            String label;
            switch (status) {
              case 'aktif': label = 'AKTIF'; break;
              case 'selesai': label = 'SELESAI'; break;
              case 'dibatalkan': label = 'DIBATALKAN'; break;
              default: label = status.toUpperCase();
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
        Text('MEDIA POSTER', style: AppTextStyles.interLabel.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickPoster,
          child: Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _newPosterPath != null || _posterUrl != null ? AppColors.primary : AppColors.inputBorder),
            ),
            child: _newPosterPath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(_newPosterPath!), fit: BoxFit.cover, width: double.infinity),
                  )
                : _posterUrl != null && _posterUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _posterUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => _uploadPlaceholder(),
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
        Text('GANTI POSTER', style: AppTextStyles.interLabel.copyWith(color: AppColors.primary)),
        const SizedBox(height: 4),
        Text('Klik untuk mengganti poster', style: AppTextStyles.interCaption.copyWith(color: AppColors.textHint)),
      ],
    );
  }

  Widget _buildTotalHadiahInfo(int totalPendaftaran, int totalHadiah, int feePlatform, int feeAdmin) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total Pendaftaran', style: AppTextStyles.interBody),
            Text(_formatRupiah(totalPendaftaran), style: AppTextStyles.poppinsMoney.copyWith(fontSize: 14)),
          ]),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Fee Platform (5%)', style: AppTextStyles.interBody),
            Text('- ${_formatRupiah(feePlatform)}', style: AppTextStyles.interBody.copyWith(color: AppColors.error)),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Fee Admin (10%)', style: AppTextStyles.interBody),
            Text('- ${_formatRupiah(feeAdmin)}', style: AppTextStyles.interBody.copyWith(color: AppColors.error)),
          ]),
          const Divider(height: 16, color: AppColors.divider),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('TOTAL HADIAH (85%)', style: AppTextStyles.goldHighlight),
            Text(_formatRupiah(totalHadiah), style: AppTextStyles.poppinsMoneyLarge.copyWith(fontSize: 18)),
          ]),
        ],
      ),
    );
  }
}