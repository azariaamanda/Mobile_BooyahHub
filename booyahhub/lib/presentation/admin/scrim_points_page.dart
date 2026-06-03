import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';

class ScrimPointsPage extends StatefulWidget {
  final int scrimId;
  const ScrimPointsPage({super.key, required this.scrimId});

  @override
  State<ScrimPointsPage> createState() => _ScrimPointsPageState();
}

class _ScrimPointsPageState extends State<ScrimPointsPage> {
  int _selectedMatch = 0;

  final List<Map<String, dynamic>> _teams = [
    {
      'nama_tim': 'EVOS Divine',
      'kapten': 'Sam13',
      'place': null,
      'kill': 0,
      'poin': 0,
    },
    {
      'nama_tim': 'RRQ Kazu',
      'kapten': 'Sisi',
      'place': 1,
      'kill': 10,
      'poin': 22,
    },
    {
      'nama_tim': 'Genesis Dogma',
      'kapten': 'Upin',
      'place': 12,
      'kill': 1,
      'poin': 1,
    },
  ];

  final List<Map<String, int>> _poinSystem = [
    {'place': 1, 'poin': 12},
    {'place': 2, 'poin': 10},
    {'place': 3, 'poin': 8},
    {'place': 4, 'poin': 7},
    {'place': 5, 'poin': 6},
    {'place': 6, 'poin': 5},
    {'place': 7, 'poin': 4},
    {'place': 8, 'poin': 3},
    {'place': 9, 'poin': 2},
    {'place': 10, 'poin': 1},
    {'place': 11, 'poin': 0},
    {'place': 12, 'poin': 0},
  ];

  final List<TextEditingController> _killControllers = [];

  @override
  void initState() {
    super.initState();
    for (var team in _teams) {
      _killControllers.add(
        TextEditingController(text: team['kill'].toString()),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _killControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updatePlace(int index, int? place) {
    setState(() {
      _teams[index]['place'] = place;
      _updatePoin(index);
    });
  }

  void _updateKill(int index, int kill) {
    setState(() {
      _teams[index]['kill'] = kill;
      _killControllers[index].text = kill.toString();
      _updatePoin(index);
    });
  }

  void _updatePoin(int index) {
    int poinPlacement = 0;
    if (_teams[index]['place'] != null) {
      final found = _poinSystem.firstWhere(
        (p) => p['place'] == _teams[index]['place'],
      );
      poinPlacement = found['poin'] ?? 0;
    }
    final totalPoin = poinPlacement + (_teams[index]['kill'] ?? 0);
    _teams[index]['poin'] = totalPoin;
  }

  int get _totalTim => _teams.length;
  int get _sudahDiisi => _teams.where((t) => t['place'] != null).length;
  int get _belumDiisi => _totalTim - _sudahDiisi;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header yang bisa di-scroll
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Statistik card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        _statCard('Total Tim', _totalTim.toString()),
                        const SizedBox(width: 6),
                        _statCard('Sudah Diisi', _sudahDiisi.toString()),
                        const SizedBox(width: 6),
                        _statCard('Belum Diisi', _belumDiisi.toString()),
                      ],
                    ),
                  ),

                  // Match selector
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: List.generate(
                        4,
                        (i) => Expanded(
                          child: _matchButton(i + 1, _selectedMatch, (match) {
                            setState(() => _selectedMatch = match - 1);
                          }),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Daftar tim
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    itemCount: _teams.length,
                    itemBuilder: (context, i) {
                      final team = _teams[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.surfaceVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              team['nama_tim'],
                              style: AppTextStyles.poppinsTitleSmall.copyWith(
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '& Capt: ${team['kapten']}',
                              style: AppTextStyles.interCaption.copyWith(
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Place
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Place',
                                        style: AppTextStyles.interLabel
                                            .copyWith(fontSize: 10),
                                      ),
                                      const SizedBox(height: 2),
                                      _buildPlaceDropdown(
                                        team['place'],
                                        (place) => _updatePlace(i, place),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Kill
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Kill',
                                        style: AppTextStyles.interLabel
                                            .copyWith(fontSize: 10),
                                      ),
                                      const SizedBox(height: 2),
                                      _buildKillField(
                                        i,
                                        team['kill'],
                                        (kill) => _updateKill(i, kill),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Poin
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Poin',
                                        style: AppTextStyles.interLabel
                                            .copyWith(fontSize: 10),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(
                                            0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${team['poin']}',
                                            style: AppTextStyles
                                                .poppinsMoneyLarge
                                                .copyWith(fontSize: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Tombol Simpan
          Container(
            margin: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Skor berhasil disimpan (Demo)',
                        style: AppTextStyles.interBody,
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                ),
                child: Text(
                  'SIMPAN SEMUA POIN',
                  style: AppTextStyles.poppinsButton.copyWith(fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.poppinsMoneyLarge.copyWith(fontSize: 16),
            ),
            Text(
              label,
              style: AppTextStyles.interCaption.copyWith(fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  Widget _matchButton(int match, int selectedMatch, Function(int) onTap) {
    final isSelected = selectedMatch == match - 1;
    return GestureDetector(
      onTap: () => onTap(match),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.primary),
        ),
        child: Center(
          child: Text(
            'Match $match',
            style: AppTextStyles.interBodyMedium.copyWith(
              color: isSelected ? Colors.black : AppColors.primary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceDropdown(int? currentPlace, Function(int?) onChanged) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: currentPlace,
          isExpanded: true,
          dropdownColor: AppColors.backgroundCard,
          style: AppTextStyles.interInput.copyWith(fontSize: 12),
          hint: Text(
            'Pilih',
            style: AppTextStyles.interHint.copyWith(fontSize: 11),
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Pilih Place', style: TextStyle(fontSize: 11)),
            ),
            ..._poinSystem.map(
              (p) => DropdownMenuItem(
                value: p['place'],
                child: Text(
                  '#${p['place']} - ${p['poin']} Poin',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildKillField(int index, int currentKill, Function(int) onChanged) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _killControllers[index],
              textAlign: TextAlign.center,
              style: AppTextStyles.interInput.copyWith(fontSize: 13),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (value) {
                final kill = int.tryParse(value) ?? 0;
                onChanged(kill);
              },
            ),
          ),
        ],
      ),
    );
  }
}
