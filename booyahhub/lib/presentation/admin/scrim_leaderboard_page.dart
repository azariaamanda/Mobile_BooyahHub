import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';

class ScrimLeaderboardPage extends StatefulWidget {
  final int scrimId;
  const ScrimLeaderboardPage({super.key, required this.scrimId});

  @override
  State<ScrimLeaderboardPage> createState() => _ScrimLeaderboardPageState();
}

class _ScrimLeaderboardPageState extends State<ScrimLeaderboardPage> {
  final List<Map<String, dynamic>> _leaderboardData = [
    {'pos': 1, 'team': 'TEAM RUU',      'player': 'RRQKAZU',         'kills': 185, 'poin': 150, 'isMyTeam': false},
    {'pos': 2, 'team': 'RRQ KAZU',      'player': null,               'kills': null,'poin': 150, 'isMyTeam': false},
    {'pos': 3, 'team': 'GENESIS DOGMA', 'player': null,               'kills': null,'poin': 142, 'isMyTeam': false},
    {'pos': 4, 'team': 'EVOS Divine',   'player': 'Capt: Sam13',      'kills': 15,  'poin': 130, 'isMyTeam': false},
    {'pos': 5, 'team': 'Team Evos C',   'player': 'YOUR TEAM',        'kills': 15,  'poin': 125, 'isMyTeam': true},
    {'pos': 6, 'team': 'Team Ganteng B','player': 'Capt: Admin_01',   'kills': 12,  'poin': 110, 'isMyTeam': false},
    {'pos': 7, 'team': 'Team Liquid',   'player': 'Capt: Horseman',   'kills': 10,  'poin': 98,  'isMyTeam': false},
  ];

  // ── Avatar placeholder dengan inisial tim ───────────────────────────────
  Widget _avatar(String teamName, double size, {Color? borderColor}) {
    final initials = teamName.trim().split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceVariant,
        border: Border.all(
          color: borderColor ?? AppColors.inputBorder,
          width: borderColor != null ? 2.5 : 1.5,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: borderColor ?? AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.3,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top3 = _leaderboardData.take(3).toList();
    final rest = _leaderboardData.skip(3).toList();

    // Urutan podium: [1]=rank2(kiri), [0]=rank1(tengah), [2]=rank3(kanan)
    final podiumOrder = [top3[1], top3[0], top3[2]];
    final podiumColors = [
      const Color(0xFFC0C0C0), // silver - kiri
      const Color(0xFFC9A227), // gold  - tengah
      const Color(0xFFCD7F32), // bronze- kanan
    ];
    final podiumRanks = [2, 1, 3];
    final podiumHeights = [90.0, 120.0, 75.0]; // tinggi podium bawah avatar

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── PODIUM TOP 3 ───────────────────────────────────────────────
            _buildPodium(podiumOrder, podiumColors, podiumRanks, podiumHeights),

            const SizedBox(height: 28),

            // ── TABEL SISA ─────────────────────────────────────────────────
            if (rest.isNotEmpty) _buildTable(rest),
          ],
        ),
      ),
    );
  }

  // ─── PODIUM ──────────────────────────────────────────────────────────────

  Widget _buildPodium(
    List<Map<String, dynamic>> order,
    List<Color> colors,
    List<int> ranks,
    List<double> podiumHeights,
  ) {
    return SizedBox(
      height: 260,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          final item   = order[i];
          final color  = colors[i];
          final rank   = ranks[i];
          final isCenter = rank == 1;

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // ── Avatar + mahkota (hanya rank 1) ──────────────────────
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    // Avatar
                    _avatar(
                      item['team'],
                      isCenter ? 72 : 52,
                      borderColor: color,
                    ),
                    // Mahkota rank 1
                    if (isCenter)
                      Positioned(
                        top: -22,
                        child: _crownIcon(color),
                      ),
                    // Badge nomor rank 2 & 3
                    if (!isCenter)
                      Positioned(
                        bottom: -2,
                        right: isCenter ? null : 8,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.background, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              '$rank',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // ── Nama Tim ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    item['team'],
                    style: AppTextStyles.poppinsTitleSmall.copyWith(
                      fontSize: isCenter ? 13 : 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 4),

                // ── Poin / kills ──────────────────────────────────────────
                Text(
                  '${item['kills'] ?? item['poin']}',
                  style: AppTextStyles.poppinsMoneyLarge.copyWith(
                    fontSize: isCenter ? 28 : 20,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                // ── Podium blok ───────────────────────────────────────────
                Container(
                  height: podiumHeights[i],
                  width: double.infinity,
                  margin: EdgeInsets.only(
                    left: isCenter ? 0 : (i == 0 ? 0 : 0),
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    border: Border(
                      top:   BorderSide(color: color, width: 2),
                      left:  BorderSide(color: color.withOpacity(0.3), width: 1),
                      right: BorderSide(color: color.withOpacity(0.3), width: 1),
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: isCenter ? 22 : 17,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // Mahkota SVG-like pakai CustomPaint
  Widget _crownIcon(Color color) {
    return Icon(Icons.workspace_premium_rounded, color: color, size: 28);
  }

  // ─── TABEL ───────────────────────────────────────────────────────────────

  Widget _buildTable(List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              border: Border(
                bottom: BorderSide(color: AppColors.surfaceVariant),
              ),
            ),
            child: Row(
              children: [
                _headerCell('POS', width: 38),
                const SizedBox(width: 12),
                Expanded(child: _headerText('TEAM / PLAYER')),
                _headerCell('KILLS', width: 46),
                const SizedBox(width: 8),
                _headerCell('POIN', width: 46),
              ],
            ),
          ),

          // Rows
          ...items.asMap().entries.map((e) {
            final i    = e.key;
            final item = e.value;
            final isLast    = i == items.length - 1;
            final isMyTeam  = item['isMyTeam'] == true;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
              decoration: BoxDecoration(
                color: isMyTeam
                    ? AppColors.primary.withOpacity(0.07)
                    : Colors.transparent,
                borderRadius: isLast
                    ? const BorderRadius.vertical(bottom: Radius.circular(13))
                    : BorderRadius.zero,
                border: !isLast
                    ? Border(
                        bottom: BorderSide(color: AppColors.surfaceVariant),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  // POS
                  SizedBox(
                    width: 38,
                    child: Center(
                      child: Text(
                        '${item['pos']}',
                        style: AppTextStyles.poppinsTitleSmall.copyWith(
                          color: isMyTeam ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Avatar
                  _avatar(item['team'], 34,
                      borderColor: isMyTeam ? AppColors.primary : null),
                  const SizedBox(width: 10),

                  // Team + player
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['team'],
                          style: AppTextStyles.poppinsTitleSmall.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item['player'] != null && (item['player'] as String).isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item['player'],
                            style: AppTextStyles.interCaption.copyWith(
                              fontSize: 10.5,
                              color: isMyTeam
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: isMyTeam ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // KILLS
                  SizedBox(
                    width: 46,
                    child: Center(
                      child: Text(
                        item['kills'] != null ? '${item['kills']}' : '-',
                        style: AppTextStyles.interBody.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // POIN
                  SizedBox(
                    width: 46,
                    child: Center(
                      child: Text(
                        '${item['poin']}',
                        style: AppTextStyles.poppinsMoneySmall.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isMyTeam ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {required double width}) {
    return SizedBox(
      width: width,
      child: Center(child: _headerText(text)),
    );
  }

  Widget _headerText(String text) {
    return Text(
      text,
      style: AppTextStyles.interLabel.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 0.5,
      ),
    );
  }
}