import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; 

import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

class HistoryScrimPage extends StatefulWidget {
  const HistoryScrimPage({super.key});

  @override
  State<HistoryScrimPage> createState() => _HistoryScrimPageState();
}

class _HistoryScrimPageState extends State<HistoryScrimPage> {
  String _selectedStatusFilter = 'all'; 
  String? _selectedMonthFilter; // Format: "MM-yyyy" (Contoh: "06-2026")
  Future<List<Map<String, dynamic>>>? _historyFuture;
  RealtimeChannel? _scrimRealtimeChannel;

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchHistoryScrim();
    _listenToScrimChanges(); 
  }

  @override
  void dispose() {
    if (_scrimRealtimeChannel != null) {
      Supabase.instance.client.removeChannel(_scrimRealtimeChannel!);
    }
    super.dispose();
  }

  void _listenToScrimChanges() {
    final supabase = Supabase.instance.client;

    if (_scrimRealtimeChannel != null) {
      supabase.removeChannel(_scrimRealtimeChannel!);
    }

    _scrimRealtimeChannel = supabase
        .channel('public:pendaftaran_tim_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'pendaftaran_tim',
          callback: (payload) async {
            await Future.delayed(const Duration(milliseconds: 300));
            if (mounted) {
              setState(() {
                _historyFuture = _fetchHistoryScrim();
              });
            }
          },
        );

    _scrimRealtimeChannel?.subscribe();
  }

  Future<List<Map<String, dynamic>>> _fetchHistoryScrim() async {
    try {
      final supabase = Supabase.instance.client;
      final userEmail = supabase.auth.currentUser?.email;

      if (userEmail == null) {
        throw 'User belum login bray, silakan login dulu.';
      }

      final response = await supabase
          .from('pendaftaran_tim')
          .select('''
            id_pendaftaran,
            dibuat_pada, 
            status_pertandingan,
            akun!inner(email),
            sesi_scrim(
              scrim(
                nama_scrim,
                poster
              )
            ),
            hasil_pertandingan(peringkat, total_poin)
          ''')
          .eq('akun.email', userEmail)
          .order('dibuat_pada', ascending: false);

      List<Map<String, dynamic>> loadedHistory = [];

      for (var item in response) {
        final String statusPertandingan = item['status_pertandingan'] ?? 'belum_mulai';
        final List<dynamic> hasilList = item['hasil_pertandingan'] ?? [];
        
        final Map<String, dynamic>? sesiScrimData = item['sesi_scrim'] as Map<String, dynamic>?;
        final Map<String, dynamic>? scrimData = sesiScrimData?['scrim'] as Map<String, dynamic>?;
        
        final String namaScrimAsli = scrimData?['nama_scrim'] ?? 'Scrim Match #${item['id_pendaftaran']}';
        final String? posterUrl = scrimData?['poster']; 

        bool hasRank = false;
        String badgeText = 'BELUM MULAI';
        String peringkatInfo = '';

        if (statusPertandingan == 'selesai') {
          if (hasilList.isNotEmpty) {
            hasRank = true;
            final int peringkat = hasilList[0]['peringkat'] ?? 0;
            peringkatInfo = 'Peringkat $peringkat';
            if (peringkat == 1) badgeText = 'JUARA 1';
            else if (peringkat == 2) badgeText = 'JUARA 2';
            else if (peringkat == 3) badgeText = 'JUARA 3';
            else badgeText = 'RANK $peringkat';
          } else {
            badgeText = 'SELESAI';
          }
        } else if (statusPertandingan == 'sedang_berlangsung') {
          badgeText = 'LIVE MATCH';
        } else if (statusPertandingan == 'dibatalkan') {
          badgeText = 'CANCELLED';
        } else {
          badgeText = 'BELUM MULAI';
        }

        DateTime dateParsed = DateTime.parse(item['dibuat_pada']);
        String formattedDate = DateFormat('dd MMM yyyy').format(dateParsed);
        String formattedTime = '${DateFormat('HH:mm').format(dateParsed)} WIB';
        
        // Key unik untuk filter bulan (cth: "06-2026") dan label display (cth: "Juni 2026")
        String monthKey = DateFormat('MM-yyyy').format(dateParsed);
        String monthLabel = DateFormat('MMMM yyyy').format(dateParsed);

        loadedHistory.add({
          'id_scrim': item['id_pendaftaran'],
          'nama_scrim': namaScrimAsli,
          'poster_scrim': posterUrl, 
          'tanggal': formattedDate,
          'jam': formattedTime,
          'status': statusPertandingan,
          'badge_text': badgeText,
          'peringkat_info': peringkatInfo,
          'has_rank': hasRank,
          'month_key': monthKey,
          'month_label': monthLabel,
        });
      }

      return loadedHistory;
    } catch (e) {
      print('Eror ambil riwayat bray: $e');
      rethrow;
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
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Riwayat Scrim',
          style: AppTextStyles.poppinsTitle.copyWith(fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppConstants.paddingS),

              // Filter Dropdown Bulan Berdasarkan Data yang Tersedia
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  // Kumpulin list bulan unik dari data snapshot
                  final List<Map<String, String>> uniqueMonths = [];
                  final Set<String> seenMonths = {};

                  if (snapshot.hasData) {
                    for (var item in snapshot.data!) {
                      final key = item['month_key'] as String;
                      final label = item['month_label'] as String;
                      if (!seenMonths.contains(key)) {
                        seenMonths.add(key);
                        uniqueMonths.add({'key': key, 'label': label});
                      }
                    }
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: AppColors.backgroundCard,
                        value: _selectedMonthFilter,
                        hint: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_month, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text('Semua Bulan', style: AppTextStyles.interBodyMedium.copyWith(fontSize: 13)),
                          ],
                        ),
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                        items: [
                          // Opsi buat reset filter kembali ke semua bulan
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text('Semua Bulan', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                          ),
                          ...uniqueMonths.map((month) {
                            return DropdownMenuItem<String>(
                              value: month['key'],
                              child: Text(
                                month['label']!,
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedMonthFilter = value;
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppConstants.paddingL),

              // Chip Status Pertandingan (All, Selesai, Dibatalkan)
              Row(
                children: [
                  _buildStatusChip('All Scrims', 'all'),
                  const SizedBox(width: AppConstants.paddingS),
                  _buildStatusChip('Selesai', 'selesai'),
                  const SizedBox(width: AppConstants.paddingS),
                  _buildStatusChip('Dibatalkan', 'dibatalkan'),
                ],
              ),
              const SizedBox(height: AppConstants.paddingL),

              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _historyFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Gagal memuat data: ${snapshot.error}',
                          style: AppTextStyles.interBody.copyWith(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final allHistory = snapshot.data ?? [];

                    // 1. Filter Berdasarkan Status
                    var filteredList = allHistory.where((item) {
                      if (_selectedStatusFilter == 'all') return true;
                      return item['status'] == _selectedStatusFilter;
                    }).toList();

                    // 2. Filter Berdasarkan Bulan (Bila Dipilih)
                    if (_selectedMonthFilter != null) {
                      filteredList = filteredList.where((item) {
                        return item['month_key'] == _selectedMonthFilter;
                      }).toList();
                    }

                    if (filteredList.isEmpty) {
                      return Center(
                        child: Text(
                          'Tidak ada riwayat pada kategori / bulan ini bray.',
                          style: AppTextStyles.interBody,
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        setState(() {
                          _historyFuture = _fetchHistoryScrim();
                        });
                      },
                      child: ListView.builder(
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final history = filteredList[index];
                          final bool isCancelled = history['status'] == 'dibatalkan';
                          final bool isJuara1 = history['badge_text'] == 'JUARA 1';

                          return GestureDetector(
                            onTap: () {
                              context.push('/user/history-detail', extra: history['id_scrim']);   
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundCard,
                                borderRadius: BorderRadius.circular(AppConstants.radiusL),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(AppConstants.paddingM),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 65,
                                          height: 65,
                                          decoration: BoxDecoration(
                                            color: isCancelled ? Colors.grey.shade800 : Colors.black26,
                                            borderRadius: BorderRadius.circular(20),
                                            image: isCancelled || history['poster_scrim'] == null
                                                ? null
                                                : DecorationImage(
                                                    image: NetworkImage(history['poster_scrim']), 
                                                    fit: BoxFit.cover,
                                                    onError: (exception, stackTrace) {
                                                      print('Gagal muat gambar poster bray');
                                                    },
                                                  ),
                                          ),
                                          child: isCancelled
                                              ? const Icon(Icons.cancel_outlined, color: Colors.grey, size: 30)
                                              : (history['poster_scrim'] == null
                                                  ? const Icon(Icons.sports_esports, color: Colors.grey, size: 30) 
                                                  : null),
                                        ),
                                        const SizedBox(width: AppConstants.paddingM),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                history['nama_scrim'],
                                                style: AppTextStyles.poppinsSectionTitle.copyWith(fontSize: 16),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                history['tanggal'],
                                                style: AppTextStyles.interBodyMedium.copyWith(color: AppColors.textSecondary, fontSize: 13),
                                              ),
                                              Text(
                                                history['jam'],
                                                style: AppTextStyles.interBodyMedium.copyWith(color: AppColors.textSecondary, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: isCancelled
                                                    ? const Color(0xFF4A2829)
                                                    : (isJuara1 ? AppColors.primary : Colors.white24),
                                                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                                              ),
                                              child: Text(
                                                history['badge_text'],
                                                style: TextStyle(
                                                  color: isCancelled
                                                      ? Colors.redAccent
                                                      : (isJuara1 ? AppColors.buttonText : Colors.white),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: history['status'] == 'selesai'
                                                        ? Colors.green
                                                        : history['status'] == 'sedang_berlangsung'
                                                            ? Colors.orange
                                                            : history['status'] == 'dibatalkan'
                                                                ? Colors.red
                                                                : Colors.blue, 
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  history['status'] == 'selesai'
                                                      ? 'Selesai'
                                                      : history['status'] == 'sedang_berlangsung'
                                                          ? 'Berlangsung'
                                                          : history['status'] == 'dibatalkan'
                                                              ? 'Dibatalkan'
                                                              : 'Belum Mulai',
                                                  style: const TextStyle(
                                                    color: AppColors.textSecondary,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (history['has_rank']) ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
                                      child: Divider(color: AppColors.inputBorder, thickness: 1),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppConstants.paddingM,
                                        vertical: AppConstants.paddingS,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.keyboard_double_arrow_up, color: AppColors.textSecondary, size: 18),
                                              const SizedBox(width: 8),
                                              Text(
                                                history['peringkat_info'],
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 14),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value) {
    final bool isSelected = _selectedStatusFilter == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedStatusFilter = value;
          });
        },
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.buttonText : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}