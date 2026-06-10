import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';

class ManageFeeScreen extends StatefulWidget {
  const ManageFeeScreen({super.key});

  @override
  State<ManageFeeScreen> createState() => _ManageFeeScreenState();
}

class _ManageFeeScreenState extends State<ManageFeeScreen> {
  final TextEditingController _platformFeeController = TextEditingController(text: '5');
  final TextEditingController _adminFeeController = TextEditingController(text: '5');

  int _savedPlatformFee = 5;
  int _savedAdminFee = 5;

  static const int _platformMin = 5;
  static const int _platformMax = 20;
  static const int _adminMin = 5;
  static const int _adminMax = 25;

  @override
  void initState() {
    super.initState();
    _platformFeeController.addListener(_onInputChanged);
    _adminFeeController.addListener(_onInputChanged);
    _fetchFeeSettings();
  }

  Future<void> _fetchFeeSettings() async {
    try {
      final data = await Supabase.instance.client
          .from('pengaturan_fee')
          .select()
          .maybeSingle();

      if (data != null && mounted) {
        final pf = (data['fee_platform_persen'] as num? ?? 5).toInt();
        final af = (data['fee_admin_persen'] as num? ?? 5).toInt();
        setState(() {
          _platformFeeController.text = pf.toString();
          _adminFeeController.text = af.toString();
          _savedPlatformFee = pf;
          _savedAdminFee = af;
        });
      }
    } catch (e) {
      debugPrint('Error fetch fee settings: $e');
    }
  }

  double get _platformFeeValue =>
      double.tryParse(_platformFeeController.text.replaceAll(',', '.')) ?? 0;
  double get _adminFeeValue =>
      double.tryParse(_adminFeeController.text.replaceAll(',', '.')) ?? 0;

  bool get _platformFeeValid =>
      _platformFeeValue >= _platformMin && _platformFeeValue <= _platformMax;
  bool get _adminFeeValid =>
      _adminFeeValue >= _adminMin && _adminFeeValue <= _adminMax;

  String get _platformFeeError {
    if (_platformFeeController.text.isEmpty) return '';
    if (_platformFeeValue < _platformMin) return 'Minimal $_platformMin% · Maksimal $_platformMax%';
    if (_platformFeeValue > _platformMax) return 'Melebihi batas maksimal $_platformMax%';
    return '';
  }

  String get _adminFeeError {
    if (_adminFeeController.text.isEmpty) return '';
    if (_adminFeeValue < _adminMin) return 'Minimal $_adminMin% · Maksimal $_adminMax%';
    if (_adminFeeValue > _adminMax) return 'Melebihi batas maksimal $_adminMax%';
    return '';
  }

  Future<void> _saveFeeSettings() async {
    if (!_platformFeeValid) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Fee Platform harus antara $_platformMin%–$_platformMax%'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    if (!_adminFeeValid) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Fee Admin harus antara $_adminMin%–$_adminMax%'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    try {
      final int platformFee = _platformFeeValue.toInt();
      final int adminFee = _adminFeeValue.toInt();

      final updateData = {
        'fee_platform_persen': platformFee,
        'nominal_minimum_platform': 5000,
        'is_persentase_admin': true,
        'fee_admin_persen': adminFee,
        'fee_admin_tetap': null,
      };

      final response = await Supabase.instance.client
          .from('pengaturan_fee')
          .select()
          .maybeSingle();

      if (response != null) {
        String? pkColumn;
        for (var key in response.keys) {
          if (key.toLowerCase().contains('id')) {
            pkColumn = key;
            break;
          }
        }
        if (pkColumn != null) {
          await Supabase.instance.client
              .from('pengaturan_fee')
              .update(updateData)
              .eq(pkColumn, response[pkColumn]);
        } else {
          await Supabase.instance.client
              .from('pengaturan_fee')
              .update(updateData)
              .eq('fee_platform_persen', response['fee_platform_persen']);
        }
      } else {
        await Supabase.instance.client
            .from('pengaturan_fee')
            .insert(updateData);
      }

      if (mounted) {
        setState(() {
          _savedPlatformFee = platformFee;
          _savedAdminFee = adminFee;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Konfigurasi Fee berhasil disimpan!'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      debugPrint('Error saving fee settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal: $e', style: const TextStyle(fontSize: 10)),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 10),
        ));
      }
    }
  }

  void _onInputChanged() => setState(() {});

  String _formatRp(double val) {
    return 'Rp ${val.toInt().toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        )}';
  }

  @override
  void dispose() {
    _platformFeeController.dispose();
    _adminFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFFFD700)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'KELOLA FEE',
          style: AppTextStyles.poppinsHeadline.copyWith(
            color: const Color(0xFFFFD700),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildPlatformFeeSection(),
            const SizedBox(height: 24),
            _buildAdminFeeSection(),
            const SizedBox(height: 24),
            _buildSimulationSection(),
            const SizedBox(height: 32),
            _buildActionButtons(),
            const SizedBox(height: 32),
            _buildHistoryLogSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformFeeSection() {
    final hasError = _platformFeeError.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131F2D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FEE\nPLATFORM',
                    style: AppTextStyles.poppinsHeadline.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Konfigurasi bagi hasil',
                    style: AppTextStyles.interCaption
                        .copyWith(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                  border: Border.all(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'KONFIGURASI\nAKTIF: $_savedPlatformFee%',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.interCaption.copyWith(
                    color: const Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildLabel('PERSENTASE FEE (%) · Min $_platformMin% – Maks $_platformMax%'),
          TextField(
            controller: _platformFeeController,
            style: AppTextStyles.poppinsHeadline
                .copyWith(color: Colors.white, fontSize: 16),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0F1722),
              suffixIcon: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('%',
                    style: AppTextStyles.poppinsHeadline.copyWith(
                        color: hasError
                            ? const Color(0xFFD67777)
                            : const Color(0xFFFFD700),
                        fontSize: 16)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: hasError
                        ? const Color(0xFFD67777).withValues(alpha: 0.8)
                        : const Color(0xFFFFD700).withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: hasError
                        ? const Color(0xFFD67777)
                        : const Color(0xFFFFD700),
                    width: 1.5),
              ),
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 8),
            _buildErrorHint(_platformFeeError),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LAMA',
                      style: AppTextStyles.interCaption.copyWith(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                  Text('$_savedPlatformFee%',
                      style: AppTextStyles.poppinsHeadline.copyWith(
                          color: Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child:
                    Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BARU',
                      style: AppTextStyles.interCaption.copyWith(
                          color: const Color(0xFFFFD700),
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                  Text(
                    '${_platformFeeController.text.isEmpty ? '0' : _platformFeeController.text}%',
                    style: AppTextStyles.poppinsHeadline.copyWith(
                        color: const Color(0xFFFFD700),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminFeeSection() {
    final hasError = _adminFeeError.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131F2D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FEE ADMIN',
                style: AppTextStyles.poppinsHeadline.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                  border: Border.all(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'KONFIGURASI\nAKTIF: $_savedAdminFee%',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.interCaption.copyWith(
                    color: const Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildLabel('PERSENTASE FEE ADMIN (%) · Min $_adminMin% – Maks $_adminMax%'),
          TextField(
            controller: _adminFeeController,
            style: AppTextStyles.poppinsHeadline
                .copyWith(color: Colors.white, fontSize: 16),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0F1722),
              suffixIcon: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('%',
                    style: AppTextStyles.poppinsHeadline.copyWith(
                        color: hasError
                            ? const Color(0xFFD67777)
                            : const Color(0xFFFFD700),
                        fontSize: 16)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: hasError
                        ? const Color(0xFFD67777).withValues(alpha: 0.8)
                        : const Color(0xFFFFD700).withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: hasError
                        ? const Color(0xFFD67777)
                        : const Color(0xFFFFD700),
                    width: 1.5),
              ),
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 8),
            _buildErrorHint(_adminFeeError),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LAMA',
                      style: AppTextStyles.interCaption.copyWith(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                  Text('$_savedAdminFee%',
                      style: AppTextStyles.poppinsHeadline.copyWith(
                          color: Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child:
                    Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BARU',
                      style: AppTextStyles.interCaption.copyWith(
                          color: const Color(0xFFFFD700),
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                  Text(
                    '${_adminFeeController.text.isEmpty ? '0' : _adminFeeController.text}%',
                    style: AppTextStyles.poppinsHeadline.copyWith(
                        color: const Color(0xFFFFD700),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorHint(String message) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Color(0xFFD67777),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.priority_high_rounded,
              color: Color(0xFF131F2D), size: 10),
        ),
        const SizedBox(width: 6),
        Text(
          message,
          style: AppTextStyles.interCaption
              .copyWith(color: const Color(0xFFD67777), fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildSimulationSection() {
    const double basePendapatan = 100000;

    final double platformPercent = _platformFeeValue;
    final double adminFeeInput = _adminFeeValue;

    final double finalFeePlatform = basePendapatan * (platformPercent / 100);
    final double feeAdminCalc = basePendapatan * (adminFeeInput / 100);

    double totalNet = basePendapatan - finalFeePlatform - feeAdminCalc;
    if (totalNet < 0) totalNet = 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131F2D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  color: Color(0xFFFFD700), size: 18),
              const SizedBox(width: 8),
              Text(
                'PREVIEW SIMULASI',
                style: AppTextStyles.interCaption.copyWith(
                    color: const Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSimRow('Pendapatan Scrim', _formatRp(basePendapatan),
              Colors.white, Colors.white),
          const SizedBox(height: 24),
          _buildSimRow(
              'Fee Platform ($platformPercent%)',
              '-${_formatRp(finalFeePlatform)}',
              Colors.white70,
              const Color(0xFFD67777)),
          const SizedBox(height: 12),
          _buildSimRow(
              'Fee Admin ($adminFeeInput%)',
              '-${_formatRp(feeAdminCalc)}',
              Colors.white70,
              const Color(0xFFD67777)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1722),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL HADIAH (NET)',
                  style: AppTextStyles.interCaption.copyWith(
                      color: const Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 10),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatRp(totalNet),
                  style: AppTextStyles.poppinsHeadline.copyWith(
                      color: const Color(0xFFFFD700),
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimRow(
      String label, String value, Color labelColor, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                AppTextStyles.interBody.copyWith(color: labelColor, fontSize: 12)),
        Text(value,
            style: AppTextStyles.interBody.copyWith(
                color: valueColor, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: AppTextStyles.interCaption.copyWith(
          color: const Color(0xFFFFD700),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final canSave = _platformFeeValid && _adminFeeValid;
    return Column(
      children: [
        ElevatedButton(
          onPressed: canSave ? _saveFeeSettings : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canSave ? const Color(0xFFFFD700) : Colors.white24,
            foregroundColor: Colors.black,
            disabledBackgroundColor: Colors.white24,
            disabledForegroundColor: Colors.white54,
            elevation: 0,
            minimumSize: const Size(double.infinity, 50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            'SIMPAN PERUBAHAN',
            style: AppTextStyles.poppinsTitleSmall
                .copyWith(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _platformFeeController.text = '5';
              _adminFeeController.text = '5';
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F1722),
            foregroundColor: const Color(0xFFFFD700),
            elevation: 0,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          child: Text(
            'RESET KE DEFAULT',
            style: AppTextStyles.poppinsTitleSmall.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: const Color(0xFFFFD700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryLogSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131F2D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LOG RIWAYAT PERUBAHAN',
            style: AppTextStyles.interCaption.copyWith(
              color: const Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 24),
          _buildLogItem(
            isLatest: true,
            user: 'Owner',
            action: ' mengubah Fee Platform dari 4% ke 5%',
            date: '20 Oct 2023 • 14:20 PM',
          ),
          _buildLogItem(
            isLatest: false,
            user: 'Owner',
            action: ' mengubah Fee Admin ke 10%',
            date: '18 Oct 2023 • 09:15 AM',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem({
    required bool isLatest,
    required String user,
    required String action,
    required String date,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 16,
            child: Column(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: isLatest ? const Color(0xFFFFD700) : Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: Colors.white24,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: user,
                          style: AppTextStyles.interCaption.copyWith(
                              color: const Color(0xFFFFD700),
                              fontWeight: FontWeight.bold,
                              fontSize: 11),
                        ),
                        TextSpan(
                          text: action,
                          style: AppTextStyles.interCaption
                              .copyWith(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: AppTextStyles.interCaption
                        .copyWith(color: Colors.white38, fontSize: 9),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
