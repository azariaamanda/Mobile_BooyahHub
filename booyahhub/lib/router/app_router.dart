import 'package:go_router/go_router.dart';
import '../presentation/auth/splash_screen.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/auth/register_admin_page.dart';
import '../presentation/auth/register_user_page.dart';
import '../presentation/owner/owner_dashboard_screen.dart';
import '../presentation/owner/admin_verification_page.dart';
import '../presentation/owner/financial_report_page.dart';
import '../presentation/owner/prize_approval_page.dart';
import '../presentation/admin/admin_main_navigator.dart';
import '../presentation/admin/create_scrim_page.dart';
import '../presentation/admin/detail_scrim_page.dart';
import '../presentation/admin/edit_scrim_page.dart';
import '../presentation/admin/edit_profile_page.dart';
import '../presentation/admin/scrim_sessions_page.dart';
import '../presentation/admin/scrim_points_page.dart';
import '../presentation/admin/scrim_leaderboard_page.dart';
import '../presentation/admin/detail_session_page.dart';
import '../presentation/admin/add_session_page.dart';
import '../presentation/admin/edit_session_page.dart';
import '../presentation/admin/admin_notification_page.dart';
import '../presentation/admin/peserta_management_page.dart';
import '../presentation/admin/setup_session_page.dart';
import '../presentation/admin/validate_payment_page.dart';
import '../presentation/admin/input_score_page.dart';
import '../presentation/user/user_home_screen.dart';
import '../presentation/user/scrim_detail_page.dart';
import '../presentation/user/booking_scrim_page.dart';
import '../presentation/user/booking_form_page.dart';
import '../presentation/user/payment_checkout_page.dart';
import '../presentation/user/leaderboard_page.dart';
import '../presentation/user/history_scrim_page.dart';
import '../presentation/user/history_detail_scrim_page.dart';
import '../presentation/user/claim_prize_page.dart';
import '../presentation/user/user_main_navigator.dart';
import '../presentation/user/user_premium_page.dart';
import '../presentation/user/user_claim_rewards_page.dart';
import '../presentation/user/user_notification_page.dart';
import '../presentation/user/user_financial_screen.dart';
import '../presentation/user/user_financial_withdraw_page.dart';
import '../presentation/user/user_financial_detail_page.dart';
import '../presentation/user/user_financial_history_page.dart';
import '../data/models/saldo_pengguna_model.dart';
import '../data/models/transaksi_keuangan_model.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // ─── AUTH ──────────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register/pengguna',
        name: 'register_pengguna',
        builder: (context, state) => const RegisterUserPage(),
      ),
      GoRoute(
        path: '/register/admin',
        name: 'register_admin',
        builder: (context, state) => const RegisterAdminPage(),
      ),

      // ─── OWNER ─────────────────────────────────────────────────
      GoRoute(
        path: '/owner/dashboard',
        name: 'owner_dashboard',
        builder: (context, state) => const OwnerDashboardScreen(),
      ),
      GoRoute(
        path: '/owner/verifikasi-admin',
        name: 'verifikasi_admin',
        builder: (context, state) => const AdminVerificationPage(),
      ),
      GoRoute(
        path: '/owner/laporan-keuangan',
        name: 'laporan_keuangan',
        builder: (context, state) => const FinancialReportPage(),
      ),
      GoRoute(
        path: '/owner/approve-pembayaran',
        name: 'approve_pembayaran',
        builder: (context, state) => const PrizeApprovalPage(),
      ),

      // ─── ADMIN ─────────────────────────────────────────────────
      GoRoute(
        path: '/admin/dashboard',
        name: 'admin_dashboard',
        builder: (context, state) => const AdminMainNavigator(),
      ),
      GoRoute(
        path: '/admin/scrim/buat',
        name: 'buat_scrim',
        builder: (context, state) => const CreateScrimPage(),
      ),
      GoRoute(
        path: '/admin/scrim/detail/:id',
        name: 'detail_scrim_admin',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return DetailScrimPage(scrimId: id);
        },
      ),
      GoRoute(
        path: '/admin/scrim/edit/:id',
        name: 'edit_scrim',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return EditScrimPage(scrimId: id);
        },
      ),
      GoRoute(
        path: '/admin/scrim/:id/sessions',
        name: 'scrim_sessions',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ScrimSessionsPage(scrimId: id);
        },
      ),
      // ==================== ROUTE DIHAPUS ====================
      // Route /admin/scrim/:id/points dan /admin/scrim/:id/leaderboard
      // SUDAH DIHAPUS karena sekarang pakai DetailSessionPage
      // ========================================================
      GoRoute(
        path: '/admin/sesi/detail/:id',
        name: 'detail_session',
        builder: (context, state) {
          final sesiId = int.parse(state.pathParameters['id']!);
          return DetailSessionPage(sesiId: sesiId);
        },
      ),
      GoRoute(
        path: '/admin/sesi/tambah/:scrimId',
        name: 'add_session',
        builder: (context, state) {
          final scrimId = int.parse(state.pathParameters['scrimId']!);
          return AddSessionPage(scrimId: scrimId);
        },
      ),
      GoRoute(
        path: '/admin/sesi/edit/:sesiId',
        name: 'edit_session',
        builder: (context, state) {
          final sesiId = int.parse(state.pathParameters['sesiId']!);
          return EditSessionPage(sesiId: sesiId);
        },
      ),
      GoRoute(
        path: '/admin/scrim/:idScrim/sesi',
        name: 'atur_sesi',
        builder: (context, state) {
          final idScrim = int.parse(state.pathParameters['idScrim']!);
          return SetupSessionPage(scrimId: idScrim);
        },
      ),
      GoRoute(
        path: '/admin/verifikasi-pembayaran',
        name: 'verifikasi_pembayaran',
        builder: (context, state) => const ValidatePaymentPage(),
      ),
      GoRoute(
        path: '/admin/input-skor/:idSesi',
        name: 'input_skor',
        builder: (context, state) {
          final idSesi = int.parse(state.pathParameters['idSesi']!);
          return InputScorePage(sesiId: idSesi);
        },
      ),
      GoRoute(
        path: '/admin/profile/edit',
        name: 'edit_profile',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/admin/profile/notifikasi',
        name: 'admin_notifikasi',
        builder: (context, state) => const AdminNotificationPage(),
      ),
      GoRoute(
        path: '/admin/peserta',
        name: 'peserta',
        builder: (context, state) => const PesertaManagementPage(),
      ),
      GoRoute(
        path: '/admin/premium',
        name: 'admin_premium',
        builder: (context, state) => const UserPremiumPage(),
      ),

      // ─── USER (PELANGGAN) ──────────────────────────────────────
      GoRoute(
        path: '/user/home',
        name: 'user_home',
        builder: (context, state) => const UserMainNavigator(),
      ),
      GoRoute(
        path: '/user/beranda-konten',
        name: 'user_beranda_konten',
        builder: (context, state) => const UserHomeScreen(),
      ),
      GoRoute(
        path: '/user/scrim/:idScrim',
        name: 'detail_scrim',
        builder: (context, state) {
          final idScrim = int.parse(state.pathParameters['idScrim']!);
          return ScrimDetailPage(scrimId: idScrim);
        },
      ),
      GoRoute(
        path: '/user/booking-scrim/:idScrim',
        name: 'booking_scrim',
        builder: (context, state) {
          final idScrim = int.parse(state.pathParameters['idScrim']!);
          return BookingScrimPage(scrimId: idScrim);
        },
      ),
      GoRoute(
        path: '/user/booking/:idSesi',
        name: 'booking',
        builder: (context, state) {
          final idSesi = int.parse(state.pathParameters['idSesi']!);
          return BookingFormPage(sesiId: idSesi);
        },
      ),
      GoRoute(
        path: '/user/payment/:idPendaftaran',
        name: 'payment',
        builder: (context, state) {
          final idPendaftaran = int.parse(state.pathParameters['idPendaftaran']!);
          return PaymentCheckoutPage(pendaftaranId: idPendaftaran);
        },
      ),
      GoRoute(
        path: '/user/leaderboard/:idSesi',
        name: 'leaderboard',
        builder: (context, state) {
          final idSesi = int.parse(state.pathParameters['idSesi']!);
          return LeaderboardPage(sesiId: idSesi);
        },
      ),
      GoRoute(
        path: '/user/history',
        name: 'history',
        builder: (context, state) => const HistoryScrimPage(),
      ),
      GoRoute(
        path: '/user/history-detail',
        name: 'history_detail',
        builder: (context, state) => const HistoryDetailScrimPage(),
      ),
      GoRoute(
        path: '/user/klaim/:idPendaftaran',
        name: 'klaim',
        builder: (context, state) {
          final idPendaftaran = int.parse(state.pathParameters['idPendaftaran']!);
          return ClaimPrizePage(pendaftaranId: idPendaftaran);
        },
      ),
      GoRoute(
        path: '/user/premium',
        name: 'premium',
        builder: (context, state) => const UserPremiumPage(),
      ),
      GoRoute(
        path: '/user/klaim-hadiah',
        name: 'klaim_hadiah',
        builder: (context, state) => const UserClaimRewardsPage(),
      ),
      GoRoute(
        path: '/user/notifikasi',
        name: 'notifikasi',
        builder: (context, state) => const UserNotificationPage(),
      ),

      // ─── FINANCIAL (KEUANGAN) ──────────────────────────────────
      GoRoute(
        path: '/user/financial',
        name: 'financial',
        builder: (context, state) => const UserFinancialScreen(),
      ),
      GoRoute(
        path: '/financial/withdraw',
        name: 'withdraw',
        builder: (context, state) {
          final saldo = state.extra as SaldoPengguna;
          return WithdrawPage(saldo: saldo);
        },
      ),
      GoRoute(
        path: '/financial/detail',
        name: 'financial_detail',
        builder: (context, state) {
          final transaksi = state.extra as TransaksiKeuangan;
          return TransactionDetailPage(transaksi: transaksi);
        },
      ),
      GoRoute(
        path: '/financial/history',
        name: 'financial_history',
        builder: (context, state) => const TransactionHistoryPage(),
      ),
    ],
  );
}