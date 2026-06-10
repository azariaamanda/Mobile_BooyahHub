import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_constants.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/services/admin_utang_service.dart';

// ─── Page ────────────────────────────────────────────────────────────────────
class AdminVerificationPage extends StatefulWidget {
  const AdminVerificationPage({super.key});
  @override
  State<AdminVerificationPage> createState() => _AdminVerificationPageState();
}

class _AdminVerificationPageState extends State<AdminVerificationPage> {
  final AdminUtangService _adminService = AdminUtangService();
  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _filteredAdmins = [];
  bool _isLoading = true;
  String _selectedFilter = 'Semua';
  String _searchQuery = '';

  final List<String> _filters = ['Semua', 'Aktif', 'Suspended', 'Utang tinggi'];

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
  }

  Future<void> _fetchAdmins() async {
    setState(() => _isLoading = true);
    final admins = await _adminService.getAllAdminWithUtang();
    setState(() {
      _admins = admins;
      _applyFilter();
      _isLoading = false;
    });
  }

  void _applyFilter() {
    List<Map<String, dynamic>> filtered = List.from(_admins);
    switch (_selectedFilter) {
      case 'Aktif':
        filtered = filtered.where((a) =>
          (a['status_akun']?.toString().toLowerCase() ?? '') == 'aktif').toList();
        break;
      case 'Suspended':
        filtered = filtered.where((a) =>
          (a['status_akun']?.toString().toLowerCase() ?? '') == 'suspended').toList();
        break;
      case 'Utang tinggi':
        filtered = filtered.where((a) {
          final utang = a['profil_admin']?['total_utang'] ?? 0;
          final limit = a['profil_admin']?['limit_utang'] ?? 100000;
          return utang >= limit;
        }).toList();
        break;
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((a) {
        final profil = a['profil_admin'] as Map<String, dynamic>?;
        final nama  = profil?['nama_lengkap']?.toString().toLowerCase() ?? '';
        final email = a['email']?.toString().toLowerCase() ?? '';
        final q = _searchQuery.toLowerCase();
        return nama.contains(q) || email.contains(q);
      }).toList();
    }
    setState(() => _filteredAdmins = filtered);
  }

  void _onFilterChanged(String f) {
    setState(() => _selectedFilter = f);
    _applyFilter();
  }

  void _onSearchChanged(String q) {
    _searchQuery = q;
    _applyFilter();
  }

  String _formatRupiah(dynamic value) {
    final n = (value ?? 0).toDouble().toInt();
    return 'Rp ${n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
  }

  String _resolveStatus(Map<String, dynamic> admin) {
    final profil     = admin['profil_admin'] as Map<String, dynamic>?;
    final totalUtang = (profil?['total_utang'] ?? 0).toDouble();
    final limitUtang = (profil?['limit_utang'] ?? 100000).toDouble();
    final status     = admin['status_akun']?.toString().toLowerCase() ?? 'pending';
    return (totalUtang >= limitUtang && status == 'aktif') ? 'suspended' : status;
  }

  bool _isSuspended(String status) => status.toLowerCase() == 'suspended';

  Widget _buildStatusBadge(String status) {
    final suspended = _isSuspended(status);
    final aktif = status.toLowerCase() == 'aktif';

    final Color bg = suspended 
        ? AppColors.error.withOpacity(0.15) 
        : aktif 
            ? AppColors.success.withOpacity(0.15) 
            : AppColors.primary.withOpacity(0.15);
    final Color fg = suspended 
        ? AppColors.error 
        : aktif 
            ? AppColors.success 
            : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: suspended ? Border.all(color: AppColors.error, width: 1.5) : null,
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.interStatus.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> admin) {
    final profil = admin['profil_admin'] as Map<String, dynamic>?;
    final nama = profil?['nama_lengkap'] ?? 'Admin';
    final email = admin['email'] ?? '';
    final totalUtang = (profil?['total_utang'] ?? 0).toDouble();
    final status = _resolveStatus(admin);
    final suspended = _isSuspended(status);

    return GestureDetector(
      onTap: () {
        context.push(
          '/owner/verifikasi-pembayaran',
          extra: {
            'id_akun': admin['id_akun'],
            'nama_lengkap': nama,
            'email': email,
            'status_akun': status,
            'total_utang': totalUtang,
            'limit_utang': profil?['limit_utang'] ?? 100000,
          },
        ).then((_) => _fetchAdmins());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nama, style: AppTextStyles.poppinsTitleSmall.copyWith(fontSize: 18)),
                      const SizedBox(height: 3),
                      Text(email, style: AppTextStyles.interCaption),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOTAL UTANG', style: AppTextStyles.interCaption.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  _formatRupiah(totalUtang),
                  style: suspended 
                      ? AppTextStyles.poppinsMoneySmall.copyWith(color: AppColors.error, fontSize: 18)
                      : AppTextStyles.poppinsMoneySmall.copyWith(color: AppColors.primary, fontSize: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label) {
    final isSelected = _selectedFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onFilterChanged(label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            label,
            style: isSelected 
                ? AppTextStyles.interBodyMedium.copyWith(color: AppColors.primary)
                : AppTextStyles.interBody.copyWith(color: AppColors.textHint),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: const Icon(Icons.arrow_back, color: Color(0xFFFFD700), size: 24),
            ),
            const SizedBox(width: 12),
            Text('LIST ADMIN', style: AppTextStyles.poppinsHeadline.copyWith( color: Color(0xFFFFD700), fontSize: 20)),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundInput,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: _onSearchChanged,
                style: AppTextStyles.interInput,
                decoration: InputDecoration(
                  hintText: 'Cari admin..',
                  hintStyle: AppTextStyles.interHint,
                  prefixIcon: const Icon(Icons.search, color: AppColors.textHint, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
            ),
            child: Row(
              children: _filters.map((f) => _buildFilterTab(f)).toList(),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _filteredAdmins.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off_outlined, size: 64, color: AppColors.textHint),
                            const SizedBox(height: 12),
                            Text(
                              'Tidak ada admin ditemukan',
                              style: AppTextStyles.interBody.copyWith(color: AppColors.textHint),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: _filteredAdmins.length,
                        itemBuilder: (_, i) => _buildCard(_filteredAdmins[i]),
                      ),
          ),
        ],
      ),
    );
  }
}