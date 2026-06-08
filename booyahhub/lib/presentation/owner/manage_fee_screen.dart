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
  final TextEditingController _platformFeeController = TextEditingController(text: '25');
  final TextEditingController _minFeeController = TextEditingController(text: '5.000');
  final TextEditingController _adminFeeController = TextEditingController(text: '10');
  
  bool _isPersentaseAdmin = true;

  @override
  void initState() {
    super.initState();
    _platformFeeController.addListener(_onInputChanged);
    _minFeeController.addListener(_onInputChanged);
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
        setState(() {
          _platformFeeController.text = (data['fee_platform_persen'] ?? 25).toString();
          
          if (data['nominal_minimum_platform'] != null) {
            _minFeeController.text = data['nominal_minimum_platform'].toString();
          }
          
          if (data['is_persentase_admin'] != null) {
            _isPersentaseAdmin = data['is_persentase_admin'];
          }

          if (_isPersentaseAdmin) {
            _adminFeeController.text = (data['fee_admin_persen'] ?? 10).toString();
          } else {
            _adminFeeController.text = (data['fee_admin_tetap'] ?? 10000).toString();
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetch fee settings: $e');
    }
  }

  Future<void> _saveFeeSettings() async {
    try {
      final double platformFee = double.tryParse(_platformFeeController.text.replaceAll(',', '.')) ?? 25;
      final double minFee = double.tryParse(_minFeeController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 5000;
      final double adminFee = double.tryParse(_adminFeeController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 10;

      final updateData = {
        'fee_platform_persen': platformFee.toInt(),
        'nominal_minimum_platform': minFee.toInt(),
        'is_persentase_admin': _isPersentaseAdmin,
        'fee_admin_persen': _isPersentaseAdmin ? adminFee.toInt() : null,
        'fee_admin_tetap': !_isPersentaseAdmin ? adminFee.toInt() : null,
      };

      // Ambil seluruh data untuk mengetahui nama primary key secara dinamis
      final response = await Supabase.instance.client
          .from('pengaturan_fee')
          .select()
          .maybeSingle();
          
      if (response != null) {
         // Mencari key yang mengandung kata 'id' (misal: id_pengaturan, id)
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
           // Fallback jika tidak ada kolom id yang jelas
           await Supabase.instance.client
              .from('pengaturan_fee')
              .update(updateData)
              .eq('fee_platform_persen', response['fee_platform_persen']);
         }
      } else {
         // Jika tabel kosong, lakukan insert
         await Supabase.instance.client
            .from('pengaturan_fee')
            .insert(updateData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konfigurasi Fee berhasil disimpan ke database!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving fee settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e', style: const TextStyle(fontSize: 10)),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
  }

  void _onInputChanged() {
    setState(() {}); // Pemicu re-render simulasi
  }

  String _formatRp(double val) {
    return 'Rp ${val.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
  }

  @override
  void dispose() {
    _platformFeeController.dispose();
    _minFeeController.dispose();
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
            _buildActionButtons(context),
            const SizedBox(height: 32),
            _buildHistoryLogSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformFeeSection() {
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
                    style: AppTextStyles.interCaption.copyWith(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                  border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'KONFIGURASI\nAKTIF: 5%',
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
          _buildLabel('PERSENTASE FEE (%)'),
          TextField(
            controller: _platformFeeController,
            style: AppTextStyles.poppinsHeadline.copyWith(color: Colors.white, fontSize: 16),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0F1722),
              suffixIcon: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('%', style: AppTextStyles.poppinsHeadline.copyWith(color: const Color(0xFFD67777), fontSize: 16)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: const Color(0xFFD67777).withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD67777), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: (double.tryParse(_platformFeeController.text) ?? 0) > 20 
                      ? const Color(0xFFD67777) 
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.priority_high_rounded, 
                  color: (double.tryParse(_platformFeeController.text) ?? 0) > 20 
                      ? const Color(0xFF131F2D) 
                      : Colors.transparent, 
                  size: 10
                ),
              ),
              const SizedBox(width: 6),
              Text(
                (double.tryParse(_platformFeeController.text) ?? 0) > 20 
                    ? 'Nilai melebihi batas 20 %' 
                    : '',
                style: AppTextStyles.interCaption.copyWith(color: const Color(0xFFD67777), fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildLabel('NOMINAL MINIMUM (Rp)'),
          TextField(
            controller: _minFeeController,
            style: AppTextStyles.poppinsHeadline.copyWith(color: Colors.white, fontSize: 16),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0F1722),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 8.0, top: 12),
                child: Text('Rp', style: AppTextStyles.poppinsHeadline.copyWith(color: const Color(0xFFFFD700), fontSize: 16)),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LAMA',
                    style: AppTextStyles.interCaption.copyWith(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '5%',
                    style: AppTextStyles.poppinsHeadline.copyWith(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BARU',
                    style: AppTextStyles.interCaption.copyWith(color: const Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_platformFeeController.text.isEmpty ? '0' : _platformFeeController.text}%',
                    style: AppTextStyles.poppinsHeadline.copyWith(color: const Color(0xFFFFD700), fontSize: 14, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
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
            'FEE ADMIN',
            style: AppTextStyles.poppinsHeadline.copyWith(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isPersentaseAdmin = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isPersentaseAdmin ? const Color(0xFFFFD700) : const Color(0xFF1C2836),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Persentase (%)',
                      style: AppTextStyles.interBody.copyWith(
                        color: _isPersentaseAdmin ? Colors.black : Colors.white54, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 12
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isPersentaseAdmin = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_isPersentaseAdmin ? const Color(0xFFFFD700) : const Color(0xFF1C2836),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Fee Tetap (Rp)',
                      style: AppTextStyles.interBody.copyWith(
                        color: !_isPersentaseAdmin ? Colors.black : Colors.white54, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 12
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildLabel('BESARAN FEE ADMIN'),
          TextField(
            controller: _adminFeeController,
            style: AppTextStyles.poppinsHeadline.copyWith(color: Colors.white, fontSize: 16),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0F1722),
              suffixIcon: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(_isPersentaseAdmin ? '%' : 'Rp', style: AppTextStyles.poppinsHeadline.copyWith(color: Colors.white, fontSize: 16)),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationSection() {
    double basePendapatan = 100000;
    
    double platformPercent = double.tryParse(_platformFeeController.text.replaceAll(',', '.')) ?? 0;
    double minFee = double.tryParse(_minFeeController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
    double adminFeeInput = double.tryParse(_adminFeeController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
    
    double feePlatformCalc = basePendapatan * (platformPercent / 100);
    double finalFeePlatform = feePlatformCalc < minFee ? minFee : feePlatformCalc;
    
    double feeAdminCalc = _isPersentaseAdmin 
        ? basePendapatan * (adminFeeInput / 100)
        : adminFeeInput;
        
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
              const Icon(Icons.bar_chart_rounded, color: Color(0xFFFFD700), size: 18),
              const SizedBox(width: 8),
              Text(
                'PREVIEW SIMULASI',
                style: AppTextStyles.interCaption.copyWith(color: const Color(0xFFFFD700), fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSimRow('Pendapatan Scrim', _formatRp(basePendapatan), Colors.white, Colors.white),
          const SizedBox(height: 24),
          _buildSimRow('Fee Platform ($platformPercent%)', '-${_formatRp(finalFeePlatform)}', Colors.white70, const Color(0xFFD67777)),
          const SizedBox(height: 12),
          _buildSimRow('Fee Admin (${_isPersentaseAdmin ? '$adminFeeInput%' : 'Tetap'})', '-${_formatRp(feeAdminCalc)}', Colors.white70, const Color(0xFFD67777)),
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
                  style: AppTextStyles.interCaption.copyWith(color: const Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 10),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatRp(totalNet),
                  style: AppTextStyles.poppinsHeadline.copyWith(color: const Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimRow(String label, String value, Color labelColor, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.interBody.copyWith(color: labelColor, fontSize: 12),
        ),
        Text(
          value,
          style: AppTextStyles.interBody.copyWith(color: valueColor, fontWeight: FontWeight.bold, fontSize: 13),
        ),
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

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _saveFeeSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: Colors.black,
            elevation: 0,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            'SIMPAN PERUBAHAN',
            style: AppTextStyles.poppinsTitleSmall.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
             setState(() {
                _platformFeeController.text = '5';
                _minFeeController.text = '2.000';
                _adminFeeController.text = '5';
             });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F1722), // very dark bg matching design
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
            user: 'Admin',
            action: ' changed Platform Fee from 4% to 5%',
            date: '20 Oct 2023 • 14:20 PM',
          ),
          _buildLogItem(
            isLatest: false,
            user: 'Admin',
            action: ' changed Admin Fee to 10%',
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
                          style: AppTextStyles.interCaption.copyWith(color: const Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        TextSpan(
                          text: action,
                          style: AppTextStyles.interCaption.copyWith(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: AppTextStyles.interCaption.copyWith(color: Colors.white38, fontSize: 9),
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
