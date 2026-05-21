import 'package:go_router/go_router.dart';
import '../presentation/auth/splash_screen.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/auth/register_admin_page.dart';
import '../presentation/auth/register_user_page.dart';
import '../presentation/owner/owner_dashboard_screen.dart';
import '../presentation/owner/admin_verification_page.dart';
import '../presentation/owner/financial_report_page.dart';
import '../presentation/owner/prize_approval_page.dart';
import '../presentation/admin/admin_dashboard_screen.dart';
import '../presentation/admin/create_scrim_page.dart';
import '../presentation/admin/setup_session_page.dart';
import '../presentation/admin/validate_payment_page.dart';
import '../presentation/admin/input_score_page.dart';
import '../presentation/admin/admin_claim_list_page.dart';
import '../presentation/admin/payment_config_page.dart';
import '../presentation/user/user_home_screen.dart';
import '../presentation/user/scrim_detail_page.dart';
import '../presentation/user/booking_form_page.dart';
import '../presentation/user/payment_checkout_page.dart';
import '../presentation/user/leaderboard_page.dart';
import '../presentation/user/history_scrim_page.dart';
import '../presentation/user/claim_prize_page.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      // Auth
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

      // Owner
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

      // Admin
      GoRoute(
        path: '/admin/dashboard',
        name: 'admin_dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/scrim/buat',
        name: 'buat_scrim',
        builder: (context, state) => const CreateScrimPage(),
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
        path: '/admin/klaim',
        name: 'admin_klaim',
        builder: (context, state) => const AdminClaimListPage(),
      ),
      GoRoute(
        path: '/admin/payment-config',
        name: 'payment_config',
        builder: (context, state) => const PaymentConfigPage(),
      ),

      // User
      GoRoute(
        path: '/user/home',
        name: 'user_home',
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
        path: '/user/klaim/:idPendaftaran',
        name: 'klaim',
        builder: (context, state) {
          final idPendaftaran = int.parse(state.pathParameters['idPendaftaran']!);
          return ClaimPrizePage(pendaftaranId: idPendaftaran);
        },
      ),
    ],
  );
}