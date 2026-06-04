import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';

class ManageFeeScreen extends StatelessWidget {
  const ManageFeeScreen({super.key});

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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1722), // Darker inner bg
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD67777).withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '25',
                  style: AppTextStyles.poppinsHeadline.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '%',
                  style: AppTextStyles.poppinsHeadline.copyWith(
                    color: const Color(0xFFD67777),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Color(0xFFD67777), shape: BoxShape.circle),
                child: const Icon(Icons.priority_high_rounded, color: Color(0xFF131F2D), size: 10),
              ),
              const SizedBox(width: 6),
              Text(
                'Nilai melebihi batas 20 %',
                style: AppTextStyles.interCaption.copyWith(color: const Color(0xFFD67777), fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildLabel('NOMINAL MINIMUM (Rp)'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1722),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  'Rp ',
                  style: AppTextStyles.poppinsHeadline.copyWith(
                    color: const Color(0xFFFFD700),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '5.000',
                  style: AppTextStyles.poppinsHeadline.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
                    '25%',
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
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Persentase (%)',
                    style: AppTextStyles.interBody.copyWith(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2836), // slightly lighter than card bg
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Fee Tetap (Rp)',
                    style: AppTextStyles.interBody.copyWith(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildLabel('BESARAN FEE ADMIN'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1722),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '10',
                  style: AppTextStyles.poppinsHeadline.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '%',
                  style: AppTextStyles.poppinsHeadline.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationSection() {
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
          _buildSimRow('Pendapatan Scrim', 'Rp 100.000', Colors.white, Colors.white),
          const SizedBox(height: 24),
          _buildSimRow('Fee Platform (5%)', '-Rp 5.000', Colors.white70, const Color(0xFFD67777)),
          const SizedBox(height: 12),
          _buildSimRow('Fee Platform (10%)', '-Rp 10.000', Colors.white70, const Color(0xFFD67777)),
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
                  'Rp 85.000',
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
          onPressed: () {},
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
          onPressed: () => Navigator.of(context).pop(),
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
            action: ' changed Platform Fee from 4% to 5%',
            date: '20 Oct 2023 • 14:20 PM',
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
