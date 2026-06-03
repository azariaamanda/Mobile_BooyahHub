import 'package:flutter/material.dart';
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
  int _selectedIndex = 0; // For bottom nav

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
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFeePlatformSection(),
              const SizedBox(height: 24),
              _buildFeeAdminSection(),
              const SizedBox(height: 24),
              _buildPreviewSimulasiSection(),
              const SizedBox(height: 24),
              _buildActionButtons(),
              const SizedBox(height: 32),
              _buildLogRiwayatSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'KELOLA FEE',
        style: AppTextStyles.poppinsTitle.copyWith(
          color: AppColors.primary,
          fontSize: 16,
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildFeePlatformSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
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
                      fontStyle: FontStyle.italic,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Konfigurasi bagi hasil',
                    style: AppTextStyles.interCaption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Text(
                  'KONFIGURASI\nAKTIF: 5%',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.interCaption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'PERSENTASE FEE (%)',
            style: AppTextStyles.interCaption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _platformFeeController,
            style: AppTextStyles.poppinsHeadline.copyWith(fontSize: 18),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              suffixIcon: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('%', style: TextStyle(color: AppColors.error, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.error, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.error, width: 1),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 14),
              const SizedBox(width: 4),
              Text(
                'Nilai melebihi batas 20 %',
                style: AppTextStyles.interCaption.copyWith(color: AppColors.error, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'NOMINAL MINIMUM (Rp)',
            style: AppTextStyles.interCaption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _minFeeController,
            style: AppTextStyles.poppinsHeadline.copyWith(fontSize: 18),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 8.0, top: 14),
                child: Text('Rp', style: AppTextStyles.poppinsHeadline.copyWith(color: AppColors.primary, fontSize: 18)),
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
                  Text('LAMA', style: AppTextStyles.interCaption.copyWith(color: AppColors.textSecondary, fontSize: 10)),
                  Text('5%', style: AppTextStyles.poppinsSubtitle.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                ],
              ),
              const SizedBox(width: 16),
              const Icon(Icons.arrow_forward, color: AppColors.textPrimary, size: 20),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BARU', style: AppTextStyles.interCaption.copyWith(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text('25%', style: AppTextStyles.poppinsSubtitle.copyWith(color: AppColors.primary, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeeAdminSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FEE ADMIN',
            style: AppTextStyles.poppinsHeadline.copyWith(
              fontStyle: FontStyle.italic,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isPersentaseAdmin = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isPersentaseAdmin ? AppColors.primary : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Persentase (%)',
                      style: AppTextStyles.interBody.copyWith(
                        color: _isPersentaseAdmin ? AppColors.black : AppColors.textSecondary,
                        fontWeight: _isPersentaseAdmin ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isPersentaseAdmin = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_isPersentaseAdmin ? AppColors.primary : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Fee Tetap (Rp)',
                      style: AppTextStyles.interBody.copyWith(
                        color: !_isPersentaseAdmin ? AppColors.black : AppColors.textSecondary,
                        fontWeight: !_isPersentaseAdmin ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'BESARAN FEE ADMIN',
            style: AppTextStyles.interCaption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _adminFeeController,
            style: AppTextStyles.poppinsHeadline.copyWith(fontSize: 18),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              suffixIcon: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(_isPersentaseAdmin ? '%' : 'Rp', style: AppTextStyles.poppinsHeadline.copyWith(color: AppColors.textPrimary, fontSize: 18)),
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

  Widget _buildPreviewSimulasiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bar_chart, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'PREVIEW SIMULASI',
              style: AppTextStyles.interBody.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pendapatan Scrim', style: AppTextStyles.interBody.copyWith(color: AppColors.textSecondary)),
            Text('Rp 100.000', style: AppTextStyles.poppinsSubtitle.copyWith(color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(color: AppColors.divider),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Fee Platform (5%)', style: AppTextStyles.interBody.copyWith(color: AppColors.textSecondary)),
            Text('-Rp 5.000', style: AppTextStyles.poppinsSubtitle.copyWith(color: AppColors.error)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Fee Admin (10%)', style: AppTextStyles.interBody.copyWith(color: AppColors.textSecondary)),
            Text('-Rp 10.000', style: AppTextStyles.poppinsSubtitle.copyWith(color: AppColors.error)),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL HADIAH (NET)',
                style: AppTextStyles.interCaption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Rp 85.000',
                style: AppTextStyles.poppinsHeadline.copyWith(
                  color: AppColors.primary,
                  fontSize: 28,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'SIMPAN PERUBAHAN',
              style: AppTextStyles.interBody.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.divider),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'RESET KE DEFAULT',
              style: AppTextStyles.interBody.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogRiwayatSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LOG RIWAYAT PERUBAHAN',
            style: AppTextStyles.interCaption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 24),
          _buildLogItem('Admin', 'changed Platform Fee from 4% to 5%', '20 Oct 2023', '14:20 PM', true),
          _buildLogItem('Admin', 'changed Platform Fee from 4% to 5%', '20 Oct 2023', '14:20 PM', false),
        ],
      ),
    );
  }

  Widget _buildLogItem(String user, String action, String date, String time, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            if (isLast)
              Container(
                width: 1,
                height: 40,
                color: AppColors.divider,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: AppTextStyles.interCaption.copyWith(color: AppColors.textSecondary),
                  children: [
                    TextSpan(
                      text: user,
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ' $action'),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$date  •  $time',
                style: AppTextStyles.interCaption.copyWith(color: AppColors.textHint, fontSize: 10),
              ),
              if (isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.dashboard, 'DASHBOARD', 0),
          _buildNavItem(Icons.account_balance_wallet, 'KEUANGAN', 1),
          _buildNavItem(Icons.gavel, 'KLAIM', 2),
          _buildNavItem(Icons.settings, 'PENGATURAN', 3),
          _buildNavItem(Icons.person, 'PROFIL', 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.interCaption.copyWith(
                color: color,
                fontSize: 8,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
