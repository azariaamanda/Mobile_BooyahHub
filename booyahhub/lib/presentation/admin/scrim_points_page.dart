import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

class ScrimPointsPage extends StatefulWidget {
  final int sesiId;
  const ScrimPointsPage({super.key, required this.sesiId});

  @override
  State<ScrimPointsPage> createState() => _ScrimPointsPageState();
}

class _ScrimPointsPageState extends State<ScrimPointsPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  List<Map<String, dynamic>> _teams = [];
  List<Map<String, dynamic>> _poinSystem = [];
  List<TextEditingController> _killControllers = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    for (var controller in _killControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Ambil sistem poin DULU
      final poinData = await _supabase
          .from('sistem_poin')
          .select('placement, poin_placement')
          .order('placement', ascending: true);

      _poinSystem = List<Map<String, dynamic>>.from(poinData);

      // Jika kosong, insert default
      if (_poinSystem.isEmpty) {
        print('Sistem poin kosong, membuat default...');
        final List<Map<String, dynamic>> defaults = [];
        final poinValues = [12, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, 0];
        for (int i = 0; i < 12; i++) {
          defaults.add({
            'placement': i + 1,
            'poin_placement': poinValues[i],
            'is_default': true,
          });
        }
        await _supabase.from('sistem_poin').insert(defaults);

        final newPoinData = await _supabase
            .from('sistem_poin')
            .select('placement, poin_placement')
            .order('placement', ascending: true);
        _poinSystem = List<Map<String, dynamic>>.from(newPoinData);
      }

      // 2. Baru fetch teams (butuh _poinSystem sudah terisi)
      await _fetchTeamsData(widget.sesiId);
    } catch (e) {
      print('Error fetchData: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchTeamsData(int sesiId) async {
    try {
      final pendaftaran = await _supabase
          .from('pendaftaran_tim')
          .select('id_pendaftaran, akun_id, nama_kapten')
          .eq('id_sesi', sesiId)
          .eq('status_pembayaran', 'dikonfirmasi');

      final hasil = await _supabase
          .from('hasil_pertandingan')
          .select('*')
          .eq('id_sesi', sesiId)
          .eq('match_ke', 1);

      List<Map<String, dynamic>> teamList = [];
      final newControllers = <TextEditingController>[];

      for (var p in pendaftaran) {
        final akunId = p['akun_id'] as int?;
        String namaTim = 'Tim ${akunId ?? '?'}';

        if (akunId != null) {
          final profilData = await _supabase
              .from('profil_pengguna')
              .select('nama_tim')
              .eq('akun_id', akunId)
              .maybeSingle();

          if (profilData != null && profilData['nama_tim'] != null) {
            namaTim = profilData['nama_tim'];
          }
        }

        final existingHasil = hasil.firstWhere(
          (h) => h['id_pendaftaran'] == p['id_pendaftaran'],
          orElse: () => {},
        );

        final kill = existingHasil.isEmpty ? 0 : (existingHasil['total_kill'] ?? 0);
        final place = existingHasil.isEmpty ? null : existingHasil['placement'];

        int poinPlacement = 0;
        if (place != null) {
          final found = _poinSystem.firstWhere(
            (ps) => ps['placement'] == place,
            orElse: () => {'poin_placement': 0},
          );
          poinPlacement = found['poin_placement'] ?? 0;
        }
        final totalPoin = poinPlacement + (kill as int);

        teamList.add({
          'id_pendaftaran': p['id_pendaftaran'],
          'akun_id': akunId,
          'nama_tim': namaTim,
          'kapten': p['nama_kapten'] ?? '',
          'place': place,
          'kill': kill,
          'poin': totalPoin,
        });
        newControllers.add(TextEditingController(text: kill.toString()));
      }

      // Dispose controller lama sebelum diganti
      for (var c in _killControllers) {
        c.dispose();
      }

      setState(() {
        _teams = teamList;
        _killControllers = newControllers;
      });
    } catch (e) {
      print('Error fetchTeamsData: $e');
      setState(() => _teams = []);
    }
  }

  Future<void> _saveScores() async {
    if (_teams.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      const matchKe = 1;

      for (int i = 0; i < _teams.length; i++) {
        final team = _teams[i];
        final place = team['place'];
        final kill = int.tryParse(_killControllers[i].text) ?? 0;

        int poinPlacement = 0;
        if (place != null) {
          final found = _poinSystem.firstWhere(
            (ps) => ps['placement'] == place,
            orElse: () => {'poin_placement': 0},
          );
          poinPlacement = found['poin_placement'] ?? 0;
        }
        final totalPoin = poinPlacement + kill;

        final existing = await _supabase
            .from('hasil_pertandingan')
            .select()
            .eq('id_pendaftaran', team['id_pendaftaran'])
            .eq('match_ke', matchKe)
            .maybeSingle();

        if (existing != null) {
          await _supabase.from('hasil_pertandingan').update({
            'placement': place,
            'poin_placement': poinPlacement,
            'total_kill': kill,
            'total_poin': totalPoin,
          }).eq('id_hasil', existing['id_hasil']);
        } else {
          await _supabase.from('hasil_pertandingan').insert({
            'id_pendaftaran': team['id_pendaftaran'],
            'id_sesi': widget.sesiId,
            'match_ke': matchKe,
            'placement': place,
            'poin_placement': poinPlacement,
            'total_kill': kill,
            'total_poin': totalPoin,
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Skor berhasil disimpan'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      await _fetchTeamsData(widget.sesiId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
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
        (p) => p['placement'] == _teams[index]['place'],
        orElse: () => {'poin_placement': 0},
      );
      poinPlacement = found['poin_placement'] ?? 0;
    }
    _teams[index]['poin'] = poinPlacement + (_teams[index]['kill'] ?? 0);
  }

  int get _totalTim => _teams.length;
  int get _sudahDiisi => _teams.where((t) => t['place'] != null).length;
  int get _belumDiisi => _totalTim - _sudahDiisi;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text('Belum ada tim terdaftar', style: AppTextStyles.interBody),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
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

                  const SizedBox(height: 12),

                  // Daftar tim
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                            Text(team['nama_tim'],
                                style: AppTextStyles.poppinsTitleSmall.copyWith(fontSize: 14)),
                            Text('& Capt: ${team['kapten']}',
                                style: AppTextStyles.interCaption.copyWith(fontSize: 11)),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Place',
                                          style: AppTextStyles.interLabel.copyWith(fontSize: 10)),
                                      const SizedBox(height: 2),
                                      _buildPlaceDropdown(
                                          team['place'], (place) => _updatePlace(i, place)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Kill',
                                          style: AppTextStyles.interLabel.copyWith(fontSize: 10)),
                                      const SizedBox(height: 2),
                                      _buildKillField(
                                          i, team['kill'], (kill) => _updateKill(i, kill)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Poin',
                                          style: AppTextStyles.interLabel.copyWith(fontSize: 10)),
                                      const SizedBox(height: 2),
                                      Container(
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${team['poin']}',
                                            style: AppTextStyles.poppinsMoneyLarge
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
                onPressed: _saveScores,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                ),
                child: Text('SIMPAN SEMUA POIN',
                    style: AppTextStyles.poppinsButton.copyWith(fontSize: 13)),
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
            Text(value, style: AppTextStyles.poppinsMoneyLarge.copyWith(fontSize: 16)),
            Text(label, style: AppTextStyles.interCaption.copyWith(fontSize: 9)),
          ],
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
          hint: Text('Pilih', style: AppTextStyles.interHint.copyWith(fontSize: 11)),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Pilih Place', style: TextStyle(fontSize: 11)),
            ),
            ..._poinSystem.map((p) => DropdownMenuItem<int?>(
                  value: p['placement'] as int,
                  child: Text(
                    '#${p['placement']} - ${p['poin_placement']} Poin',
                    style: const TextStyle(fontSize: 11),
                  ),
                )),
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
    );
  }
}