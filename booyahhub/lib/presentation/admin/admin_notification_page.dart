import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

class AdminNotificationPage extends StatefulWidget {
  const AdminNotificationPage({super.key});

  @override
  State<AdminNotificationPage> createState() => _AdminNotificationPageState();
}

class _AdminNotificationPageState extends State<AdminNotificationPage> {
  String _targetPenerima = 'Semua User';
  late TextEditingController _judulController;
  late TextEditingController _pesanController;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _judulController = TextEditingController();
    _pesanController = TextEditingController();
  }

  @override
  void dispose() {
    _judulController.dispose();
    _pesanController.dispose();
    super.dispose();
  }

  void _reset() {
    _judulController.clear();
    _pesanController.clear();
  }

  // Mapping dropdown → target_role di tabel notifikasi
  static const _roleMap = {
    'Semua User': 'pengguna',
    'Admin': 'admin',
    'Owner': 'owner',
    'Peserta': 'pengguna',
  };

  Future<void> _kirimNotifikasi() async {
    final judul = _judulController.text.trim();
    final pesan = _pesanController.text.trim();
    if (judul.isEmpty || pesan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan pesan tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await Supabase.instance.client.from('notifikasi').insert({
        'tipe': 'manual',
        'judul': judul,
        'pesan': pesan,
        'target_role': _roleMap[_targetPenerima] ?? 'pengguna',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notifikasi dikirim ke $_targetPenerima')),
      );
      _reset();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim notifikasi: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        ),
        title: Text(
          'Notifikasi',
          style: AppTextStyles.poppinsTitleSmall.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // ===== FORM KIRIM NOTIFIKASI =====
          _buildSectionTitle('FORM KIRIM NOTIFIKASI'),
          const SizedBox(height: 12),

          // Target Penerima Dropdown
          _buildLabel('TARGET PENERIMA'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundInput,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _targetPenerima,
                isExpanded: true,
                dropdownColor: AppColors.surface,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.primary,
                ),
                style: AppTextStyles.interInput,
                items: ['Semua User', 'Admin', 'Owner', 'Peserta']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _targetPenerima = v);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Judul Field
          _buildLabel('JUDUL'),
          const SizedBox(height: 8),
          TextField(
            controller: _judulController,
            style: AppTextStyles.interInput,
            decoration: InputDecoration(
              hintText: 'Masukkan judul notifikasi...',
              hintStyle: AppTextStyles.interInput.copyWith(
                color: AppColors.textDisabled,
              ),
              filled: true,
              fillColor: AppColors.backgroundInput,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Pesan Field
          _buildLabel('PESAN'),
          const SizedBox(height: 8),
          TextField(
            controller: _pesanController,
            style: AppTextStyles.interInput,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tulis detail pengumuman di sini...',
              hintStyle: AppTextStyles.interInput.copyWith(
                color: AppColors.textDisabled,
              ),
              filled: true,
              fillColor: AppColors.backgroundInput,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _reset,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.divider),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  icon: const Icon(
                    Icons.refresh,
                    color: AppColors.textSecondary,
                  ),
                  label: Text(
                    'Reset',
                    style: AppTextStyles.poppinsButton.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _kirimNotifikasi,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  icon: const Icon(Icons.send, color: AppColors.buttonText),
                  label: Text(
                    'Kirim Sekarang',
                    style: AppTextStyles.poppinsButton.copyWith(
                      color: AppColors.buttonText,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ===== PREVIEW NOTIFIKASI =====
          _buildSectionTitle('PREVIEW NOTIFIKASI'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _judulController.text.isEmpty
                            ? 'Pengingat Scrim'
                            : _judulController.text,
                        style: AppTextStyles.poppinsTitleSmall.copyWith(
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _pesanController.text.isEmpty
                            ? 'Ini adalah preview notifikasi Anda'
                            : _pesanController.text,
                        style: AppTextStyles.interCaption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ===== RIWAYAT PENGIRIMAN =====
          _buildSectionTitle('RIWAYAT PENGIRIMAN'),
          const SizedBox(height: 12),
          ..._buildHistoryList(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Icon(Icons.info_outline, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppTextStyles.interCaption.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.interCaption.copyWith(
        color: AppColors.textHint,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  List<Widget> _buildHistoryList() {
    final historyItems = [
      {
        'icon': Icons.calendar_today_outlined,
        'title': 'Update Jadwal Match',
        'subtitle': 'SEMUA USER',
        'date': '20 Mei 2026 pukul 10:30',
        'description':
            'Halo Elite Gamers! Jadwal pertandingan bulan Mei telah dimulai jam lebih awal untuk menghindarkan jadwal',
      },
      {
        'icon': Icons.card_giftcard_outlined,
        'title': 'Promo Premium',
        'subtitle': 'USER PREMIUM',
        'date': '19 Mei 2026 pukul 08:00',
        'description':
            'Diskon khusus 50% untuk bergabung premium bulan ini! Gunakan kode PREMIUMO sekarang...',
      },
    ];

    return historyItems
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              style: AppTextStyles.poppinsTitleSmall.copyWith(
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['subtitle'] as String,
                              style: AppTextStyles.interCaption.copyWith(
                                color: AppColors.textHint,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['date'] as String,
                              style: AppTextStyles.interCaption.copyWith(
                                color: AppColors.textDisabled,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item['description'] as String,
                    style: AppTextStyles.interCaption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.divider),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          label: Text(
                            'Edit & Kirim Ulang',
                            style: AppTextStyles.interCaption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 14,
                            color: AppColors.buttonText,
                          ),
                          label: Text(
                            'Hapus',
                            style: AppTextStyles.interCaption.copyWith(
                              color: AppColors.buttonText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
        .toList();
  }
}
