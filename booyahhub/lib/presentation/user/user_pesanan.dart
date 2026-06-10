import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_session.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

class UserPesananPage extends StatefulWidget {
  const UserPesananPage({super.key});

  @override
  State<UserPesananPage> createState() => _UserPesananPageState();
}

class _UserPesananPageState extends State<UserPesananPage> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _allPesanan = [];
  List<Map<String, dynamic>> _filteredPesanan = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Filter status (mirip dengan home page)
  String _selectedStatusFilter = 'semua';

  final List<Map<String, String>> _filterOptions = [
    {'value': 'semua', 'label': 'Semua'},
    {'value': 'belum_bayar', 'label': 'Belum Bayar'},
    {'value': 'menunggu', 'label': 'Menunggu'},
    {'value': 'dikonfirmasi', 'label': 'Dikonfirmasi'},
    {'value': 'ditolak', 'label': 'Dibatalkan'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchPesanan();
  }

  Future<void> _fetchPesanan() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _supabase.sessionEmail;
      if (email == null) {
        setState(() {
          _errorMessage = 'Silakan login terlebih dahulu';
          _isLoading = false;
        });
        return;
      }

      final akunResponse = await _supabase
          .from('akun')
          .select('id_akun')
          .eq('email', email!)
          .maybeSingle();

      if (akunResponse == null) {
        setState(() {
          _errorMessage = 'Akun tidak ditemukan';
          _isLoading = false;
        });
        return;
      }

      final int akunId = akunResponse['id_akun'];

      final response = await _supabase
          .from('pendaftaran_tim')
          .select('''
            id_pendaftaran,
            id_sesi,
            status_pembayaran,
            dibuat_pada,
            diverifikasi_pada,
            akun_id,
            bukti_pembayaran,
            nama_kapten,
            whatsapp_kapten,
            id_player_1,
            id_player_2,
            id_player_3,
            id_player_4,
            metode_pembayaran_daftar,
            sesi_scrim (
              id_sesi,
              nama_sesi,
              waktu_mulai,
              waktu_selesai,
              room_id,
              password,
              scrim (
                id_scrim,
                nama_scrim,
                poster,
                biaya_pendaftaran,
                total_hadiah
              )
            ),
            hasil_pertandingan (*),
            klaim_hadiah (*)
          ''')
          .eq('akun_id', akunId)
          .order('dibuat_pada', ascending: false);

      if (response == null || response.isEmpty) {
        setState(() {
          _allPesanan = [];
          _filterPesanan();
          _isLoading = false;
        });
        return;
      }

      final profilResponse = await _supabase
          .from('profil_pengguna')
          .select('nama_tim')
          .eq('akun_id', akunId)
          .maybeSingle();
      
      final String namaTim = profilResponse?['nama_tim'] ?? 'No Team';

      final pesananWithTim = List<Map<String, dynamic>>.from(response);
      for (var pesanan in pesananWithTim) {
        pesanan['nama_tim'] = namaTim;
      }

      setState(() {
        _allPesanan = pesananWithTim;
        _filterPesanan();
        _isLoading = false;
      });
    } catch (e, s) {
      debugPrint('Error fetch pesanan: $e');
      debugPrint(s.toString());
      setState(() {
        _errorMessage = 'Gagal memuat data pesanan: $e';
        _isLoading = false;
      });
    }
  }

  void _filterPesanan() {
    if (_selectedStatusFilter == 'semua') {
      setState(() => _filteredPesanan = _allPesanan);
    } else {
      setState(() {
        _filteredPesanan = _allPesanan
            .where((p) => p['status_pembayaran'] == _selectedStatusFilter)
            .toList();
      });
    }
  }

  // ─── BUILD FILTER CHIP (SAMA SEPERTI HOME PAGE) ───
  Widget _buildFilterChip() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final option = _filterOptions[index];
          final isSelected = _selectedStatusFilter == option['value'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedStatusFilter = option['value']!;
                _filterPesanan();
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: AppConstants.paddingS),
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.inputBorder,
                  width: 1.2,
                ),
              ),
              child: Text(
                option['label']!,
                style: TextStyle(
                  color: isSelected ? AppColors.buttonText : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<String?> _getSignedUrl(String path) async {
    if (path == null || path.isEmpty) return null;
    try {
      final signedUrl = await _supabase.storage
          .from('bukti_bayar')
          .createSignedUrl(path, 3600);
      return signedUrl;
    } catch (e) {
      return null;
    }
  }

  // ─── POP UP DETAIL PESANAN ───
  void _showDetailPopup(Map<String, dynamic> pesanan) {
    final sesi = pesanan['sesi_scrim'] as Map<String, dynamic>?;
    if (sesi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data sesi tidak ditemukan'), backgroundColor: Colors.red),
      );
      return;
    }
    final scrim = sesi['scrim'] as Map<String, dynamic>?;
    if (scrim == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data scrim tidak ditemukan'), backgroundColor: Colors.red),
      );
      return;
    }
    final String namaTim = pesanan['nama_tim'] ?? 'No Team';
    final status = pesanan['status_pembayaran'] ?? 'menunggu';
    
    final waktuMulai = DateTime.tryParse(sesi['waktu_mulai'] ?? '') ?? DateTime.now();
    final waktuSelesai = DateTime.tryParse(sesi['waktu_selesai'] ?? '') ?? DateTime.now();
    
    final hasilList = pesanan['hasil_pertandingan'] as List?;
    final hasil = (hasilList != null && hasilList.isNotEmpty) ? hasilList[0] : null;
    
    final klaimList = pesanan['klaim_hadiah'] as List?;
    final klaim = (klaimList != null && klaimList.isNotEmpty) ? klaimList[0] : null;
    
    final biayaPendaftaran = scrim['biaya_pendaftaran'] ?? 0;
    final totalHadiah = scrim['total_hadiah'] ?? 0;
    
    final buktiPembayaran = pesanan['bukti_pembayaran'] as String?;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusL)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Detail Pesanan', style: AppTextStyles.poppinsSectionTitle.copyWith(fontSize: 18)),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: AppColors.inputBorder),
              const SizedBox(height: AppConstants.paddingS),

              Text('Informasi Scrim', style: AppTextStyles.poppinsTitleSmall),
              const SizedBox(height: AppConstants.paddingS),
              _buildInfoRow(Icons.sports_esports, 'Nama Scrim: ${scrim?['nama_scrim'] ?? '-'}'),
              const SizedBox(height: 6),
              _buildInfoRow(Icons.calendar_today, 'Tanggal: ${_formatDate(waktuMulai)}'),
              const SizedBox(height: 6),
              _buildInfoRow(Icons.access_time, 'Waktu: ${_formatTime(waktuMulai)} - ${_formatTime(waktuSelesai)} WIB'),
              const SizedBox(height: 6),
              _buildInfoRow(Icons.attach_money, 'Biaya Pendaftaran: ${_formatRupiah(biayaPendaftaran)}'),
              const SizedBox(height: 6),
              _buildInfoRow(Icons.emoji_events, 'Total Hadiah: ${_formatRupiah(totalHadiah)}'),
              const SizedBox(height: AppConstants.paddingM),

              const Divider(color: AppColors.inputBorder),
              const SizedBox(height: AppConstants.paddingS),

              Text('Informasi Tim', style: AppTextStyles.poppinsTitleSmall),
              const SizedBox(height: AppConstants.paddingS),
              _buildInfoRow(Icons.group, 'Nama Tim: $namaTim'),
              const SizedBox(height: 6),
              _buildInfoRow(Icons.person, 'Kapten: ${pesanan['nama_kapten'] ?? '-'}'),
              const SizedBox(height: 6),
              _buildInfoRow(Icons.phone, 'WhatsApp: ${pesanan['whatsapp_kapten'] ?? '-'}'),
              const SizedBox(height: AppConstants.paddingM),

              const Divider(color: AppColors.inputBorder),
              const SizedBox(height: AppConstants.paddingS),

              Text('Daftar Player', style: AppTextStyles.poppinsTitleSmall),
              const SizedBox(height: AppConstants.paddingS),
              _buildInfoRow(Icons.person, 'Player 1: ${pesanan['id_player_1'] ?? '-'}'),
              if (pesanan['id_player_2'] != null && pesanan['id_player_2'].toString().isNotEmpty)
                _buildInfoRow(Icons.person, 'Player 2: ${pesanan['id_player_2']}'),
              if (pesanan['id_player_3'] != null && pesanan['id_player_3'].toString().isNotEmpty)
                _buildInfoRow(Icons.person, 'Player 3: ${pesanan['id_player_3']}'),
              if (pesanan['id_player_4'] != null && pesanan['id_player_4'].toString().isNotEmpty)
                _buildInfoRow(Icons.person, 'Player 4: ${pesanan['id_player_4']}'),
              const SizedBox(height: AppConstants.paddingM),

              const Divider(color: AppColors.inputBorder),
              const SizedBox(height: AppConstants.paddingS),

              Text('Status Pembayaran', style: AppTextStyles.poppinsTitleSmall),
              const SizedBox(height: AppConstants.paddingS),
              Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: _getStatusColor(status))),
                  const SizedBox(width: 8),
                  Text(_getStatusDisplay(status), style: AppTextStyles.interBodyMedium.copyWith(color: _getStatusColor(status), fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.payment, 'Metode: ${pesanan['metode_pembayaran_daftar'] ?? '-'}'),
              
              if (buktiPembayaran != null && buktiPembayaran.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Bukti Pembayaran:', style: AppTextStyles.interBodyMedium),
                const SizedBox(height: 8),
                FutureBuilder<String?>(
                  future: _getSignedUrl(buktiPembayaran),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(height: 180, color: AppColors.surface, child: const Center(child: CircularProgressIndicator(color: AppColors.primary)));
                    }
                    final imageUrl = snapshot.data;
                    if (imageUrl == null || imageUrl.isEmpty) {
                      return Container(height: 180, color: AppColors.surface, child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.broken_image, size: 40, color: AppColors.textSecondary), SizedBox(height: 8), Text('Gagal memuat gambar')])));
                    }
                    return Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppConstants.radiusM), border: Border.all(color: AppColors.inputBorder)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                        child: Image.network(imageUrl, height: 180, width: double.infinity, fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : Container(height: 180, color: AppColors.surface, child: const Center(child: CircularProgressIndicator(color: AppColors.primary))),
                          errorBuilder: (context, error, stackTrace) => Container(height: 180, color: AppColors.surface, child: const Center(child: Text('Gagal memuat gambar'))),
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: AppConstants.paddingM),

              if (status == 'dikonfirmasi' && sesi['room_id'] != null && sesi['room_id'].toString().isNotEmpty) ...[
                const Divider(color: AppColors.inputBorder),
                const SizedBox(height: AppConstants.paddingS),
                Text('Informasi Room', style: AppTextStyles.poppinsTitleSmall.copyWith(color: AppColors.primary)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(AppConstants.radiusM)),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.meeting_room, 'Room ID: ${sesi['room_id']}'),
                      if (sesi['password'] != null && sesi['password'].toString().isNotEmpty) const SizedBox(height: 8),
                      if (sesi['password'] != null && sesi['password'].toString().isNotEmpty) _buildInfoRow(Icons.lock, 'Password: ${sesi['password']}'),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.paddingM),
              ],

              if (hasil != null && hasil['peringkat'] != null) ...[
                const Divider(color: AppColors.inputBorder),
                const SizedBox(height: AppConstants.paddingS),
                Text('Hasil Pertandingan', style: AppTextStyles.poppinsTitleSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildResultItemPopup(icon: Icons.emoji_events, label: 'peringkat', value: '#${hasil['peringkat']}', color: Colors.amber)),
                    Expanded(child: _buildResultItemPopup(icon: Icons.sports_esports, label: 'Total Kill', value: '${hasil['total_kill'] ?? 0}', color: Colors.redAccent)),
                    Expanded(child: _buildResultItemPopup(icon: Icons.star, label: 'Total Poin', value: '${hasil['total_poin'] ?? 0}', color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingM),
              ],

              if (hasil != null && hasil['peringkat'] != null && hasil['peringkat'] <= 3) ...[
                const Divider(color: AppColors.inputBorder),
                const SizedBox(height: AppConstants.paddingS),
                Text('Status Klaim Hadiah', style: AppTextStyles.poppinsTitleSmall),
                const SizedBox(height: 12),
                _buildTimelinePopup(klaim),
                const SizedBox(height: AppConstants.paddingM),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppTextStyles.interBodyMedium)),
      ],
    );
  }

  Widget _buildResultItemPopup({required IconData icon, required String label, required String value, required Color color}) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.interCaption),
        Text(value, style: AppTextStyles.poppinsMoneySmall.copyWith(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTimelinePopup(Map<String, dynamic>? klaim) {
    final statusKlaim = klaim?['status_klaim'] ?? 'belum_diajukan';
    
    final List<Map<String, dynamic>> timelineSteps = [
      {'label': 'Klaim Diajukan', 'date': klaim?['diajukan_pada'], 'status': statusKlaim != 'belum_diajukan'},
      {'label': 'Diverifikasi Admin', 'date': klaim?['disetujui_admin_pada'], 'status': statusKlaim == 'disetujui_admin' || statusKlaim == 'dibayar'},
      {'label': 'Pembayaran Diproses', 'date': klaim?['dibayar_pada'], 'status': statusKlaim == 'dibayar'},
    ];

    return Column(
      children: timelineSteps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == timelineSteps.length - 1;
        final isCompleted = step['status'] == true;
        final isActive = !isCompleted && index == timelineSteps.indexWhere((s) => s['status'] == false);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: isCompleted ? Colors.green : (isActive ? Colors.orange : AppColors.textSecondary.withOpacity(0.3))),
                  child: Icon(isCompleted ? Icons.check : Icons.access_time, size: 12, color: Colors.white),
                ),
                if (!isLast) Container(width: 2, height: 40, color: isCompleted ? Colors.green.withOpacity(0.5) : AppColors.textSecondary.withOpacity(0.2)),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step['label'], style: TextStyle(color: isCompleted ? AppColors.textPrimary : (isActive ? Colors.orange : AppColors.textSecondary), fontWeight: isActive ? FontWeight.w600 : FontWeight.normal, fontSize: 13)),
                  if (step['date'] != null) Text(_formatDateTime(DateTime.parse(step['date'])), style: AppTextStyles.interCaption),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _formatRupiah(dynamic value) {
    if (value == null) return 'Rp 0';
    final double nominal = double.tryParse(value.toString()) ?? 0;
    return 'Rp ${nominal.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
  }

  String _formatDate(DateTime date) => '${date.day} ${_getMonth(date.month)} ${date.year}';
  String _formatTime(DateTime time) => '${time.hour.toString().padLeft(2, '0')}.${time.minute.toString().padLeft(2, '0')}';
  String _formatDateTime(DateTime date) => '${date.day} ${_getMonth(date.month)}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  String _getMonth(int month) => const ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'][month - 1];

  String _getStatusDisplay(String status) {
    switch (status) {
      case 'dikonfirmasi': return 'Dikonfirmasi';
      case 'menunggu': return 'Menunggu Verifikasi';
      case 'ditolak': return 'Dibatalkan';
      case 'belum_bayar': return 'Belum Bayar';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'dikonfirmasi': return Colors.green;
      case 'menunggu': return Colors.orange;
      case 'ditolak': return Colors.red;
      case 'belum_bayar': return Colors.amber.shade700;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          const SizedBox(height: AppConstants.paddingS),
          _buildFilterChip(),
          const SizedBox(height: AppConstants.paddingM),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMessage != null
                    ? _buildErrorWidget()
                    : _filteredPesanan.isEmpty
                        ? _buildEmptyState()
                        : _buildPesananList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPesananList() {
    return RefreshIndicator(
      onRefresh: _fetchPesanan,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
        itemCount: _filteredPesanan.length,
        itemBuilder: (context, index) {
          final pesanan = _filteredPesanan[index];
          return _buildPesananCard(pesanan);
        },
      ),
    );
  }

  Widget _buildPesananCard(Map<String, dynamic> pesanan) {
    final sesi = pesanan['sesi_scrim'] as Map<String, dynamic>?;
    final scrim = sesi?['scrim'] as Map<String, dynamic>?;
    final String namaTim = pesanan['nama_tim'] ?? 'No Team';
    final waktuMulai = sesi != null ? (DateTime.tryParse(sesi['waktu_mulai'] ?? '') ?? DateTime.now()) : DateTime.now();
    final status = pesanan['status_pembayaran'] ?? 'menunggu';
    final isConfirmed = status == 'dikonfirmasi';
    final hasRoomId = sesi?['room_id'] != null && sesi!['room_id'].toString().isNotEmpty;
    final hasilList = pesanan['hasil_pertandingan'] as List?;
    final hasil = (hasilList != null && hasilList.isNotEmpty) ? hasilList[0] : null;

    return GestureDetector(
      onTap: () => _showDetailPopup(pesanan),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
        decoration: BoxDecoration(color: AppColors.backgroundCard, borderRadius: BorderRadius.circular(AppConstants.radiusL)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(scrim?['nama_scrim'] ?? 'No Title', style: AppTextStyles.poppinsTitleSmall, overflow: TextOverflow.ellipsis)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingS, vertical: AppConstants.paddingXS),
                        decoration: BoxDecoration(color: _getStatusColor(status).withOpacity(0.2), borderRadius: BorderRadius.circular(AppConstants.radiusXL)),
                        child: Text(_getStatusDisplay(status), style: AppTextStyles.interStatus.copyWith(color: _getStatusColor(status))),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingS),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(_formatDate(waktuMulai), style: AppTextStyles.interCaption),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(_formatTime(waktuMulai), style: AppTextStyles.interCaption),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingXS),
                  Row(
                    children: [
                      Icon(Icons.group, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(namaTim, style: AppTextStyles.interCaption),
                    ],
                  ),
                ],
              ),
            ),
            Container(height: 1, color: AppColors.inputBorder.withOpacity(0.5)),
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [Icon(Icons.info_outline, size: 16, color: AppColors.primary), const SizedBox(width: 4), Text('Ketuk untuk detail', style: AppTextStyles.interCaption.copyWith(color: AppColors.primary))]),
                  if (status == 'belum_bayar')
                    ElevatedButton(
                      onPressed: () => context.push('/user/payment/${pesanan['id_pendaftaran']}', extra: pesanan['id_pendaftaran']),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: const Text('Bayar Sekarang', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  if (isConfirmed && hasRoomId) Row(children: [Icon(Icons.meeting_room, size: 14, color: AppColors.primary), const SizedBox(width: 4), Text('Room tersedia', style: AppTextStyles.interCaption.copyWith(color: AppColors.primary))]),
                  if (hasil != null && hasil['placement'] != null && hasil['placement'] <= 3) Row(children: [Icon(Icons.emoji_events, size: 14, color: Colors.amber), const SizedBox(width: 4), Text('Juara ${hasil['placement']}', style: AppTextStyles.interCaption.copyWith(color: Colors.amber))]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textDisabled),
          const SizedBox(height: AppConstants.paddingM),
          Text('Belum ada pesanan', style: AppTextStyles.poppinsTitleSmall),
          const SizedBox(height: AppConstants.paddingS),
          Text('Ikuti scrim dan lihat pesananmu di sini', style: AppTextStyles.interBody),
          const SizedBox(height: AppConstants.paddingL),
          ElevatedButton(
            onPressed: () => context.pushNamed('scrim_page'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.buttonText),
            child: const Text('Cari Scrim'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: AppConstants.paddingM),
          Text(_errorMessage ?? 'Terjadi kesalahan', style: AppTextStyles.interBody, textAlign: TextAlign.center),
          const SizedBox(height: AppConstants.paddingL),
          ElevatedButton(
            onPressed: _fetchPesanan,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.buttonText),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}