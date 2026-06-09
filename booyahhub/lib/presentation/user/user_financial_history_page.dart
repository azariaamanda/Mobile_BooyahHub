import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_session.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/transaksi_keuangan_model.dart';
import '../../data/models/services/keuangan_service.dart';
import 'user_widgets/transaction_card.dart';
import 'user_widgets/filter_chip_widget.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final KeuanganService _keuanganService = KeuanganService();
  final _supabase = Supabase.instance.client;

  int? _idAkun; // Make _idAkun nullable
  List<TransaksiKeuangan> _transaksi = [];

  String _selectedType = 'semua';
  String _selectedStatus = 'semua';
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  final List<Map<String, String>> _typeFilters = [
    {'value': 'semua', 'label': 'Semua'},
    {'value': 'pemasukan', 'label': 'Pemasukan'},
    {'value': 'penarikan', 'label': 'Penarikan'},
    {'value': 'hadiah', 'label': 'Hadiah'},
  ];

  final List<Map<String, String>> _statusFilters = [
    {'value': 'semua', 'label': 'Semua'},
    {'value': 'berhasil', 'label': 'Berhasil'},
    {'value': 'pending', 'label': 'Menunggu'},
    {'value': 'gagal', 'label': 'Gagal'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    try {
      final email = _supabase.sessionEmail;
      if (email == null) {
        throw Exception('User tidak ditemukan');
      }

      final akunResponse = await _supabase
          .from('akun')
          .select('id_akun')
          .eq('email', email!)
          .maybeSingle();

      if (akunResponse == null) {
        throw Exception('Data akun tidak ditemukan');
      }

      _idAkun = akunResponse['id_akun'] as int; // Cast to int
      await _loadData();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final idAkun = _idAkun;
      if (idAkun == null) {
        setState(() {
          _hasError = true;
          _errorMessage = 'ID Akun tidak tersedia. Silakan coba login ulang.';
          _isLoading = false;
        });
        return;
      }

      final typeFilter = _selectedType == 'semua' ? null : _selectedType;
      final statusFilter = _selectedStatus == 'semua' ? null : _selectedStatus;

      final transaksi = await _keuanganService.fetchTransaksiPengguna(
        idAkun,
        tipeFilter: typeFilter,
        statusFilter: statusFilter,
        limit: 500,
      );

      setState(() {
        _transaksi = transaksi;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Riwayat Transaksi'), elevation: 0),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Riwayat Transaksi')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error.withOpacity(0.5),
              ),
              const SizedBox(height: AppConstants.paddingL),
              Text('Gagal memuat data', style: AppTextStyles.poppinsTitle),
              const SizedBox(height: AppConstants.paddingS),
              Text(
                _errorMessage,
                style: AppTextStyles.interCaption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.paddingL),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi'), elevation: 0),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Filter
              Text('Filter Jenis', style: AppTextStyles.poppinsTitleSmall),
              const SizedBox(height: AppConstants.paddingM),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ..._typeFilters.map((filter) {
                      final isSelected = _selectedType == filter['value'];
                      return Padding(
                        padding: const EdgeInsets.only(
                          right: AppConstants.paddingS,
                        ),
                        child: AppFilterChip(
                          // AppFilterChip adalah child dari Padding
                          label: filter['label']!,
                          isSelected: isSelected,
                          onPressed: () {
                            setState(() {
                              _selectedType = filter['value']!;
                            });
                            _loadData();
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.paddingL),

              // Status Filter
              Text('Filter Status', style: AppTextStyles.poppinsTitleSmall),
              const SizedBox(height: AppConstants.paddingM),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ..._statusFilters.map((filter) {
                      final isSelected = _selectedStatus == filter['value'];
                      return Padding(
                        padding: const EdgeInsets.only(
                          right: AppConstants.paddingS,
                        ),
                        child: AppFilterChip(
                          // AppFilterChip adalah child dari Padding
                          label: filter['label']!,
                          isSelected: isSelected,
                          onPressed: () {
                            setState(() {
                              _selectedStatus = filter['value']!;
                            });
                            _loadData();
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.paddingL),

              // Transaction Count
              Text(
                'Total Transaksi: ${_transaksi.length}',
                style: AppTextStyles.interCaption,
              ),
              const SizedBox(height: AppConstants.paddingM),

              // Transaction List
              if (_transaksi.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingL),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: AppColors.textSecondary.withOpacity(0.3),
                        ),
                        const SizedBox(height: AppConstants.paddingM),
                        Text(
                          'Belum ada transaksi',
                          style: AppTextStyles.poppinsTitle.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    ..._transaksi.asMap().entries.map((entry) {
                      final transaksi = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppConstants.paddingM,
                        ),
                        child: TransactionCard(
                          transaksi: transaksi,
                          onTap: () {
                            context.push('/financial/detail', extra: transaksi);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              const SizedBox(height: AppConstants.paddingL),
            ],
          ),
        ),
      ),
    );
  }
}
