import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_session.dart';
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
  Uint8List? _posterBytes;
  bool _isLoading = false;
  bool _isLoadingModes = true;
  List<Map<String, dynamic>> _modes = [];
  
  // Fee settings from database
  int _feePlatformPersen = 25;
  int _nominalMinimumPlatform = 5000;
  int _feeAdminPersen = 10;
  int _feeAdminTetap = 10000;
  bool _isPersentaseAdmin = true;
  bool _isLoadingFee = true;
  
  // Calendar state
  DateTime _currentMonth = DateTime.now();
  Set<DateTime> _selectedDates = {};
  
  // Sesi per tanggal
  Map<DateTime, List<Map<String, dynamic>>> _sessionsPerDate = {};
  
  // Default time per sesi
  TimeOfDay _defaultStartTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _defaultEndTime = const TimeOfDay(hour: 9, minute: 0);
  int _jumlahSesiPerTanggal = 1;

  @override
  void initState() {
    super.initState();
    _fetchModes();
    _fetchFeeSettings();
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

  // ==================== FEE SETTINGS ====================
  Future<void> _fetchFeeSettings() async {
    setState(() => _isLoadingFee = true);
    try {
      final feeSetting = await _supabase
          .from('pengaturan_fee')
          .select()
          .maybeSingle();
      
      if (feeSetting != null) {
        _feePlatformPersen = feeSetting['fee_platform_persen'] ?? 25;
        _nominalMinimumPlatform = feeSetting['nominal_minimum_platform'] ?? 5000;
        _feeAdminPersen = feeSetting['fee_admin_persen'] ?? 10;
        _feeAdminTetap = feeSetting['fee_admin_tetap'] ?? 10000;
        _isPersentaseAdmin = feeSetting['is_persentase_admin'] ?? true;
      }
    } catch (e) {
      print('Error fetch fee settings: $e');
    } finally {
      setState(() => _isLoadingFee = false);
    }
  }

  // ==================== UPDATE SESI DARI TANGGAL TERPILIH ====================
  void _updateSessionsFromDates() {
    final Map<DateTime, List<Map<String, dynamic>>> newSessions = {};
    
    for (var date in _selectedDates) {
      List<Map<String, dynamic>> sessionsForDate = [];
      for (int i = 0; i < _jumlahSesiPerTanggal; i++) {
        sessionsForDate.add({
          'nama': 'Sesi ${i + 1}',
          'tanggal': date,
          'waktuMulai': _defaultStartTime,
          'waktuSelesai': _defaultEndTime,
        });
      }
      newSessions[date] = sessionsForDate;
    }
    
    setState(() {
      _sessionsPerDate = newSessions;
    });
  }

  void _updateJumlahSesiPerTanggal(int value) {
    setState(() {
      _jumlahSesiPerTanggal = value;
      _updateSessionsFromDates();
    });
  }

  void _toggleDateSelection(DateTime date) {
    setState(() {
      if (_selectedDates.contains(date)) {
        _selectedDates.remove(date);
        _sessionsPerDate.remove(date);
      } else {
        _selectedDates.add(date);
        List<Map<String, dynamic>> sessionsForDate = [];
        for (int i = 0; i < _jumlahSesiPerTanggal; i++) {
          sessionsForDate.add({
            'nama': 'Sesi ${i + 1}',
            'tanggal': date,
            'waktuMulai': _defaultStartTime,
            'waktuSelesai': _defaultEndTime,
          });
        }
        _sessionsPerDate[date] = sessionsForDate;
      }
    });
  }

  void _selectAllDatesInMonth() {
    setState(() {
      final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(_currentMonth.year, _currentMonth.month, day);
        if (date.isAfter(DateTime.now()) || date.isAtSameMomentAs(DateTime.now())) {
          if (!_selectedDates.contains(date)) {
            _selectedDates.add(date);
          }
        }
      }
      _updateSessionsFromDates();
    });
  }

  void _clearSelectedDates() {
    setState(() {
      _selectedDates.clear();
      _sessionsPerDate.clear();
    });
  }

  // ==================== MANUAL SESSION ====================
  void _addManualSessionForDate(DateTime date) {
    setState(() {
      final currentSessions = _sessionsPerDate[date] ?? [];
      final newSession = {
        'nama': 'Sesi ${currentSessions.length + 1}',
        'tanggal': date,
        'waktuMulai': _defaultStartTime,
        'waktuSelesai': _defaultEndTime,
      };
      _sessionsPerDate[date] = [...currentSessions, newSession];
    });
  }

  void _removeSessionFromDate(DateTime date, int sessionIndex) {
    setState(() {
      final currentSessions = _sessionsPerDate[date] ?? [];
      currentSessions.removeAt(sessionIndex);
      for (int i = 0; i < currentSessions.length; i++) {
        currentSessions[i]['nama'] = 'Sesi ${i + 1}';
      }
      _sessionsPerDate[date] = currentSessions;
      if (currentSessions.isEmpty) {
        _sessionsPerDate.remove(date);
        _selectedDates.remove(date);
      }
    });
  }

  Future<void> _selectDateForSession(DateTime date, int sessionIndex) async {
    final session = _sessionsPerDate[date]?[sessionIndex];
    if (session == null) return;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: session['tanggal'] as DateTime,
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
        final oldDate = date;
        final newDate = picked;
        
        session['tanggal'] = newDate;
        
        if (!oldDate.isAtSameMomentAs(newDate)) {
          final oldSessions = _sessionsPerDate[oldDate];
          if (oldSessions != null) {
            oldSessions.removeAt(sessionIndex);
            if (oldSessions.isEmpty) {
              _sessionsPerDate.remove(oldDate);
              _selectedDates.remove(oldDate);
            } else {
              for (int i = 0; i < oldSessions.length; i++) {
                oldSessions[i]['nama'] = 'Sesi ${i + 1}';
              }
            }
          }
          
          if (!_selectedDates.contains(newDate)) {
            _selectedDates.add(newDate);
          }
          
          final List<Map<String, dynamic>> newSessions = List.from(_sessionsPerDate[newDate] ?? []);
          newSessions.add(session);
          newSessions.sort((a, b) {
            final aNum = int.tryParse(a['nama'].toString().replaceAll('Sesi ', '')) ?? 0;
            final bNum = int.tryParse(b['nama'].toString().replaceAll('Sesi ', '')) ?? 0;
            return aNum.compareTo(bNum);
          });
          for (int i = 0; i < newSessions.length; i++) {
            newSessions[i]['nama'] = 'Sesi ${i + 1}';
          }
          _sessionsPerDate[newDate] = newSessions;
        }
      });
    }
  }

  Future<void> _selectTimeForSession(DateTime date, int sessionIndex, bool isStart) async {
    final session = _sessionsPerDate[date]?[sessionIndex];
    if (session == null) return;
    
    final initialTime = isStart 
        ? (session['waktuMulai'] as TimeOfDay)
        : (session['waktuSelesai'] as TimeOfDay);
    
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
          session['waktuMulai'] = picked;
        } else {
          session['waktuSelesai'] = picked;
        }
      });
    }
  }

  // ==================== FETCH MODES ====================
  Future<void> _fetchModes() async {
    setState(() => _isLoadingModes = true);
    try {
      final response = await _supabase
          .from('master_mode_pertandingan')
          .select('id_mode, nama_mode')
          .order('id_mode', ascending: true);

      setState(() {
        _modes = List<Map<String, dynamic>>.from(response);
        if (_modes.isNotEmpty) {
          _selectedModeId = _modes.first['id_mode'] as int;
        }
      });
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

  // ==================== POSTER ====================
  Future<void> _pickPoster() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _posterBytes = bytes);
    }
  }

  Future<String?> _uploadPoster() async {
    if (_posterBytes == null) return null;

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'posters/$fileName';

    await _supabase.storage.from('posters').uploadBinary(path, _posterBytes!);
    return _supabase.storage.from('posters').getPublicUrl(path);
  }

  // ==================== SUBMIT ====================
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedModeId == null) {
      _showSnackBar('Pilih mode pertandingan', isError: true);
      return;
    }
    if (_sessionsPerDate.isEmpty) {
      _showSnackBar('Minimal 1 tanggal dipilih', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final adminEmail = _supabase.sessionEmail;
      if (adminEmail == null) throw Exception('User tidak ditemukan');
      
      final adminData = await _supabase
          .from('akun')
          .select('id_akun')
          .eq('email', adminEmail)
          .maybeSingle();
      
      if (adminData == null) throw Exception('Admin tidak ditemukan');
      final adminId = adminData['id_akun'] as int;

      String? posterUrl = await _uploadPoster();

      final biaya = int.tryParse(_biayaController.text) ?? 0;
      final maksPeserta = int.tryParse(_maksPesertaController.text) ?? 16;
      final totalPendaftaran = biaya * maksPeserta;
      
      // Gunakan fee dari database dengan logika lengkap
      int feePlatform = totalPendaftaran * _feePlatformPersen ~/ 100;
      if (feePlatform < _nominalMinimumPlatform) feePlatform = _nominalMinimumPlatform;
      
      int feeAdmin = _isPersentaseAdmin 
          ? (totalPendaftaran * _feeAdminPersen ~/ 100)
          : _feeAdminTetap;
          
      final totalHadiah = totalPendaftaran - (feePlatform + feeAdmin);
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

      for (var entry in _sessionsPerDate.entries) {
        final sessions = entry.value;
        for (final session in sessions) {
          final tanggal = session['tanggal'] as DateTime;
          final startTime = session['waktuMulai'] as TimeOfDay;
          final endTime = session['waktuSelesai'] as TimeOfDay;
          
          final start = DateTime(
            tanggal.year, tanggal.month, tanggal.day,
            startTime.hour, startTime.minute,
          );
          final end = DateTime(
            tanggal.year, tanggal.month, tanggal.day,
            endTime.hour, endTime.minute,
          );
          
          await _supabase.from('sesi_scrim').insert({
            'id_scrim': scrimId,
            'nama_sesi': session['nama'],
            'waktu_mulai': start.toIso8601String(),
            'waktu_selesai': end.toIso8601String(),
            'slot_maksimal': maksPeserta,
          });
        }
      }

      _showSnackBar('Scrim berhasil dibuat!');
      if (mounted) context.go('/admin/dashboard');
    } catch (e) {
      _showSnackBar('Gagal: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==================== UTILS ====================
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
        title: Text('Buat Scrim Baru', style: AppTextStyles.poppinsTitle),
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.go('/admin/dashboard'),
        ),
      ),
      body: _isLoadingFee
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
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
                      _buildJumlahSesiPicker(),
                      const SizedBox(height: 16),
                      _buildCalendarPicker(),
                      const SizedBox(height: 16),
                      if (_selectedDates.isNotEmpty)
                        _buildQuickActions(),
                      const SizedBox(height: 16),
                      _buildSessionsList(),
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

  Widget _buildJumlahSesiPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('JUMLAH SESI PER TANGGAL', style: AppTextStyles.interLabel.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove, color: AppColors.primary),
              onPressed: () {
                if (_jumlahSesiPerTanggal > 1) {
                  _updateJumlahSesiPerTanggal(_jumlahSesiPerTanggal - 1);
                }
              },
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '$_jumlahSesiPerTanggal Sesi',
                    style: AppTextStyles.poppinsTitleSmall,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.primary),
              onPressed: () {
                if (_jumlahSesiPerTanggal < 10) {
                  _updateJumlahSesiPerTanggal(_jumlahSesiPerTanggal + 1);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Setiap tanggal yang dipilih akan memiliki $_jumlahSesiPerTanggal sesi (Sesi 1, Sesi 2, ...)',
          style: AppTextStyles.interCaption.copyWith(color: AppColors.textHint),
        ),
      ],
    );
  }

  Widget _buildCalendarPicker() {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfWeek = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;
    final today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: AppColors.primary),
              onPressed: () {
                setState(() {
                  _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                });
              },
            ),
            Text(
              '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
              style: AppTextStyles.poppinsTitleSmall,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: AppColors.primary),
              onPressed: () {
                setState(() {
                  _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['MIN', 'SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB'].map((day) => 
            Expanded(
              child: Center(
                child: Text(
                  day,
                  style: AppTextStyles.interCaption.copyWith(color: AppColors.textSecondary, fontSize: 11),
                ),
              ),
            )
          ).toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.2,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: 42,
          itemBuilder: (context, index) {
            final day = index - firstDayOfWeek + 1;
            if (day < 1 || day > daysInMonth) {
              return const SizedBox();
            }
            final date = DateTime(_currentMonth.year, _currentMonth.month, day);
            final isPast = date.isBefore(today) && !date.isAtSameMomentAs(today);
            final isSelected = _selectedDates.contains(date);
            
            return GestureDetector(
              onTap: isPast ? null : () => _toggleDateSelection(date),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: isSelected 
                      ? null 
                      : (date.isAtSameMomentAs(today) 
                          ? Border.all(color: AppColors.primary, width: 1.5) 
                          : null),
                ),
                child: Center(
                  child: Text(
                    day.toString(),
                    style: AppTextStyles.interBody.copyWith(
                      color: isSelected 
                          ? Colors.black 
                          : (isPast ? AppColors.textHint : AppColors.textPrimary),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_selectedDates.length} tanggal dipilih',
                style: AppTextStyles.interLabel.copyWith(color: AppColors.primary),
              ),
              if (_selectedDates.isNotEmpty)
                TextButton(
                  onPressed: _clearSelectedDates,
                  child: Text('Hapus Semua', style: AppTextStyles.interLink.copyWith(fontSize: 11)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _selectAllDatesInMonth,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Pilih Semua Bulan Ini', style: AppTextStyles.interLabel.copyWith(color: AppColors.primary)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: _clearSelectedDates,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Hapus Semua', style: AppTextStyles.interLabel.copyWith(color: AppColors.error)),
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
              border: Border.all(color: _posterBytes != null ? AppColors.primary : AppColors.inputBorder),
            ),
            child: _posterBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(_posterBytes!, fit: BoxFit.cover, width: double.infinity),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                feePlatform == _nominalMinimumPlatform 
                    ? 'Fee Platform (Min. Rp${_nominalMinimumPlatform ~/ 1000}K)' 
                    : 'Fee Platform ($_feePlatformPersen%)', 
                style: AppTextStyles.interBody
              ),
              Text('- ${_formatRupiah(feePlatform)}', style: AppTextStyles.interBody.copyWith(color: AppColors.error)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isPersentaseAdmin ? 'Fee Admin ($_feeAdminPersen%)' : 'Fee Admin (Tetap)', 
                style: AppTextStyles.interBody
              ),
              Text('- ${_formatRupiah(feeAdmin)}', style: AppTextStyles.interBody.copyWith(color: AppColors.error)),
            ],
          ),
          const Divider(height: 16, color: AppColors.divider),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('TOTAL HADIAH', style: AppTextStyles.goldHighlight),
            Text(_formatRupiah(totalHadiah), style: AppTextStyles.poppinsMoneyLarge.copyWith(fontSize: 18)),
          ]),
        ],
      ),
    );
  }

  Widget _buildSessionsList() {
    if (_sessionsPerDate.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: Center(
          child: Text(
            'Belum ada tanggal dipilih. Pilih tanggal di kalender.',
            style: AppTextStyles.interBody.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final sortedDates = _sessionsPerDate.keys.toList()..sort();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DAFTAR SESI', style: AppTextStyles.interLabel.copyWith(color: AppColors.primary, letterSpacing: 1)),
        const SizedBox(height: 8),
        ...sortedDates.map((date) {
          final sessions = _sessionsPerDate[date] ?? [];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(date),
                            style: AppTextStyles.poppinsTitleSmall.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => _addManualSessionForDate(date),
                        child: Text('Tambah Sesi', style: AppTextStyles.interLink.copyWith(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
                ...sessions.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final session = entry.value;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: idx != sessions.length - 1
                          ? Border(bottom: BorderSide(color: AppColors.surfaceVariant))
                          : null,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(session['nama'] as String, style: AppTextStyles.poppinsTitleSmall)),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                              onPressed: () => _removeSessionFromDate(date, idx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectDateForSession(date, idx),
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
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectTimeForSession(date, idx, true),
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
                                onTap: () => _selectTimeForSession(date, idx, false),
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
              ],
            ),
          );
        }),
      ],
    );
  }
}