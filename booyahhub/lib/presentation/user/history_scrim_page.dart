import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../config/app_session.dart';
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
  String? _selectedMonthFilter;

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
        .channel('public:history_scrim_changes')
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
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sesi_scrim',
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

  String _getStatusPertandinganValue(
    dynamic waktuMulai,
    dynamic waktuSelesai,
  ) {
    if (waktuMulai == null || waktuSelesai == null) {
      return 'belum_mulai';
    }

    final now = DateTime.now();
    final mulai = DateTime.parse(waktuMulai.toString()).toLocal();
    final selesai = DateTime.parse(waktuSelesai.toString()).toLocal();

    if (now.isBefore(mulai)) {
      return 'belum_mulai';
    } else if (now.isAfter(selesai)) {
      return 'selesai';
    } else {
      return 'sedang_berlangsung';
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'sedang_berlangsung':
        return 'Berlangsung';
      case 'selesai':
        return 'Selesai';
      case 'belum_mulai':
      default:
        return 'Belum Mulai';
    }
  }

  Color _getStatusDotColor(String status) {
    switch (status) {
      case 'sedang_berlangsung':
        return Colors.orange;
      case 'selesai':
        return Colors.green;
      case 'belum_mulai':
      default:
        return Colors.blue;
    }
  }

  Future<void> _syncStatusPertandinganByPendaftaran(
    int idPendaftaran,
    String statusValue,
  ) async {
    try {
      await Supabase.instance.client
          .from('pendaftaran_tim')
          .update({'status_pertandingan': statusValue})
          .eq('id_pendaftaran', idPendaftaran);
    } catch (e) {
      debugPrint('Gagal sync status history: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchHistoryScrim() async {
    try {
      final supabase = Supabase.instance.client;

      final userEmail = supabase.sessionEmail;

      if (userEmail == null) {
        throw 'User belum login, silakan login ulang.';
      }

      final response = await supabase
          .from('pendaftaran_tim')
          .select('''
            id_pendaftaran,
            dibuat_pada,
            status_pertandingan,
            akun!pendaftaran_tim_akun_id_fkey!inner(email),
            sesi_scrim!pendaftaran_tim_id_sesi_fkey(
              waktu_mulai,
              waktu_selesai,
              scrim!sesi_scrim_id_scrim_fkey(
                nama_scrim,
                poster
              )
            ),
            hasil_pertandingan(*)
          ''')
          .eq('akun.email', userEmail)
          .order('dibuat_pada', ascending: false);

      final List<Map<String, dynamic>> loadedHistory = [];

      for (final item in response) {
        final int idPendaftaran = item['id_pendaftaran'];

        final List hasilList = item['hasil_pertandingan'] ?? [];

        final Map? sesiScrimData = item['sesi_scrim'] as Map?;
        final Map? scrimData = sesiScrimData?['scrim'] as Map?;

        final String statusPertandingan = _getStatusPertandinganValue(
          sesiScrimData?['waktu_mulai'],
          sesiScrimData?['waktu_selesai'],
        );

        await _syncStatusPertandinganByPendaftaran(
          idPendaftaran,
          statusPertandingan,
        );

        final String namaScrimAsli =
            scrimData?['nama_scrim'] ?? 'Scrim Match #$idPendaftaran';

        final String? posterUrl = scrimData?['poster'];

        bool hasRank = false;
        String badgeText = 'BELUM MULAI';
        String peringkatInfo = '';

        if (statusPertandingan == 'selesai') {
          if (hasilList.isNotEmpty) {
            hasRank = true;

            final int placement = hasilList[0]['placement'] ?? 0;

            peringkatInfo = 'Peringkat $placement';

            if (placement == 1) {
              badgeText = 'JUARA 1';
            } else if (placement == 2) {
              badgeText = 'JUARA 2';
            } else if (placement == 3) {
              badgeText = 'JUARA 3';
            } else if (placement > 0) {
              badgeText = 'RANK $placement';
            } else {
              badgeText = 'SELESAI';
            }
          } else {
            badgeText = 'SELESAI';
          }
        } else if (statusPertandingan == 'sedang_berlangsung') {
          badgeText = 'LIVE MATCH';
        } else {
          badgeText = 'BELUM MULAI';
        }

        final DateTime dateParsed =
            DateTime.parse(item['dibuat_pada'].toString()).toLocal();

        final String formattedDate = DateFormat('dd MMM yyyy').format(dateParsed);
        final String formattedTime = '${DateFormat('HH:mm').format(dateParsed)} WIB';

        final String monthKey = DateFormat('MM-yyyy').format(dateParsed);
        final String monthLabel = DateFormat('MMMM yyyy').format(dateParsed);

        loadedHistory.add({
          'id_scrim': idPendaftaran,
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
      debugPrint('Error ambil riwayat scrim: $e');
      rethrow;
    }
  }

  Widget _buildStatusChip(
    String label,
    String value,
  ) {
    final bool isSelected = _selectedStatusFilter == value;

    return GestureDetector(
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
            color:
                isSelected ? AppColors.buttonText : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Riwayat Scrim',
          style: AppTextStyles.poppinsTitle.copyWith(
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingM,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppConstants.paddingS),

              FutureBuilder<List<Map<String, dynamic>>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  final List<Map<String, String>> uniqueMonths = [];
                  final Set<String> seenMonths = {};

                  if (snapshot.hasData) {
                    for (final item in snapshot.data!) {
                      final key = item['month_key'] as String;
                      final label = item['month_label'] as String;

                      if (!seenMonths.contains(key)) {
                        seenMonths.add(key);
                        uniqueMonths.add({
                          'key': key,
                          'label': label,
                        });
                      }
                    }
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusM,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        dropdownColor: AppColors.backgroundCard,
                        value: _selectedMonthFilter,
                        hint: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_month,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Semua Bulan',
                              style: AppTextStyles.interBodyMedium.copyWith(
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.textSecondary,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'Semua Bulan',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          ...uniqueMonths.map((month) {
                            return DropdownMenuItem<String?>(
                              value: month['key'],
                              child: Text(
                                month['label']!,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
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

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: _buildStatusChip(
                        'All Scrims',
                        'all',
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingS),
                    SizedBox(
                      width: 120,
                      child: _buildStatusChip(
                        'Belum Mulai',
                        'belum_mulai',
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingS),
                    SizedBox(
                      width: 130,
                      child: _buildStatusChip(
                        'Berlangsung',
                        'sedang_berlangsung',
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingS),
                    SizedBox(
                      width: 120,
                      child: _buildStatusChip(
                        'Selesai',
                        'selesai',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.paddingL),

              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _historyFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Gagal memuat data: ${snapshot.error}',
                          style: AppTextStyles.interBody.copyWith(
                            color: Colors.redAccent,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final allHistory = snapshot.data ?? [];

                    var filteredList = allHistory.where((item) {
                      if (_selectedStatusFilter == 'all') return true;
                      return item['status'] == _selectedStatusFilter;
                    }).toList();

                    if (_selectedMonthFilter != null) {
                      filteredList = filteredList.where((item) {
                        return item['month_key'] == _selectedMonthFilter;
                      }).toList();
                    }

                    if (filteredList.isEmpty) {
                      return Center(
                        child: Text(
                          'Tidak ada riwayat pada kategori / bulan ini.',
                          style: AppTextStyles.interBody,
                          textAlign: TextAlign.center,
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

                          final bool isJuara1 =
                              history['badge_text'] == 'JUARA 1';

                          return GestureDetector(
                            onTap: () {
                              context.push(
                                '/user/history-detail',
                                extra: history['id_scrim'],
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(
                                bottom: AppConstants.paddingM,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundCard,
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusL,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(
                                      AppConstants.paddingM,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 65,
                                          height: 65,
                                          decoration: BoxDecoration(
                                            color: Colors.black26,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            image:
                                                history['poster_scrim'] == null
                                                    ? null
                                                    : DecorationImage(
                                                        image: NetworkImage(
                                                          history[
                                                              'poster_scrim'],
                                                        ),
                                                        fit: BoxFit.cover,
                                                      ),
                                          ),
                                          child: history['poster_scrim'] == null
                                              ? const Icon(
                                                  Icons.sports_esports,
                                                  color: Colors.grey,
                                                  size: 30,
                                                )
                                              : null,
                                        ),

                                        const SizedBox(
                                          width: AppConstants.paddingM,
                                        ),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                history['nama_scrim'],
                                                style: AppTextStyles
                                                    .poppinsSectionTitle
                                                    .copyWith(
                                                  fontSize: 16,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                history['tanggal'],
                                                style: AppTextStyles
                                                    .interBodyMedium
                                                    .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              Text(
                                                history['jam'],
                                                style: AppTextStyles
                                                    .interBodyMedium
                                                    .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isJuara1
                                                    ? AppColors.primary
                                                    : Colors.white24,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  AppConstants.radiusM,
                                                ),
                                              ),
                                              child: Text(
                                                history['badge_text'],
                                                style: TextStyle(
                                                  color: isJuara1
                                                      ? AppColors.buttonText
                                                      : Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 12),

                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: _getStatusDotColor(
                                                      history['status'],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  _getStatusLabel(
                                                    history['status'],
                                                  ),
                                                  style: const TextStyle(
                                                    color: AppColors
                                                        .textSecondary,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  if (history['has_rank']) ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppConstants.paddingM,
                                      ),
                                      child: Divider(
                                        color: AppColors.inputBorder,
                                        thickness: 1,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppConstants.paddingM,
                                        vertical: AppConstants.paddingS,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.keyboard_double_arrow_up,
                                                color:
                                                    AppColors.textSecondary,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                history['peringkat_info'],
                                                style: const TextStyle(
                                                  color:
                                                      AppColors.textPrimary,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            color: AppColors.textSecondary,
                                            size: 14,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
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
}