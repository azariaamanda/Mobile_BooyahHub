import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../config/supabase_client.dart';
import '../../data/models/sesi_scrim_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_session.dart';

class BookingScrimPage extends StatefulWidget {
  final int scrimId;

  const BookingScrimPage({
    super.key,
    required this.scrimId,
  });

  @override
  State<BookingScrimPage> createState() => _BookingScrimPageState();
}

class _BookingScrimPageState extends State<BookingScrimPage> {
  bool _isLoading = true;
  String? _namaScrim;

  Map<String, List<SesiScrimModel>> _sesiPerTanggal = {};
  Set<String> _tanggalAktif = {};
  SesiScrimModel? _selectedSlot;

  DateTime _focusedMonth = DateTime.now();
  String? _selectedDateString;

  Set<int> _sesiSudahDaftar = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  bool _isSesiMasihBisaDaftar(DateTime waktuMulai) {
    final now = DateTime.now();
    return now.isBefore(waktuMulai);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final scrimResp = await SupabaseClientHelper.client
          .from('scrim')
          .select('nama_scrim')
          .eq('id_scrim', widget.scrimId)
          .single();

      _namaScrim = scrimResp['nama_scrim'] ?? 'Booking Scrim';

      final sesiResp = await SupabaseClientHelper.client
          .from('sesi_scrim')
          .select()
          .eq('id_scrim', widget.scrimId)
          .order('waktu_mulai', ascending: true);

      final supabase = Supabase.instance.client;
      final email = supabase.sessionEmail;

      Set<int> sesiSudahDaftar = {};

      if (email != null) {
        final akunResp = await supabase
            .from('akun')
            .select('id_akun')
            .eq('email', email)
            .maybeSingle();

        if (akunResp != null) {
          final int akunId = akunResp['id_akun'];

          final daftarResp = await supabase
              .from('pendaftaran_tim')
              .select('id_sesi')
              .eq('akun_id', akunId)
              .neq('status_pembayaran', 'ditolak');

          sesiSudahDaftar = (daftarResp as List)
              .map((e) => e['id_sesi'] as int)
              .toSet();
        }
      }

      final pendResp = await SupabaseClientHelper.client
          .from('pendaftaran_tim')
          .select('id_sesi')
          .eq('status_pembayaran', 'dikonfirmasi');

      final Map<int, int> terisiMap = {};

      for (final row in pendResp as List) {
        final id = row['id_sesi'] as int;
        terisiMap[id] = (terisiMap[id] ?? 0) + 1;
      }

      final Map<String, List<SesiScrimModel>> grouped = {};

      for (final row in sesiResp as List) {
        final mulai = DateTime.parse(row['waktu_mulai'].toString()).toLocal();
        final selesai =
            DateTime.parse(row['waktu_selesai'].toString()).toLocal();

        if (!_isSesiMasihBisaDaftar(mulai)) {
          continue;
        }

        final keyString =
            '${mulai.year}-${mulai.month.toString().padLeft(2, '0')}-${mulai.day.toString().padLeft(2, '0')}';

        final idSesi = (row['id_sesi'] ?? row['id']) as int;
        final slotMaks = (row['slot_maksimal'] ?? 12) as int;
        final slotTerisi = terisiMap[idSesi] ?? 0;

        grouped.putIfAbsent(keyString, () => []).add(
              SesiScrimModel(
                idSesi: idSesi,
                idScrim: widget.scrimId,
                namaSesi: row['nama_sesi'] ?? '',
                waktuMulai: mulai,
                waktuSelesai: selesai,
                slotMaksimal: slotMaks,
                slotTerisi: slotTerisi,
              ),
            );
      }

      if (!mounted) return;

      setState(() {
        _sesiPerTanggal = grouped;
        _tanggalAktif = grouped.keys.toSet();
        _sesiSudahDaftar = sesiSudahDaftar;
        _selectedSlot = null;

        if (_tanggalAktif.isNotEmpty) {
          final sorted = _tanggalAktif.toList()..sort();
          _selectedDateString = sorted.first;

          final parsedFirst = DateTime.parse(_selectedDateString!);
          _focusedMonth = DateTime(parsedFirst.year, parsedFirst.month);
        } else {
          final skrg = DateTime.now();
          _selectedDateString =
              '${skrg.year}-${skrg.month.toString().padLeft(2, '0')}-${skrg.day.toString().padLeft(2, '0')}';
        }

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      debugPrint('❌ ERROR CRITICAL: $e');
    }
  }

  List<SesiScrimModel> get _slotsForSelected {
    if (_selectedDateString == null) return [];

    final slots = _sesiPerTanggal[_selectedDateString!] ?? [];

    return slots.where((slot) {
      return _isSesiMasihBisaDaftar(slot.waktuMulai);
    }).toList();
  }

  String _formatJam(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatSlotLabel(SesiScrimModel s) {
    return '${_formatJam(s.waktuMulai)} - ${_formatJam(s.waktuSelesai)}';
  }

  static const List<String> _hariHeader = [
    'M',
    'S',
    'S',
    'R',
    'K',
    'J',
    'S',
  ];

  static const List<String> _namaBulan = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppConstants.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCalendar(),
                        const SizedBox(height: AppConstants.paddingM),
                        if (_slotsForSelected.isNotEmpty) ...[
                          Text(
                            'Pilih Sesi Jam Tersedia',
                            style: AppTextStyles.poppinsTitleSmall.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppConstants.paddingS),
                          _buildSlotGrid(),
                          const SizedBox(height: AppConstants.paddingM),
                        ] else ...[
                          _buildEmptySlot(),
                          const SizedBox(height: AppConstants.paddingM),
                        ],
                        if (_selectedSlot != null) _buildSelectedInfo(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
        _namaScrim ?? 'Booking Scrim',
        style: AppTextStyles.poppinsTitle,
      ),
      centerTitle: false,
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      padding: const EdgeInsets.all(AppConstants.paddingM),
      child: Column(
        children: [
          _buildMonthHeader(),
          const SizedBox(height: AppConstants.paddingM),
          _buildDayHeaders(),
          const SizedBox(height: AppConstants.paddingS),
          _buildDayGrid(),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: AppColors.background,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              '${_namaBulan[_focusedMonth.month - 1]} ${_focusedMonth.year}',
              style: AppTextStyles.poppinsTitleSmall.copyWith(
                color: AppColors.background,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _navButton(Icons.chevron_left, () {
              setState(() {
                _focusedMonth = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month - 1,
                );
              });
            }),
            const SizedBox(width: 4),
            _navButton(Icons.chevron_right, () {
              setState(() {
                _focusedMonth = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month + 1,
                );
              });
            }),
          ],
        ),
      ],
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppColors.background,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildDayHeaders() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _hariHeader
          .map(
            (h) => SizedBox(
              width: 32,
              child: Text(
                h,
                textAlign: TextAlign.center,
                style: AppTextStyles.interCaption.copyWith(
                  color: AppColors.background.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDayGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);

    int offset = firstDay.weekday - 1;

    if (offset < 0) offset = 6;

    final totalCells = offset + lastDay.day;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (col) {
            final cellIndex = row * 7 + col;
            final dayNumber = cellIndex - offset + 1;

            if (dayNumber < 1 || dayNumber > lastDay.day) {
              return const SizedBox(
                width: 32,
                height: 36,
              );
            }

            final dateObj = DateTime(
              _focusedMonth.year,
              _focusedMonth.month,
              dayNumber,
            );

            final dateStr =
                '${dateObj.year}-${dateObj.month.toString().padLeft(2, '0')}-${dateObj.day.toString().padLeft(2, '0')}';

            final hasSlot = _tanggalAktif.contains(dateStr);
            final isSelected = _selectedDateString == dateStr;

            return _buildDayCell(
              dateStr,
              dayNumber,
              hasSlot,
              isSelected,
            );
          }),
        );
      }),
    );
  }

  Widget _buildDayCell(
    String dateStr,
    int day,
    bool hasSlot,
    bool isSelected,
  ) {
    Color bg;
    Color textColor;

    if (isSelected) {
      bg = AppColors.background;
      textColor = AppColors.primary;
    } else if (hasSlot) {
      bg = AppColors.background.withOpacity(0.25);
      textColor = AppColors.background;
    } else {
      bg = Colors.transparent;
      textColor = AppColors.background.withOpacity(0.4);
    }

    return GestureDetector(
      onTap: hasSlot
          ? () {
              setState(() {
                _selectedDateString = dateStr;
                _selectedSlot = null;
              });
            }
          : null,
      child: Container(
        width: 32,
        height: 36,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: AppTextStyles.interBodyMedium.copyWith(
            color: textColor,
            fontWeight: (isSelected || hasSlot)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSlotGrid() {
    final slots = _slotsForSelected;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppConstants.paddingS,
        crossAxisSpacing: AppConstants.paddingS,
        childAspectRatio: 2.4,
      ),
      itemCount: slots.length,
      itemBuilder: (_, i) => _buildSlotChip(slots[i]),
    );
  }

  Widget _buildSlotChip(SesiScrimModel slot) {
    final isSelected = _selectedSlot?.idSesi == slot.idSesi;
    final isFull = slot.isFull;
    final sudahDaftar = _sesiSudahDaftar.contains(slot.idSesi);

    final isDisabled =
        isFull || sudahDaftar || !_isSesiMasihBisaDaftar(slot.waktuMulai);

    Color bg;
    Color borderColor;
    Color textColor;

    if (sudahDaftar) {
      bg = AppColors.primary.withOpacity(0.08);
      borderColor = AppColors.primary.withOpacity(0.4);
      textColor = AppColors.primary.withOpacity(0.6);
    } else if (isFull) {
      bg = AppColors.accentRed.withOpacity(0.15);
      borderColor = AppColors.accentRed;
      textColor = AppColors.accentRed;
    } else if (isSelected) {
      bg = AppColors.primary.withOpacity(0.2);
      borderColor = AppColors.primary;
      textColor = AppColors.primary;
    } else {
      bg = AppColors.surface;
      borderColor = AppColors.inputBorder;
      textColor = AppColors.textSecondary;
    }

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              setState(() {
                _selectedSlot = isSelected ? null : slot;
              });
            },
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
          border: Border.all(
            color: borderColor,
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatSlotLabel(slot),
              style: AppTextStyles.interCaption.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (sudahDaftar)
              Text(
                'Sudah Daftar',
                style: AppTextStyles.interCaption.copyWith(
                  color: AppColors.primary.withOpacity(0.7),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              )
            else if (isFull)
              Text(
                'Penuh',
                style: AppTextStyles.interCaption.copyWith(
                  color: AppColors.accentRed,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySlot() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_busy,
            color: AppColors.textHint,
            size: 36,
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ada sesi tersedia\npada tanggal ini',
            style: AppTextStyles.interBody,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedInfo() {
    final s = _selectedSlot!;
    final parsed = DateTime.parse(_selectedDateString!);
    final tanggal = '${parsed.day} ${_namaBulan[parsed.month - 1]}';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingS + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Slot dipilih: $tanggal, ${_formatSlotLabel(s)}',
              style: AppTextStyles.interBodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '${s.sisaSlot}/${s.slotMaksimal} slot',
            style: AppTextStyles.interCaption.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final canNext = _selectedSlot != null &&
        !_selectedSlot!.isFull &&
        _isSesiMasihBisaDaftar(_selectedSlot!.waktuMulai);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.paddingM,
          AppConstants.paddingS,
          AppConstants.paddingM,
          AppConstants.paddingM,
        ),
        child: SizedBox(
          width: double.infinity,
          height: AppConstants.buttonHeight,
          child: ElevatedButton(
            onPressed: canNext
                ? () {
                    if (_selectedSlot == null) return;

                    if (!_isSesiMasihBisaDaftar(_selectedSlot!.waktuMulai)) {
                      setState(() {
                        _selectedSlot = null;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Sesi sudah dimulai, silakan pilih sesi lain.',
                          ),
                        ),
                      );

                      return;
                    }

                    context.push('/user/booking/${_selectedSlot!.idSesi}');
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
              disabledBackgroundColor: AppColors.buttonPrimaryDisabled,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
            ),
            child: Text(
              'Selanjutnya',
              style: AppTextStyles.poppinsButton,
            ),
          ),
        ),
      ),
    );
  }
}