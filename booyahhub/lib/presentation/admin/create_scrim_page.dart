import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

class CreateScrimPage extends StatefulWidget {
  const CreateScrimPage({super.key});

  @override
  State<CreateScrimPage> createState() => _CreateScrimPageState();
}

class _CreateScrimPageState extends State<CreateScrimPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final _namaScrimController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _syaratController = TextEditingController();
  final _biayaController = TextEditingController();
  final _maksPesertaController = TextEditingController();
  final _jumlahMatchController = TextEditingController();

  // State
  int? _selectedModeId;
  String? _posterPath;
  bool _isLoading = false;
  bool _isLoadingModes = true;
  List<Map<String, dynamic>> _modes = [];
  
  // Tanggal mulai (default: hari ini + 7 hari)
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  
  // Dynamic session times
  List<Map<String, dynamic>> _sessions = [
    {
      'nama': 'Sesi 1', 
      'tanggal': DateTime.now().add(const Duration(days: 7)),
      'waktuMulai': const TimeOfDay(hour: 8, minute: 0), 
      'waktuSelesai': const TimeOfDay(hour: 9, minute: 0)
    }
  ];

  @override
  void initState() {
    super.initState();
    _fetchModes();
  }

  @override
  void dispose() {
    _namaScrimController.dispose();
    _deskripsiController.dispose();
    _syaratController.dispose();
    _biayaController.dispose();
    _maksPesertaController.dispose();
    _jumlahMatchController.dispose();
    super.dispose();
  }

  Future<void> _fetchModes() async {
    setState(() => _isLoadingModes = true);
    try {
      final response = await _supabase
          .from('master_mode_pertandingan')
          .select('id_mode, nama_mode')
          .order('id_mode', ascending: true);
      
      if (response.isEmpty) {
        // Hardcoded fallback
        setState(() {
          _modes = [
            {'id_mode': 1, 'nama_mode': 'Clash Squad'},
            {'id_mode': 2, 'nama_mode': 'Battle Royale'},
            {'id_mode': 3, 'nama_mode': 'Ranked BR'},
            {'id_mode': 4, 'nama_mode': 'Solo Vs Squad'},
          ];
          _selectedModeId = 1;
        });
      } else {
        setState(() {
          _modes = List<Map<String, dynamic>>.from(response);
          if (_modes.isNotEmpty) {
            _selectedModeId = _modes.first['id_mode'] as int;
          }
        });
      }
    } catch (e) {
      setState(() {
        _modes = [
          {'id_mode': 1, 'nama_mode': 'Clash Squad'},
          {'id_mode': 2, 'nama_mode': 'Battle Royale'},
          {'id_mode': 3, 'nama_mode': 'Ranked BR'},
          {'id_mode': 4, 'nama_mode': 'Solo Vs Squad'},
        ];
        _selectedModeId = 1;
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
      setState(() => _posterPath = image.path);
    }
  }

  Future<String?> _uploadPoster() async {
    if (_posterPath == null) return null;
    
    final file = File(_posterPath!);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'posters/$fileName';
    
    await _supabase.storage.from('posters').upload(path, file);
    return _supabase.storage.from('posters').getPublicUrl(path);
  }

  void _addSession() {
    setState(() {
      _sessions.add({
        'nama': 'Sesi ${_sessions.length + 1}',
        'tanggal': _startDate,
        'waktuMulai': const TimeOfDay(hour: 8, minute: 0),
        'waktuSelesai': const TimeOfDay(hour: 9, minute: 0),
      });
    });
  }

  void _removeSession(int index) {
    setState(() {
      _sessions.removeAt(index);
      for (int i = 0; i < _sessions.length; i++) {
        _sessions[i]['nama'] = 'Sesi ${i + 1}';
      }
    });
  }

  Future<void> _selectDate(int sessionIndex) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _sessions[sessionIndex]['tanggal'] as DateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.black,
              surface: AppColors.backgroundCard,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _sessions[sessionIndex]['tanggal'] = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart, int sessionIndex) async {
    final initialTime = isStart 
        ? (_sessions[sessionIndex]['waktuMulai'] as TimeOfDay)
        : (_sessions[sessionIndex]['waktuSelesai'] as TimeOfDay);
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.black,
              surface: AppColors.backgroundCard,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _sessions[sessionIndex]['waktuMulai'] = picked;
        } else {
          _sessions[sessionIndex]['waktuSelesai'] = picked;
        }
      });
    }
  }

  String _formatRupiah(int amount) {
    if (amount == 0) return 'Rp 0';
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[month - 1];
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedModeId == null) {
      _showSnackBar('Pilih mode pertandingan', isError: true);
      return;
    }
    if (_sessions.isEmpty) {
      _showSnackBar('Minimal 1 sesi', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final adminEmail = _supabase.auth.currentUser?.email;
      if (adminEmail == null) throw Exception('User tidak ditemukan');
      
      final adminData = await _supabase
          .from('akun')
          .select('id_akun')
          .eq('email', adminEmail)
          .maybeSingle();
      
      if (adminData == null) throw Exception('Admin tidak ditemukan');
      final adminId = adminData['id_akun'] as int;

      // Upload poster
      String? posterUrl = await _uploadPoster();

      // Insert scrim
      final biaya = int.tryParse(_biayaController.text) ?? 0;
      final maksPeserta = int.tryParse(_maksPesertaController.text) ?? 16;
      final totalHadiah = (biaya * maksPeserta) * 85 ~/ 100;
      final jumlahMatch = int.tryParse(_jumlahMatchController.text) ?? 3;

      final scrimResponse = await _supabase.from('scrim').insert({
        'id_admin': adminId,
        'id_mode': _selectedModeId,
        'nama_scrim': _namaScrimController.text,
        'biaya_pendaftaran': biaya,
        'total_hadiah': totalHadiah,
        'maks_peserta': maksPeserta,
        'jumlah_match': jumlahMatch,
        'deskripsi': _deskripsiController.text,
        'syarat_ketentuan': _syaratController.text,
        'poster': posterUrl,
        'status_scrim': 'aktif',
      }).select().single();

      final scrimId = scrimResponse['id_scrim'] as int;

      // Insert sessions
      for (int i = 0; i < _sessions.length; i++) {
        final session = _sessions[i];
        final tanggal = session['tanggal'] as DateTime;
        final startTime = session['waktuMulai'] as TimeOfDay;
        final endTime = session['waktuSelesai'] as TimeOfDay;
        
        final start = DateTime(
          tanggal.year,
          tanggal.month,
          tanggal.day,
          startTime.hour,
          startTime.minute,
        );
        final end = DateTime(
          tanggal.year,
          tanggal.month,
          tanggal.day,
          endTime.hour,
          endTime.minute,
        );
        
        await _supabase.from('sesi_scrim').insert({
          'id_scrim': scrimId,
          'nama_sesi': session['nama'],
          'waktu_mulai': start.toIso8601String(),
          'waktu_selesai': end.toIso8601String(),
          'slot_maksimal': maksPeserta,
        });
      }

      _showSnackBar('Scrim berhasil dibuat!');
      if (mounted) context.go('/admin/dashboard');
    } catch (e) {
      _showSnackBar('Gagal: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        title: Text('Buat Scrim Baru', style: AppTextStyles.poppinsTitle),
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.go('/admin/dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection('IDENTITAS UTAMA', [
                _buildTextField('NAMA SCRIM', _namaScrimController, hint: 'Contoh: Ultimate Pro League S3'),
                const SizedBox(height: 16),
                _buildDropdown(),
                const SizedBox(height: 16),
                _buildUploadPoster(),
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
              const SizedBox(height: 24),
              _buildSection('TANGGAL & SESI', [
                _buildJadwalMulai(),
                const SizedBox(height: 16),
                _buildSessions(),
                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: _addSession,
                    icon: const Icon(Icons.add, color: AppColors.primary),
                    label: Text('Tambah Sesi', style: AppTextStyles.interLink),
                  ),
                ),
              ]),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Text('SIMPAN', style: AppTextStyles.poppinsButton),
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

  Widget _buildJadwalMulai() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('JADWAL MULAI', style: AppTextStyles.interLabel.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _startDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.primary,
                      onPrimary: Colors.black,
                      surface: AppColors.backgroundCard,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                _startDate = picked;
                // Update semua sesi dengan tanggal baru
                for (int i = 0; i < _sessions.length; i++) {
                  _sessions[i]['tanggal'] = _startDate.add(Duration(days: i));
                }
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(_formatDate(_startDate), style: AppTextStyles.interInput),
                const Spacer(),
                Icon(Icons.arrow_drop_down, color: AppColors.primary),
              ],
            ),
          ),
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
              border: Border.all(color: _posterPath != null ? AppColors.primary : AppColors.inputBorder),
            ),
            child: _posterPath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(_posterPath!), fit: BoxFit.cover, width: double.infinity),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 32),
                      const SizedBox(height: 8),
                      Text('UPLOAD GAMBAR', style: AppTextStyles.interLabel.copyWith(color: AppColors.primary)),
                      const SizedBox(height: 4),
                      Text('Format: JPG, PNG (Max. 5MB)', style: AppTextStyles.interCaption.copyWith(color: AppColors.textHint)),
                    ],
                  ),
          ),
        ),
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

  Widget _buildSessions() {
    return Column(
      children: List.generate(_sessions.length, (index) {
        final session = _sessions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Text(session['nama'] as String, style: AppTextStyles.poppinsTitleSmall)),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    onPressed: _sessions.length > 1 ? () => _removeSession(index) : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Pilih Tanggal per sesi
              GestureDetector(
                onTap: () => _selectDate(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(_formatDate(session['tanggal'] as DateTime), style: AppTextStyles.interInput),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Pilih Jam Mulai dan Selesai
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(context, true, index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text((session['waktuMulai'] as TimeOfDay).format(context), style: AppTextStyles.interInput),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('-', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(context, false, index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text((session['waktuSelesai'] as TimeOfDay).format(context), style: AppTextStyles.interInput),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}