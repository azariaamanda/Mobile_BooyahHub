import 'dart:math' show min, max;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import 'admin_notification_page.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String _adminNama = '';
  String _adminInitials = '';
  int _bookingHariIni = 0;
  int _bookingKemarin = 0;
  int _verifikasiCount = 0;
  int _sisaSlot = 0;
  int _totalSlot = 0;
  double _pendapatanBulanIni = 0;
  double _pendapatanBulanLalu = 0;
  List<double> _trendData = List.filled(7, 0);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, min(2, name.length)).toUpperCase();
  }

  String _formatRupiah(double value) {
    if (value >= 1000000000) return 'Rp ${(value / 1000000000).toStringAsFixed(1)}B';
    if (value >= 1000000) return 'Rp ${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return 'Rp ${(value / 1000).toStringAsFixed(0)}K';
    return 'Rp ${value.toStringAsFixed(0)}';
  }

  String get _bookingBadge {
    if (_bookingKemarin == 0) return 'Hari ini';
    final pct = (_bookingHariIni - _bookingKemarin) / _bookingKemarin * 100;
    return '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}% Vs kemarin';
  }

  bool get _bookingUp => _bookingHariIni >= _bookingKemarin;

  String get _pendapatanBadge {
    if (_pendapatanBulanLalu == 0) return '-';
    final pct = (_pendapatanBulanIni - _pendapatanBulanLalu) / _pendapatanBulanLalu * 100;
    return '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%';
  }

  bool get _pendapatanUp => _pendapatanBulanIni >= _pendapatanBulanLalu;

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final email = _supabase.auth.currentUser?.email;
      if (email == null) return;

      // Admin info
      final akun = await _supabase
          .from('akun')
          .select('id_akun')
          .eq('email', email)
          .single();
      final adminId = akun['id_akun'] as int;

      final profil = await _supabase
          .from('profil_admin')
          .select('nama_lengkap')
          .eq('akun_id', adminId)
          .maybeSingle();
      final nama = profil?['nama_lengkap'] as String? ?? 'Admin';

      // Admin's scrims
      final scrims = await _supabase
          .from('scrim')
          .select('id_scrim, biaya_pendaftaran, maks_peserta')
          .eq('id_admin', adminId);
      if ((scrims as List).isEmpty) {
        if (mounted) {
          setState(() { _adminNama = nama; _adminInitials = _initials(nama); _isLoading = false; });
        }
        return;
      }
      final scrimIds = scrims.map((s) => s['id_scrim'] as int).toList();
      final biayaMap = <int, double>{
        for (var s in scrims) s['id_scrim'] as int: (s['biaya_pendaftaran'] as num? ?? 0).toDouble()
      };
      final totalSlot = scrims.fold<int>(0, (sum, s) => sum + (s['maks_peserta'] as int? ?? 0));

      // Sessions
      final sessions = await _supabase
          .from('sesi_scrim')
          .select('id_sesi, id_scrim')
          .inFilter('id_scrim', scrimIds);
      if ((sessions as List).isEmpty) {
        if (mounted) {
          setState(() {
            _adminNama = nama;
            _adminInitials = _initials(nama);
            _totalSlot = totalSlot;
            _sisaSlot = totalSlot;
            _isLoading = false;
          });
        }
        return;
      }
      final sesiToScrim = <int, int>{
        for (var s in sessions) s['id_sesi'] as int: s['id_scrim'] as int
      };
      final sesiIds = sesiToScrim.keys.toList();

      // All bookings
      final bookings = await _supabase
          .from('pendaftaran_tim')
          .select('id_sesi, status_pembayaran, dibuat_pada')
          .inFilter('id_sesi', sesiIds);

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final yesterdayStart = todayStart.subtract(const Duration(days: 1));
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final lastMonthStart = now.month == 1
          ? DateTime(now.year - 1, 12, 1)
          : DateTime(now.year, now.month - 1, 1);

      int bookingHariIni = 0;
      int bookingKemarin = 0;
      int verifikasiCount = 0;
      int konfirmasiCount = 0;
      double pendapatanBulanIni = 0;
      double pendapatanBulanLalu = 0;
      final trendMap = <int, double>{};

      for (final b in bookings as List) {
        final status = b['status_pembayaran'] as String? ?? '';
        final tglStr = b['dibuat_pada'] as String?;
        DateTime? tgl;
        try {
          tgl = tglStr != null ? DateTime.parse(tglStr).toLocal() : null;
        } catch (_) {}
        final sesiId = b['id_sesi'] as int;
        final scrimId = sesiToScrim[sesiId] ?? 0;
        final biaya = biayaMap[scrimId] ?? 0;

        if (status == 'menunggu') verifikasiCount++;
        if (status == 'dikonfirmasi') konfirmasiCount++;

        if (tgl != null) {
          final tglDay = DateTime(tgl.year, tgl.month, tgl.day);

          if (!tglDay.isBefore(todayStart)) bookingHariIni++;
          if (tglDay == yesterdayStart) bookingKemarin++;

          if (status == 'dikonfirmasi') {
            if (!tglDay.isBefore(thisMonthStart)) pendapatanBulanIni += biaya;
            if (!tglDay.isBefore(lastMonthStart) && tglDay.isBefore(thisMonthStart)) {
              pendapatanBulanLalu += biaya;
            }
          }

          final diff = todayStart.difference(tglDay).inDays;
          if (diff >= 0 && diff < 7) {
            trendMap[6 - diff] = (trendMap[6 - diff] ?? 0) + 1;
          }
        }
      }

      if (mounted) {
        setState(() {
        _adminNama = nama;
        _adminInitials = _initials(nama);
        _bookingHariIni = bookingHariIni;
        _bookingKemarin = bookingKemarin;
        _verifikasiCount = verifikasiCount;
        _totalSlot = totalSlot;
        _sisaSlot = max(0, totalSlot - konfirmasiCount);
        _pendapatanBulanIni = pendapatanBulanIni;
        _pendapatanBulanLalu = pendapatanBulanLalu;
        _trendData = List.generate(7, (i) => trendMap[i] ?? 0);
        _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          primary: false,
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppConstants.paddingS),

              // ── Header ──
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _adminInitials.isEmpty ? 'AD' : _adminInitials,
                      style: AppTextStyles.poppinsButton.copyWith(
                        color: AppColors.background,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Halo,', style: AppTextStyles.interBody.copyWith(color: AppColors.textSecondary, fontSize: 13)),
                      Text(
                        _adminNama.isEmpty ? 'Admin' : _adminNama,
                        style: AppTextStyles.poppinsTitleSmall.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminNotificationPage()),
                    ),
                    child: Stack(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: AppColors.backgroundCard, shape: BoxShape.circle),
                          child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 22),
                        ),
                        if (_verifikasiCount > 0)
                          Positioned(
                            right: 10, top: 10,
                            child: Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingL),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else ...[
                // ── Grid Stats ──
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Booking Hari Ini',
                        value: '$_bookingHariIni',
                        subtitle: 'Total Booking',
                        badge: _bookingBadge,
                        badgeUp: _bookingKemarin > 0 ? _bookingUp : null,
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingS),
                    Expanded(
                      child: _StatCard(
                        title: 'Verifikasi',
                        value: '$_verifikasiCount',
                        subtitle: 'Pembayaran',
                        badge: 'Menunggu Verifikasi',
                        badgeUp: null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingS),
                _StatCard(
                  title: 'Sisa Slot',
                  value: '$_sisaSlot',
                  subtitle: 'Slot Tersisa',
                  badge: 'Dari $_totalSlot Total Slot',
                  badgeUp: null,
                ),

                const SizedBox(height: AppConstants.paddingL),

                // ── Pendapatan ──
                _RevenueCard(
                  jumlah: _formatRupiah(_pendapatanBulanIni),
                  badge: _pendapatanBadge,
                  badgeUp: _pendapatanUp,
                ),
                const SizedBox(height: AppConstants.paddingL),

                // ── Tren Booking ──
                Text(
                  'Tren Booking',
                  style: AppTextStyles.poppinsTitleSmall.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: AppConstants.paddingM),
                _TrendChart(data: _trendData),
                const SizedBox(height: AppConstants.paddingM),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Revenue Card ──
class _RevenueCard extends StatelessWidget {
  final String jumlah;
  final String badge;
  final bool badgeUp;

  const _RevenueCard({required this.jumlah, required this.badge, required this.badgeUp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pendapatan Bulan Ini',
            style: AppTextStyles.poppinsTitleSmall.copyWith(
              color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            jumlah,
            style: AppTextStyles.poppinsHeadline.copyWith(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                badgeUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: AppColors.primary, size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                badge,
                style: AppTextStyles.interBody.copyWith(
                  color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Vs bulan lalu',
                style: AppTextStyles.interBody.copyWith(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stat Card ──
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final String badge;
  final bool? badgeUp;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.badge,
    required this.badgeUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.poppinsTitleSmall.copyWith(
              color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: AppTextStyles.poppinsHeadline.copyWith(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(width: 4),
              Text(subtitle, style: AppTextStyles.interBody.copyWith(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (badgeUp != null) ...[
                Icon(
                  badgeUp! ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  color: AppColors.primary, size: 14,
                ),
                const SizedBox(width: 3),
              ],
              Flexible(
                child: Text(
                  badge,
                  style: AppTextStyles.interBody.copyWith(color: AppColors.textSecondary, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Trend Chart ──
class _TrendChart extends StatelessWidget {
  final List<double> data;
  const _TrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '7 HARI TERAKHIR',
            style: AppTextStyles.interLabel.copyWith(
              color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: CustomPaint(painter: _ChartPainter(data), size: Size.infinite)),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> data;

  _ChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = data.isEmpty ? 1.0 : max(data.reduce(max), 1.0);
    const labelHeight = 18.0;
    final chartH = size.height - labelHeight;
    final stepX = size.width / (data.length - 1);

    // Y gridlines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      final y = chartH - (chartH * i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Points
    List<Offset> pts = [];
    for (int i = 0; i < data.length; i++) {
      final x = stepX * i;
      final y = chartH - (chartH * data[i] / maxVal);
      pts.add(Offset(x, y));
    }

    // Fill
    final fillPath = Path()..moveTo(pts.first.dx, chartH);
    for (final p in pts) { fillPath.lineTo(p.dx, p.dy); }
    fillPath.lineTo(pts.last.dx, chartH);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFD4AF37).withValues(alpha: 0.3),
            const Color(0xFFD4AF37).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, chartH)),
    );

    // Line
    final linePath = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      final cp1 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i - 1].dy);
      final cp2 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i].dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = const Color(0xFFD4AF37)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    // Dots
    for (final p in pts) {
      canvas.drawCircle(p, 4, Paint()..color = const Color(0xFF0A1628));
      canvas.drawCircle(
        p, 4,
        Paint()
          ..color = const Color(0xFFD4AF37)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    // Day labels
    // Show days of week for last 7 days starting from 6 days ago
    final now = DateTime.now();
    final dayNames = ['MIN', 'SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB'];
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < data.length; i++) {
      final day = now.subtract(Duration(days: data.length - 1 - i));
      tp.text = TextSpan(
        text: dayNames[day.weekday % 7],
        style: const TextStyle(color: Color(0xFF8899AA), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      );
      tp.layout();
      tp.paint(canvas, Offset(stepX * i - tp.width / 2, chartH + 5));
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => old.data != data;
}
