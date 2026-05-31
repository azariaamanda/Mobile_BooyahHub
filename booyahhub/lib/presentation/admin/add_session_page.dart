import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

class AddSessionPage extends StatefulWidget {
  final int scrimId;
  const AddSessionPage({super.key, required this.scrimId});

  @override
  State<AddSessionPage> createState() => _AddSessionPageState();
}

class _AddSessionPageState extends State<AddSessionPage> {
  final _supabase = Supabase.instance.client;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 0);
  int _slot = 12;
  bool _isLoading = false;

  Future<void> _saveSession() async {
    setState(() => _isLoading = true);
    try {
      final startDateTime = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        _startTime.hour, _startTime.minute,
      );
      final endDateTime = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        _endTime.hour, _endTime.minute,
      );
      
      await _supabase.from('sesi_scrim').insert({
        'id_scrim': widget.scrimId,
        'nama_sesi': 'Sesi Baru',
        'waktu_mulai': startDateTime.toIso8601String(),
        'waktu_selesai': endDateTime.toIso8601String(),
        'slot_maksimal': _slot,
      });
      
      if (mounted) context.pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Edit Sesi', style: AppTextStyles.poppinsTitle),
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WAKTU SESI', style: AppTextStyles.interLabel.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _timePickerField('MULAI', _startTime, (t) => setState(() => _startTime = t)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _timePickerField('SELESAI', _endTime, (t) => setState(() => _endTime = t)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _datePickerField(),
                  const SizedBox(height: 16),
                  _slotField(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSession,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('SIMPAN PERUBAHAN', style: AppTextStyles.poppinsButton),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.pop(),
                child: Text('BATAL', style: AppTextStyles.poppinsButton.copyWith(color: AppColors.primary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timePickerField(String label, TimeOfDay time, Function(TimeOfDay) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.interLabel),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final picked = await showTimePicker(context: context, initialTime: time);
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
                const SizedBox(width: 8),
                Text(time.format(context), style: AppTextStyles.interInput),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _datePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TANGGAL', style: AppTextStyles.interLabel),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(_formatDate(_selectedDate), style: AppTextStyles.interInput),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _slotField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('KAPASITAS', style: AppTextStyles.interLabel),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: AppColors.primary),
                onPressed: () => setState(() => _slot = (_slot > 1 ? _slot - 1 : 1)),
              ),
              Expanded(
                child: Text(
                  '$_slot Tim',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.poppinsTitleSmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.primary),
                onPressed: () => setState(() => _slot = (_slot < 50 ? _slot + 1 : 50)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) => '${d.day} ${_getMonth(d.month)} ${d.year}';
  String _getMonth(int m) => ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'][m - 1];
}