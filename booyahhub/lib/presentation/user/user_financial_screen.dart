import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/saldo_pengguna_model.dart';
import '../../data/models/transaksi_keuangan_model.dart';
import '../../data/models/services/keuangan_service.dart';
import 'user_widgets/balance_card.dart';
import 'user_widgets/transaction_card.dart';
import 'user_widgets/statistic_card.dart';
import 'user_widgets/filter_chip_widget.dart';

class UserFinancialScreen extends StatefulWidget {
  const UserFinancialScreen({super.key});

  @override
  State<UserFinancialScreen> createState() => _UserFinancialScreenState();
}

class _UserFinancialScreenState extends State<UserFinancialScreen> {
  final KeuanganService _keuanganService = KeuanganService();
  final _supabase = Supabase.instance.client;

  int? _idAkun;
  SaldoPengguna? _saldo;
  List<TransaksiKeuangan> _transaksi = [];
  Map<String, dynamic> _statistik = {};
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
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User tidak ditemukan');
      }

      // Get akun ID dari email
      final akunResponse = await _supabase
          .from('akun')
          .select('id_akun')
          .eq('email', currentUser.email!)
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

      final saldo = await _keuanganService.fetchSaldoPengguna(idAkun);

      final typeFilter = _selectedType == 'semua' ? null : _selectedType;
      final statusFilter = _selectedStatus == 'semua' ? null : _selectedStatus;

      final transaksi = await _keuanganService.fetchTransaksiPengguna(
        idAkun,
        tipeFilter: typeFilter,
        statusFilter: statusFilter,
        limit: 100,
      );

      final statistik = await _keuanganService.fetchStatistikKeuangan(idAkun);

      setState(() {
        _saldo = saldo;
        _transaksi = transaksi;
        _statistik = statistik;
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

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}';
  }

  void _handleWithdraw() {
    if (_saldo == null || _saldo!.saldoBisaDitarik <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saldo tidak cukup untuk melakukan penarikan'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Kirim objek saldo langsung, jangan dibungkus Map agar sesuai dengan AppRouter
    context.push('/financial/withdraw', extra: _saldo);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Keuangan'), elevation: 0),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      );
    }

    if (_hasError || _saldo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Keuangan')),
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
      appBar: AppBar(title: const Text('Keuangan'), elevation: 0),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              BalanceCard(
                saldoTotal: _saldo?.saldoTotal ?? 0,
                saldoBisaDitarik: _saldo?.saldoBisaDitarik ?? 0,
                saldoDitahan: _saldo?.saldoDitahan ?? 0,
                saldoHadiah: _saldo?.saldoKlaimHadiah ?? 0,
                onWithdrawPressed: _handleWithdraw,
              ),
              const SizedBox(height: AppConstants.paddingL),

              // Statistik Section
              Text(
                'Statistik Keuangan',
                style: AppTextStyles.poppinsSectionTitle,
              ),
              const SizedBox(height: AppConstants.paddingM),
              Row(
                children: [
                  StatisticCard(
                    title: 'Total Pemasukan',
                    amount: _formatCurrency(_statistik['total_pemasukan'] ?? 0),
                    icon: Icons.call_received,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppConstants.paddingM),
                  StatisticCard(
                    title: 'Total Penarikan',
                    amount: _formatCurrency(_statistik['total_penarikan'] ?? 0),
                    icon: Icons.call_made,
                    color: AppColors.accentRed,
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingM),
              Row(
                children: [
                  StatisticCard(
                    title: 'Total Hadiah',
                    amount: _formatCurrency(_statistik['total_hadiah'] ?? 0),
                    icon: Icons.card_giftcard,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppConstants.paddingM),
                  StatisticCard(
                    title: 'Saldo Saat Ini',
                    amount: _formatCurrency(_saldo?.saldoTotal ?? 0),
                    icon: Icons.wallet_outlined,
                    color: AppColors.info,
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingL),

              // Riwayat Transaksi Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Riwayat Transaksi',
                    style: AppTextStyles.poppinsSectionTitle,
                  ),
                  TextButton(
                    onPressed: () {
                      context.push('/financial/history');
                    },
                    child: Text(
                      'Lihat Semua',
                      style: AppTextStyles.interBodyMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingM),

              // Filter chips
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
                    ..._transaksi.map((transaksi) {
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
