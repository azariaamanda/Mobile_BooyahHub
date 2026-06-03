import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';

class ScrimSessionsPage extends StatefulWidget {
  final int scrimId;
  const ScrimSessionsPage({super.key, required this.scrimId});

  @override
  State<ScrimSessionsPage> createState() => _ScrimSessionsPageState();
}

class _ScrimSessionsPageState extends State<ScrimSessionsPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _allSessions = [];
  List<Map<String, dynamic>> _filteredSessions = [];
  Map<String, dynamic>? _scrim;

  DateTime _selectedDate = DateTime.now();
  List<DateTime> _availableDates = [];
  Set<DateTime> _existingDates = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final scrimData = await _supabase
          .from('scrim')
          .select('nama_scrim')
          .eq('id_scrim', widget.scrimId)
          .single();
      _scrim = scrimData;

      final sesiData = await _supabase
          .from('sesi_scrim')
          .select('*')
          .eq('id_scrim', widget.scrimId)
          .order('waktu_mulai', ascending: true);
      _allSessions = List<Map<String, dynamic>>.from(sesiData);

      _availableDates =
          _allSessions
              .map((s) => DateTime.parse(s['waktu_mulai']).toLocal())
              .map((d) => DateTime(d.year, d.month, d.day))
              .toSet()
              .toList()
            ..sort();

      if (_availableDates.isNotEmpty) {
        _selectedDate = _availableDates.first;
        _filterSessions();
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterSessions() {
    _filteredSessions = _allSessions.where((s) {
      final date = DateTime.parse(s['waktu_mulai']).toLocal();
      return date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;
    }).toList();
    setState(() {});
  }

  // ==================== POPUP ATUR JADWAL (Tanpa Jam & Kapasitas) ====================
  Future<void> _showAddSchedulePopup() async {
    DateTime _currentMonth = DateTime.now();
    Set<DateTime> _selectedDates = {};
    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 9, minute: 0);
    int slot = 12;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            backgroundColor: AppColors.backgroundCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width - 40,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Atur Jadwal',
                    style: AppTextStyles.poppinsHeadline.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'HARI BARU UNTUK SCRIM',
                    style: AppTextStyles.interLabel.copyWith(
                      color: AppColors.primary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pilih tanggal pelaksanaan untuk sesi baru.',
                    style: AppTextStyles.interCaption,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pastikan tidak bentrok dengan jadwal yang sudah ada.',
                    style: AppTextStyles.interCaption.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 16),

                  // Month selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            _currentMonth = DateTime(
                              _currentMonth.year,
                              _currentMonth.month - 1,
                            );
                          });
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_getMonth(_currentMonth.month)} ${_currentMonth.year}',
                        style: AppTextStyles.poppinsTitleSmall,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            _currentMonth = DateTime(
                              _currentMonth.year,
                              _currentMonth.month + 1,
                            );
                          });
                        },
                      ),
                    ],
                  ),

                  // Calendar grid
                  _buildCalendarGrid(_currentMonth, _selectedDates, (date) {
                    setDialogState(() {
                      if (_selectedDates.contains(date)) {
                        _selectedDates.remove(date);
                      } else {
                        _selectedDates.add(date);
                      }
                    });
                  }),

                  const SizedBox(height: 16),

                  // Selected dates summary
                  if (_selectedDates.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_selectedDates.length} tanggal dipilih',
                        style: AppTextStyles.interLabel.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Time and slot picker
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimePicker('MULAI', startTime, (time) {
                          setDialogState(() => startTime = time);
                        }),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimePicker('SELESAI', endTime, (time) {
                          setDialogState(() => endTime = time);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSlotPicker(slot, (value) {
                    setDialogState(() => slot = value);
                  }),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.divider),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'BATAL',
                            style: AppTextStyles.poppinsButton.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            for (var date in _selectedDates) {
                              final startDateTime = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                startTime.hour,
                                startTime.minute,
                              );
                              final endDateTime = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                endTime.hour,
                                endTime.minute,
                              );
                              await _supabase.from('sesi_scrim').insert({
                                'id_scrim': widget.scrimId,
                                'nama_sesi': 'Sesi ${_allSessions.length + 1}',
                                'waktu_mulai': startDateTime.toIso8601String(),
                                'waktu_selesai': endDateTime.toIso8601String(),
                                'slot_maksimal': slot,
                              });
                            }
                            Navigator.pop(ctx);
                            _fetchData();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'SIMPAN',
                            style: AppTextStyles.poppinsButton,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendarGrid(
    DateTime month,
    Set<DateTime> selectedDates,
    Function(DateTime) onDateTap,
  ) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstDayOfWeek = DateTime(month.year, month.month, 1).weekday % 7;
    final today = DateTime.now();

    return GridView.builder(
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
        final date = DateTime(month.year, month.month, day);
        final isSelected = selectedDates.contains(date);
        final hasExisting = _existingDates.contains(date);
        final bgColor = isSelected ? AppColors.primary : null;
        final isToday =
            date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;

        return GestureDetector(
          onTap: () => onDateTap(date),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor ?? Colors.transparent,
              shape: BoxShape.circle,
              border: isToday
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              day.toString(),
              style: AppTextStyles.interBody.copyWith(
                color: isSelected
                    ? Colors.black
                    : (hasExisting ? AppColors.primary : AppColors.textPrimary),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimePicker(
    String label,
    TimeOfDay time,
    Function(TimeOfDay) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.interLabel.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: time,
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
            if (picked != null) onChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(time.format(context), style: AppTextStyles.interInput),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlotPicker(int slot, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KAPASITAS',
          style: AppTextStyles.interLabel.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: AppColors.primary),
                onPressed: () => onChanged(slot > 1 ? slot - 1 : 1),
              ),
              Expanded(
                child: Text(
                  '$slot Tim',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.poppinsTitleSmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.primary),
                onPressed: () => onChanged(slot < 50 ? slot + 1 : 50),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== POPUP EDIT SESI ====================
  Future<void> _showEditSessionPopup(Map<String, dynamic> session) async {
    final currentDate = DateTime.parse(session['waktu_mulai']).toLocal();
    TimeOfDay startTime = TimeOfDay(
      hour: currentDate.hour,
      minute: currentDate.minute,
    );
    final endDateTime = DateTime.parse(session['waktu_selesai']).toLocal();
    TimeOfDay endTime = TimeOfDay(
      hour: endDateTime.hour,
      minute: endDateTime.minute,
    );
    int slot = session['slot_maksimal'] ?? 12;

    final pesertaData = await _supabase
        .from('pendaftaran_tim')
        .select('id_pendaftaran')
        .eq('id_sesi', session['id_sesi'])
        .eq('status_pembayaran', 'dikonfirmasi');
    final currentParticipants = pesertaData.length;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            backgroundColor: AppColors.backgroundCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width - 40,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Edit Sesi',
                    style: AppTextStyles.poppinsHeadline.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'EDIT SESI UNTUK SCRIM',
                    style: AppTextStyles.interLabel.copyWith(
                      color: AppColors.primary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTimePicker('MULAI', startTime, (time) {
                          setDialogState(() => startTime = time);
                        }),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimePicker('SELESAI', endTime, (time) {
                          setDialogState(() => endTime = time);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildSlotPicker(slot, (value) {
                    setDialogState(() => slot = value);
                  }),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'KAPASITAS SAAT INI',
                          style: AppTextStyles.interLabel,
                        ),
                        Text(
                          '$currentParticipants/$slot Tim',
                          style: AppTextStyles.poppinsMoneySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mengubah waktu akan memberitahu peserta yang sudah terdaftar.',
                    style: AppTextStyles.interCaption.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.divider),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'BATAL',
                            style: AppTextStyles.poppinsButton.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final startDateTime = DateTime(
                              currentDate.year,
                              currentDate.month,
                              currentDate.day,
                              startTime.hour,
                              startTime.minute,
                            );
                            final endDateTime = DateTime(
                              currentDate.year,
                              currentDate.month,
                              currentDate.day,
                              endTime.hour,
                              endTime.minute,
                            );
                            await _supabase
                                .from('sesi_scrim')
                                .update({
                                  'waktu_mulai': startDateTime
                                      .toIso8601String(),
                                  'waktu_selesai': endDateTime
                                      .toIso8601String(),
                                  'slot_maksimal': slot,
                                })
                                .eq('id_sesi', session['id_sesi']);
                            Navigator.pop(ctx);
                            _fetchData();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'SIMPAN',
                            style: AppTextStyles.poppinsButton,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteSession(int sesiId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Sesi', style: AppTextStyles.poppinsTitle),
        content: Text(
          'Yakin ingin menghapus sesi ini?',
          style: AppTextStyles.interBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: AppTextStyles.interLink),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hapus', style: AppTextStyles.poppinsButton),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _supabase.from('sesi_scrim').delete().eq('id_sesi', sesiId);
      _fetchData();
    }
  }

  String _formatDate(DateTime d) => '${d.day} ${_getMonth(d.month)} ${d.year}';
  String _getMonth(int m) => [
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
  ][m - 1];
  String _formatTime(String? s) {
    if (s == null) return '-';
    final d = DateTime.parse(s);
    return '${d.hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')}';
  }

  Future<int> _getSlotTerisi(int sesiId) async {
    try {
      final pesertaData = await _supabase
          .from('pendaftaran_tim')
          .select('id_pendaftaran')
          .eq('id_sesi', sesiId)
          .eq('status_pembayaran', 'dikonfirmasi');
      return pesertaData.length;
    } catch (e) {
      return 0;
    }
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_availableDates.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceVariant),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<DateTime>(
                  value: _selectedDate,
                  isExpanded: true,
                  dropdownColor: AppColors.backgroundCard,
                  style: AppTextStyles.interInput,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.primary,
                  ),
                  items: _availableDates.map((date) {
                    return DropdownMenuItem(
                      value: date,
                      child: Text(
                        _formatDate(date),
                        style: AppTextStyles.interInput,
                      ),
                    );
                  }).toList(),
                  onChanged: (date) {
                    setState(() {
                      _selectedDate = date!;
                      _filterSessions();
                    });
                  },
                ),
              ),
            ),

          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _showAddSchedulePopup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: Text('ATUR JADWAL', style: AppTextStyles.poppinsButton),
              ),
            ),
          ),

          Expanded(
            child: _filteredSessions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.schedule_outlined,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada sesi untuk tanggal ini',
                          style: AppTextStyles.interBody,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredSessions.length,
                    itemBuilder: (context, i) {
                      final sesi = _filteredSessions[i];
                      final slotMaks = sesi['slot_maksimal'] ?? 12;
                      final slotTerisi = _getSlotTerisi(sesi['id_sesi']);
                      final sisaSlot = slotMaks - slotTerisi;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.surfaceVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Baris 1: Waktu (kiri) + Tombol Edit/Hapus (kanan)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Waktu
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_formatTime(sesi['waktu_mulai'])} - ${_formatTime(sesi['waktu_selesai'])}',
                                      style: AppTextStyles.poppinsTitleSmall
                                          .copyWith(fontSize: 14),
                                    ),
                                  ],
                                ),
                                // Edit & Delete buttons
                                Row(
                                  children: [
                                    _actionButton(
                                      Icons.edit,
                                      AppColors.primary,
                                      () => _showEditSessionPopup(sesi),
                                    ),
                                    const SizedBox(width: 8),
                                    _actionButton(
                                      Icons.delete,
                                      AppColors.error,
                                      () => _deleteSession(sesi['id_sesi']),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Baris 2: Slot info
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SLOT TERISI',
                                      style: AppTextStyles.interLabel.copyWith(
                                        fontSize: 10,
                                      ),
                                    ),
                                    Text(
                                      '$slotTerisi/$slotMaks Tim',
                                      style: AppTextStyles.poppinsMoneySmall
                                          .copyWith(fontSize: 18),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: sisaSlot > 0
                                        ? AppColors.primary.withOpacity(0.15)
                                        : AppColors.error.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    sisaSlot > 0
                                        ? '$sisaSlot Slot Tersisa'
                                        : 'Penuh',
                                    style: AppTextStyles.interCaption.copyWith(
                                      color: sisaSlot > 0
                                          ? AppColors.primary
                                          : AppColors.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // // Baris 3: Room ID (jika ada)
                            // if (sesi['room_id'] != null && sesi['room_id'].toString().isNotEmpty) ...[
                            //   const SizedBox(height: 12),
                            //   Container(
                            //     padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            //     decoration: BoxDecoration(
                            //       color: AppColors.inputFill,
                            //       borderRadius: BorderRadius.circular(8),
                            //     ),
                            //     child: Row(
                            //       children: [
                            //         Icon(Icons.meeting_room, size: 14, color: AppColors.primary),
                            //         const SizedBox(width: 8),
                            //         Expanded(
                            //           child: Text(
                            //             'Room ID: ${sesi['room_id']}',
                            //             style: AppTextStyles.interCaption.copyWith(color: AppColors.textPrimary),
                            //           ),
                            //         ),
                            //       ],
                            //     ),
                            //   ),
                            // ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
