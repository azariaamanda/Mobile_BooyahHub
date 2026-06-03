import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

enum ClaimStatus { pendingClaim, processing, claimed }

class ClaimReward {
  final String title;
  final int amount;
  final String rank;
  final String eventName;
  final DateTime date;
  final ClaimStatus status;
  final String? bankAccount;
  final String? accountHolder;

  const ClaimReward({
    required this.title,
    required this.amount,
    required this.rank,
    required this.eventName,
    required this.date,
    required this.status,
    this.bankAccount,
    this.accountHolder,
  });
}

class UserClaimRewardsPage extends StatefulWidget {
  const UserClaimRewardsPage({super.key});

  @override
  State<UserClaimRewardsPage> createState() => _UserClaimRewardsPageState();
}

class _UserClaimRewardsPageState extends State<UserClaimRewardsPage> {
  int selectedTabIndex = 0;

  final List<ClaimReward> allRewards = [
    ClaimReward(
      title: 'Scrim Ganteng',
      amount: 250000,
      rank: 'Juara 1',
      eventName: 'Scrim Ganteng',
      date: DateTime.now().subtract(const Duration(days: 2)),
      status: ClaimStatus.pendingClaim,
    ),
    ClaimReward(
      title: 'Tournament Mega',
      amount: 500000,
      rank: 'Juara 1',
      eventName: 'Tournament Mega',
      date: DateTime.now().subtract(const Duration(days: 5)),
      status: ClaimStatus.processing,
      accountHolder: 'John Doe',
      bankAccount: '****1234',
    ),
    ClaimReward(
      title: 'RRQ Scrim',
      amount: 150000,
      rank: 'Juara 2',
      eventName: 'RRQ Scrim',
      date: DateTime.now().subtract(const Duration(days: 10)),
      status: ClaimStatus.claimed,
      accountHolder: 'John Doe',
      bankAccount: '****1234',
    ),
    ClaimReward(
      title: 'Esports Series',
      amount: 350000,
      rank: 'Juara 1',
      eventName: 'Esports Series',
      date: DateTime.now().subtract(const Duration(days: 15)),
      status: ClaimStatus.claimed,
      accountHolder: 'John Doe',
      bankAccount: '****1234',
    ),
  ];

  List<ClaimReward> get filteredRewards {
    switch (selectedTabIndex) {
      case 0: // Semua
        return allRewards;
      case 1: // Perlu Tindakan
        return allRewards
            .where((r) => r.status == ClaimStatus.pendingClaim)
            .toList();
      case 2: // Diproses
        return allRewards
            .where((r) => r.status == ClaimStatus.processing)
            .toList();
      case 3: // Selesai
        return allRewards
            .where((r) => r.status == ClaimStatus.claimed)
            .toList();
      default:
        return allRewards;
    }
  }

  String _formatCurrency(int amount) {
    final s = amount.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return 'Rp $b';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Klaim Hadiah',
          style: AppTextStyles.poppinsTitle.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingL,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Penghargaan Kamu',
                  style: AppTextStyles.poppinsHeadline.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kelola semua hadiah dari turnamen dan scrim yang telah kamu menangkan',
                  style: AppTextStyles.interBody,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Tab Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingL,
            ),
            child: Row(
              children: [
                _buildTabButton('Semua', 0),
                const SizedBox(width: 12),
                _buildTabButton('Perlu Tindakan', 1),
                const SizedBox(width: 12),
                _buildTabButton('Diproses', 2),
                const SizedBox(width: 12),
                _buildTabButton('Selesai', 3),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // List Content
          Expanded(
            child: filteredRewards.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingL,
                    ),
                    itemCount: filteredRewards.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _buildRewardCard(context, filteredRewards[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingM,
          vertical: AppConstants.paddingS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.inputBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.interBodyMedium.copyWith(
            color: isSelected ? AppColors.buttonText : AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildRewardCard(BuildContext context, ClaimReward reward) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (reward.status) {
      case ClaimStatus.pendingClaim:
        statusColor = AppColors.urgent;
        statusLabel = 'PERLU TINDAKAN';
        statusIcon = Icons.warning;
        break;
      case ClaimStatus.processing:
        statusColor = const Color(0xFF14B8A6);
        statusLabel = 'SEDANG DICAIRKAN';
        statusIcon = Icons.hourglass_bottom;
        break;
      case ClaimStatus.claimed:
        statusColor = AppColors.accent;
        statusLabel = 'SELESAI';
        statusIcon = Icons.check_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.inputBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reward.title, style: AppTextStyles.poppinsTitleSmall),
                    const SizedBox(height: 4),
                    Text(reward.eventName, style: AppTextStyles.interCaption),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingM,
                  vertical: AppConstants.paddingS,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: AppTextStyles.interCaption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Amount and Rank
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hadiah', style: AppTextStyles.interLabel),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(reward.amount),
                    style: AppTextStyles.poppinsMoney,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(reward.rank, style: AppTextStyles.interLabel),
                  const SizedBox(height: 4),
                  Text(reward.rank, style: AppTextStyles.poppinsTitleSmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date
          Text(
            'Tanggal Klaim: ${_formatDate(reward.date)}',
            style: AppTextStyles.interCaption,
          ),

          // Bank Info (if available)
          if (reward.bankAccount != null && reward.accountHolder != null) ...[
            const SizedBox(height: 16),
            Divider(color: AppColors.inputBorder, height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Atas Nama', style: AppTextStyles.interLabel),
                    const SizedBox(height: 4),
                    Text(
                      reward.accountHolder!,
                      style: AppTextStyles.interBodyMedium,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Rekening', style: AppTextStyles.interLabel),
                    const SizedBox(height: 4),
                    Text(
                      reward.bankAccount!,
                      style: AppTextStyles.interBodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ],

          // Action Button
          if (reward.status == ClaimStatus.pendingClaim) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ajukan klaim berhasil'),
                      backgroundColor: AppColors.accent,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ajukan Klaim',
                      style: AppTextStyles.poppinsButton.copyWith(fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_giftcard_outlined,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada hadiah',
            style: AppTextStyles.poppinsTitleSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Menangkan kompetisi untuk mendapatkan hadiah',
            style: AppTextStyles.interBody,
          ),
        ],
      ),
    );
  }
}
