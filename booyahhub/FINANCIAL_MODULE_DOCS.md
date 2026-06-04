# 📊 Financial Module Documentation

## Daftar Isi
- [Struktur Module](#struktur-module)
- [Database Schema](#database-schema)
- [Model & Service](#model--service)
- [UI Components](#ui-components)
- [Features](#features)
- [Implementasi](#implementasi)
- [API Functions](#api-functions)

---

## Struktur Module

### File Structure
```
lib/
├── data/
│   └── models/
│       ├── transaksi_keuangan_model.dart        # Model transaksi
│       ├── saldo_pengguna_model.dart            # Model saldo
│       └── services/
│           └── keuangan_service.dart            # Business logic service
├── presentation/
│   └── user/
│       ├── user_financial_screen.dart           # Main financial page
│       ├── user_financial_withdraw_page.dart    # Withdrawal request page
│       ├── user_financial_detail_page.dart      # Transaction detail
│       ├── user_financial_history_page.dart     # Transaction history
│       └── user_widgets/
│           ├── balance_card.dart                # Balance display
│           ├── transaction_card.dart            # Transaction list item
│           ├── statistic_card.dart              # Statistics widgets
│           ├── filter_chip_widget.dart          # Filter chips
│           └── financial_dashboard_widget.dart  # Dashboard summary
└── router/
    └── app_router.dart                          # Routes configuration
```

---

## Database Schema

### Tabel yang Diperlukan

#### 1. **saldo_pengguna**
```sql
CREATE TABLE saldo_pengguna (
  id_saldo INT PRIMARY KEY,
  id_akun INT NOT NULL REFERENCES akun(id_akun),
  saldo_total DECIMAL(15,2) DEFAULT 0,
  saldo_ditahan DECIMAL(15,2) DEFAULT 0,       -- Saldo pending
  saldo_klaim_hadiah DECIMAL(15,2) DEFAULT 0,  -- Hadiah yang belum diambil
  dibuat_pada TIMESTAMP DEFAULT NOW(),
  diperbarui TIMESTAMP,
  UNIQUE(id_akun)
);
```

#### 2. **transaksi_keuangan**
```sql
CREATE TABLE transaksi_keuangan (
  id_transaksi INT PRIMARY KEY,
  id_akun INT NOT NULL REFERENCES akun(id_akun),
  tipe_transaksi VARCHAR(20) NOT NULL,     -- 'pemasukan', 'penarikan', 'hadiah'
  nominal DECIMAL(15,2) NOT NULL,
  status VARCHAR(20) DEFAULT 'pending',    -- 'pending', 'berhasil', 'gagal', 'ditolak'
  deskripsi TEXT,
  dibuat_pada TIMESTAMP DEFAULT NOW(),
  diperbarui TIMESTAMP,
  nomor_rekening VARCHAR(50),
  nama_bank VARCHAR(100),
  nama_atas VARCHAR(100),
  INDEX idx_akun (id_akun),
  INDEX idx_status (status),
  INDEX idx_tipe (tipe_transaksi)
);
```

---

## Model & Service

### TransaksiKeuangan Model
```dart
TransaksiKeuangan(
  idTransaksi: 1,
  idAkun: 10,
  tipeTransaksi: 'pemasukan',           // pemasukan, penarikan, hadiah
  nominal: 50000.0,
  status: 'berhasil',                   // pending, berhasil, gagal, ditolak
  deskripsi: 'Hadiah juara scrim ID 5',
  dibuatPada: DateTime.now(),
  nomorRekening: '1234567890',
  namaBank: 'BRI',
  namaAtas: 'Nama Pemilik'
)
```

**Properties:**
- `isPending`, `isSuccess`, `isFailed`, `isRejected` - Status checks
- `isPemasukan`, `isPenarikan`, `isHadiah` - Type checks
- `displayNominal` - Formatted currency with sign
- `statusText`, `tipeText` - Readable labels

### SaldoPengguna Model
```dart
SaldoPengguna(
  idSaldo: 1,
  idAkun: 10,
  saldoTotal: 500000.0,
  saldoDitahan: 100000.0,               // Pending/processing
  saldoKlaimHadiah: 50000.0,            // Unclaimed prizes
  dibuatPada: DateTime.now(),
)
```

**Calculated Properties:**
- `saldoBisaDitarik` - Available balance (total - held - prizes)
- Display methods: `displaySaldoTotal`, `displaySaldoDitahan`, etc.

### KeuanganService
```dart
// Fetch user balance
await keuanganService.fetchSaldoPengguna(idAkun);

// Fetch transactions with filters
await keuanganService.fetchTransaksiPengguna(
  idAkun,
  tipeFilter: 'penarikan',
  statusFilter: 'pending',
  limit: 50,
);

// Create withdrawal request
await keuanganService.createPenarikan(
  idAkun: 10,
  nominal: 100000,
  nomorRekening: '123456789',
  namaBank: 'BRI',
  namaAtas: 'John Doe',
);

// Fetch statistics
await keuanganService.fetchStatistikKeuangan(idAkun);
// Returns: {total_pemasukan, total_penarikan, total_hadiah, saldo_current, saldo_bisa_ditarik}

// Get current month transactions
await keuanganService.fetchTransaksiThisMonth(idAkun);

// Update transaction status (admin only)
await keuanganService.updateTransaksiStatus(idTransaksi, 'berhasil');
```

---

## UI Components

### 1. BalanceCard
Menampilkan ringkasan saldo dengan breakdown.
```dart
BalanceCard(
  saldoTotal: 500000,
  saldoBisaDitarik: 350000,
  saldoDitahan: 100000,
  saldoHadiah: 50000,
  onWithdrawPressed: () { /* navigate to withdraw */ },
)
```

**Features:**
- Gradient background (gold theme)
- Real-time balance breakdown
- Quick withdraw button

### 2. TransactionCard
Item list untuk setiap transaksi.
```dart
TransactionCard(
  transaksi: transaksi,
  onTap: () { /* navigate to detail */ },
)
```

**Features:**
- Icon berdasarkan tipe transaksi
- Status badge dengan warna
- Clickable untuk detail

### 3. StatisticCard
Card untuk menampilkan statistik (pemasukan total, dll).
```dart
StatisticCard(
  title: 'Total Pemasukan',
  amount: 'Rp 1.000.000',
  icon: Icons.call_received,
  color: AppColors.success,
)
```

### 4. FilterChip
Chips untuk filter transaksi berdasarkan jenis/status.
```dart
FilterChip(
  label: 'Penarikan',
  isSelected: true,
  onPressed: () { /* update filter */ },
)
```

### 5. FinancialDashboardWidget
Widget mini untuk ditampilkan di dashboard/home.
```dart
FinancialDashboardWidget(
  saldo: saldoPengguna,
  isLoading: false,
  onWithdraw: () { /* navigate to withdraw */ },
  onViewMore: () { /* navigate to full financial */ },
)
```

---

## Features

### 1. **User Financial Screen** (`/user/financial`)
Halaman utama keuangan dengan:
- Saldo card dengan breakdown
- Statistik keuangan (total pemasukan/penarikan/hadiah)
- List transaksi terbaru (max 10)
- Filter berdasarkan jenis & status
- Refresh functionality

### 2. **Withdraw Page** (`/financial/withdraw`)
Form untuk membuat permintaan penarikan:
- Input nominal (min Rp 50.000)
- Validasi saldo otomatis
- Pilih bank/e-wallet (BRI, BCA, Mandiri, dll)
- Input nomor rekening & atas nama
- Syarat & ketentuan
- Konfirmasi dengan dialog success

### 3. **Transaction Detail Page** (`/financial/detail`)
Detail lengkap satu transaksi:
- Amount & status display
- Detail transaksi (ID, tanggal, deskripsi)
- Info rekening (untuk penarikan)
- Timeline (created → processed)
- Copy ID transaction button
- Contact support info

### 4. **Transaction History Page** (`/financial/history`)
List semua transaksi dengan:
- Filter jenis (semua/pemasukan/penarikan/hadiah)
- Filter status (semua/berhasil/pending/gagal)
- Total count
- Scroll untuk load lebih banyak
- Clickable items untuk detail

### 5. **Dashboard Widget**
Mini card di home screen:
- Saldo total dengan format singkat (Rp XXK)
- Saldo bisa ditarik
- Tarik dana button
- Lihat detail button

---

## Implementasi

### Routes Configuration
Routes sudah ditambahkan di `app_router.dart`:

```dart
// Main financial page
GoRoute(
  path: '/user/financial',
  name: 'financial',
  builder: (context, state) => const UserFinancialScreen(),
),

// Withdraw
GoRoute(
  path: '/financial/withdraw',
  name: 'withdraw',
  builder: (context, state) {
    final saldo = state.extra as SaldoPengguna;
    return WithdrawPage(saldo: saldo);
  },
),

// Detail transaksi
GoRoute(
  path: '/financial/detail',
  name: 'financial_detail',
  builder: (context, state) {
    final transaksi = state.extra as TransaksiKeuangan;
    return TransactionDetailPage(transaksi: transaksi);
  },
),

// History
GoRoute(
  path: '/financial/history',
  name: 'financial_history',
  builder: (context, state) => const TransactionHistoryPage(),
),
```

### Dashboard Integration
Financial widget sudah ditambahkan ke `user_home_screen.dart`:
- Loads saldo data pada init
- Displays widget dengan refresh capability
- Buttons navigate ke withdraw & full financial page

---

## API Functions

### User Operations

#### Get Balance
```dart
final saldo = await keuanganService.fetchSaldoPengguna(idAkun);
print('Saldo Total: ${saldo?.displaySaldoTotal}');
print('Bisa Ditarik: ${saldo?.displaySaldoBisaDitarik}');
```

#### Get Transactions
```dart
final transaksi = await keuanganService.fetchTransaksiPengguna(
  idAkun,
  tipeFilter: 'penarikan',    // Optional
  statusFilter: 'pending',    // Optional
  limit: 50,
  offset: 0,
);
```

#### Create Withdrawal
```dart
try {
  final result = await keuanganService.createPenarikan(
    idAkun: 10,
    nominal: 100000,
    nomorRekening: '1234567890',
    namaBank: 'BRI',
    namaAtas: 'John Doe',
  );
  print('Penarikan dibuat: ${result.idTransaksi}');
} catch (e) {
  print('Error: $e');
}
```

#### Get Statistics
```dart
final stats = await keuanganService.fetchStatistikKeuangan(idAkun);
print('Total Pemasukan: ${stats['total_pemasukan']}');
print('Total Penarikan: ${stats['total_penarikan']}');
print('Saldo Saat Ini: ${stats['saldo_current']}');
```

### Admin Operations

#### Update Transaction Status
```dart
// Approve withdrawal
await keuanganService.updateTransaksiStatus(
  idTransaksi,
  'berhasil',
);

// Reject withdrawal
await keuanganService.updateTransaksiStatus(
  idTransaksi,
  'ditolak',
);
```

---

## Styling & Colors

Menggunakan existing app theme:
- **Primary Color**: `AppColors.primary` (Gold #C9A227)
- **Success**: `AppColors.success` (Green #10B981)
- **Warning**: `AppColors.warning` (Yellow #F5C400)
- **Error**: `AppColors.error` (Red #F44336)
- **Background**: `AppColors.background` (Dark Blue #020C15)

---

## Error Handling

Semua service functions throw exception dengan pesan yang deskriptif:

```dart
try {
  await keuanganService.createPenarikan(...);
} catch (e) {
  // Possible errors:
  // - "Saldo tidak cukup"
  // - "Error creating penarikan: ..."
  // - "Nominal minimum adalah Rp 50.000"
}
```

---

## Future Enhancements

- [ ] Export transaksi ke PDF
- [ ] Scheduled withdrawals
- [ ] Multi-currency support
- [ ] Analytics & charts
- [ ] Bulk withdrawal approval (admin)
- [ ] Withdrawal templates/favorites
- [ ] Transaction search & advanced filters
- [ ] Notification untuk transaction updates

---

## Notes

1. **Minimum Withdrawal**: Rp 50.000 (configurable di service)
2. **Processing Time**: 1-2 hari kerja (displayed di UI)
3. **Currency Format**: Rupiah (Rp) dengan separator ribuan
4. **Auto-refresh**: Pull-to-refresh on main financial page
5. **Real-time**: Data fetched dari Supabase secara real-time

---

**Last Updated**: June 2026
**Module Version**: 1.0.0
