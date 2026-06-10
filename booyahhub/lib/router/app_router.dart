import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/auth/splash_screen.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/auth/register_selection_page.dart';
import '../presentation/auth/register_user_page.dart';
import '../presentation/auth/register_admin_page.dart';
import '../presentation/auth/register_owner_page.dart';
import '../presentation/auth/reset_password_page.dart';
import '../presentation/owner/premium_management_screen.dart';
import '../presentation/owner/edit_profile_screen.dart';
import '../presentation/owner/edit_premium_package_screen.dart';
import '../presentation/owner/manage_fee_screen.dart';
import '../data/models/paket_premium_model.dart';
import '../presentation/owner/owner_main_navigator.dart';
import '../presentation/owner/admin_verification_page.dart';
import '../presentation/owner/admin_payment_verification_page.dart';
import '../presentation/owner/financial_report_page.dart';
import '../presentation/owner/prize_approval_page.dart';
import '../presentation/admin/admin_main_navigator.dart';
import '../presentation/admin/admin_suspension_guard.dart';
import '../presentation/admin/admin_scrim_page.dart';
import '../presentation/admin/create_scrim_page.dart';
import '../presentation/admin/detail_scrim_page.dart';
import '../presentation/admin/edit_scrim_page.dart';
import '../presentation/admin/edit_profile_page.dart';
import '../presentation/admin/scrim_sessions_page.dart';
import '../presentation/admin/detail_session_page.dart';
import '../presentation/admin/add_session_page.dart';
import '../presentation/admin/edit_session_page.dart';
import '../presentation/admin/admin_notification_page.dart';
import '../presentation/admin/peserta_management_page.dart';
import '../presentation/admin/setup_session_page.dart';
import '../presentation/admin/admin_bayar_tagihan_page.dart';
import '../presentation/admin/validate_payment_page.dart';
import '../presentation/admin/input_score_page.dart';
import '../presentation/admin/admin_claim_list_page.dart';
import '../presentation/admin/admin_profile_page.dart';
import '../presentation/admin/admin_premium_page.dart';
import '../presentation/admin/manage_banner_page.dart';
import '../presentation/admin/scrim_limit_page.dart';
import '../presentation/user/user_home_screen.dart';
import '../presentation/user/scrim_page.dart';
import '../presentation/user/user_pesanan.dart';
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

  // ── Fade: perpindahan konteks besar (auth → app, splash → login) ──
  static CustomTransitionPage _fade(LocalKey key, Widget child) {
    return CustomTransitionPage(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      ),
    );
  }

  // ── Slide kanan + fade: navigasi standar drill-down ──
  static CustomTransitionPage _push(LocalKey key, Widget child) {
    return CustomTransitionPage(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        final fade = Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn));
        // Halaman sebelumnya sedikit geser ke kiri
        final secondarySlide = Tween<Offset>(begin: Offset.zero, end: const Offset(-0.25, 0))
            .chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(
          position: secondaryAnimation.drive(secondarySlide),
          child: SlideTransition(
            position: animation.drive(slide),
            child: FadeTransition(opacity: animation.drive(fade), child: child),
          ),
        );
      },
    );
  }

  // ── Slide atas: aksi/transaksi (booking, payment, premium) ──
  static CustomTransitionPage _modal(LocalKey key, Widget child) {
    return CustomTransitionPage(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 360),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (_, animation, __, child) {
        final slide = Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutQuart));
        final fade = Tween<double>(begin: 0.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));
        return SlideTransition(
          position: animation.drive(slide),
          child: FadeTransition(opacity: animation.drive(fade), child: child),
        );
      },
    );
  }

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // ─── AUTH — fade (perpindahan konteks besar) ────────────────
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (c, s) => _fade(s.pageKey, const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (c, s) => _fade(s.pageKey, const LoginScreen()),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset_password',
        pageBuilder: (c, s) => _push(s.pageKey, const ResetPasswordPage()),
      ),
      GoRoute(
        path: '/register/selection',
        name: 'register_selection',
        pageBuilder: (c, s) => _fade(s.pageKey, const RegisterSelectionPage()),
      ),
      GoRoute(
        path: '/register/pengguna',
        name: 'register_pengguna',
        pageBuilder: (c, s) => _push(s.pageKey, const RegisterUserPage()),
      ),
      GoRoute(
        path: '/register/admin',
        name: 'register_admin',
        pageBuilder: (c, s) => _push(s.pageKey, const RegisterAdminPage()),
      ),
      GoRoute(
        path: '/register/owner',
        name: 'register_owner',
        pageBuilder: (c, s) => _push(s.pageKey, const RegisterOwnerPage()),
      ),

      // ─── OWNER — main: fade, sub: push/modal ───────────────────
      GoRoute(
        path: '/owner/dashboard',
        name: 'owner_dashboard',
        pageBuilder: (c, s) => _fade(s.pageKey, const OwnerMainNavigator()),
      ),
      GoRoute(
        path: '/owner/edit-premium',
        name: 'owner_edit_premium',
        pageBuilder: (c, s) {
          final pkg = s.extra as PaketPremiumModel?;
          return _push(s.pageKey, EditPremiumPackageScreen(package: pkg));
        },
      ),
      GoRoute(
        path: '/owner/verifikasi-pembayaran',
        name: 'owner_verifikasi_pembayaran',
        pageBuilder: (c, s) {
          final admin = s.extra as Map<String, dynamic>;
          return _modal(s.pageKey, AdminPaymentVerificationPage(admin: admin));
        },
      ),
      GoRoute(
        path: '/owner/manage-fee',
        name: 'owner_manage_fee',
        pageBuilder: (c, s) => _push(s.pageKey, const ManageFeeScreen()),
      ),
      GoRoute(
        path: '/owner/edit-profile',
        name: 'owner_edit_profile',
        pageBuilder: (c, s) => _push(s.pageKey, const EditProfileScreen()),
      ),
      GoRoute(
        path: '/owner/premium-management',
        name: 'owner_premium_management',
        pageBuilder: (c, s) => _push(s.pageKey, const PremiumManagementScreen()),
      ),
      GoRoute(
        path: '/owner/laporan-keuangan',
        name: 'laporan_keuangan',
        pageBuilder: (c, s) => _push(s.pageKey, const FinancialReportPage()),
      ),
      GoRoute(
        path: '/owner/approve-pembayaran',
        name: 'approve_pembayaran',
        pageBuilder: (c, s) => _modal(s.pageKey, const PrizeApprovalPage()),
      ),

      // ─── ADMIN — main: fade, drill-down: push, aksi: modal ─────
      GoRoute(
        path: '/admin/dashboard',
        name: 'admin_dashboard',
        pageBuilder: (c, s) => _fade(s.pageKey, const AdminSuspensionGuard(child: AdminMainNavigator())),
      ),
      GoRoute(
        path: '/admin/scrim',
        name: 'admin_scrim',
        pageBuilder: (c, s) => _push(s.pageKey, const AdminSuspensionGuard(child: AdminScrimPage())),
      ),
      GoRoute(
        path: '/admin/scrim/buat',
        name: 'buat_scrim',
        pageBuilder: (c, s) => _modal(s.pageKey, const AdminSuspensionGuard(child: CreateScrimPage())),
      ),
      GoRoute(
        path: '/admin/scrim/detail/:id',
        name: 'detail_scrim_admin',
        pageBuilder: (c, s) {
          final id = int.parse(s.pathParameters['id']!);
          return _push(s.pageKey, AdminSuspensionGuard(child: DetailScrimPage(scrimId: id)));
        },
      ),
      GoRoute(
        path: '/admin/scrim/edit/:id',
        name: 'edit_scrim',
        pageBuilder: (c, s) {
          final id = int.parse(s.pathParameters['id']!);
          return _push(s.pageKey, AdminSuspensionGuard(child: EditScrimPage(scrimId: id)));
        },
      ),
      GoRoute(
        path: '/admin/scrim/:id/sessions',
        name: 'scrim_sessions',
        pageBuilder: (c, s) {
          final id = int.parse(s.pathParameters['id']!);
          return _push(s.pageKey, AdminSuspensionGuard(child: ScrimSessionsPage(scrimId: id)));
        },
      ),
      GoRoute(
        path: '/admin/sesi/detail/:id',
        name: 'detail_session',
        pageBuilder: (c, s) {
          final sesiId = int.parse(s.pathParameters['id']!);
          return _push(s.pageKey, AdminSuspensionGuard(child: DetailSessionPage(sesiId: sesiId)));
        },
      ),
      GoRoute(
        path: '/admin/sesi/tambah/:scrimId',
        name: 'add_session',
        pageBuilder: (c, s) {
          final scrimId = int.parse(s.pathParameters['scrimId']!);
          return _modal(s.pageKey, AdminSuspensionGuard(child: AddSessionPage(scrimId: scrimId)));
        },
      ),
      GoRoute(
        path: '/admin/sesi/edit/:sesiId',
        name: 'edit_session',
        pageBuilder: (c, s) {
          final sesiId = int.parse(s.pathParameters['sesiId']!);
          return _push(s.pageKey, AdminSuspensionGuard(child: EditSessionPage(sesiId: sesiId)));
        },
      ),
      GoRoute(
        path: '/admin/scrim/:idScrim/sesi',
        name: 'atur_sesi',
        pageBuilder: (c, s) {
          final idScrim = int.parse(s.pathParameters['idScrim']!);
          return _modal(s.pageKey, AdminSuspensionGuard(child: SetupSessionPage(scrimId: idScrim)));
        },
      ),
      GoRoute(
        path: '/admin/verifikasi-pembayaran',
        name: 'verifikasi_pembayaran',
        pageBuilder: (c, s) => _modal(s.pageKey, const AdminSuspensionGuard(child: ValidatePaymentPage())),
      ),
      GoRoute(
        path: '/admin/input-skor/:idSesi',
        name: 'input_skor',
        pageBuilder: (c, s) {
          final idSesi = int.parse(s.pathParameters['idSesi']!);
          return _modal(s.pageKey, AdminSuspensionGuard(child: InputScorePage(sesiId: idSesi)));
        },
      ),
      GoRoute(
        path: '/admin/klaim',
        name: 'admin_klaim',
        pageBuilder: (c, s) => _push(s.pageKey, const AdminSuspensionGuard(child: AdminClaimListPage())),
      ),
      GoRoute(
        path: '/admin/profile/edit',
        name: 'edit_profile',
        pageBuilder: (c, s) => _push(s.pageKey, const AdminSuspensionGuard(child: EditProfilePage())),
      ),
      GoRoute(
        path: '/admin/profile/notifikasi',
        name: 'admin_notifikasi',
        pageBuilder: (c, s) => _push(s.pageKey, const AdminSuspensionGuard(child: AdminNotificationPage())),
      ),
      GoRoute(
        path: '/admin/peserta',
        name: 'peserta',
        pageBuilder: (c, s) => _push(s.pageKey, const AdminSuspensionGuard(child: PesertaManagementPage())),
      ),
      GoRoute(
        path: '/admin/premium',
        name: 'admin_premium',
        pageBuilder: (c, s) => _modal(s.pageKey, const AdminSuspensionGuard(child: AdminPremiumPage())),
      ),
      GoRoute(
        path: '/admin/bayar-tagihan',
        name: 'admin_bayar_tagihan',
        pageBuilder: (c, s) => _modal(s.pageKey, const AdminBayarTagihanPage()),
      ),
      GoRoute(
        path: '/admin/banner',
        name: 'admin_banner',
        pageBuilder: (c, s) => _push(s.pageKey, const AdminSuspensionGuard(child: ManageBannerPage())),
      ),
      GoRoute(
        path: '/admin/scrim/limit',
        name: 'scrim_limit',
        pageBuilder: (c, s) => _push(s.pageKey, const ScrimLimitPage()),
      ),

      // ─── USER — main: fade, list: push, detail: scale, aksi: modal ─
      GoRoute(
        path: '/user/home',
        name: 'user_home',
        pageBuilder: (c, s) => _fade(s.pageKey, const UserMainNavigator()),
      ),
      GoRoute(
        path: '/user/beranda-konten',
        name: 'user_beranda_konten',
        pageBuilder: (c, s) => _fade(s.pageKey, const UserHomeScreen()),
      ),
      GoRoute(
        path: '/user/scrim',
        name: 'scrim_page',
        pageBuilder: (c, s) => _push(s.pageKey, const ScrimPage()),
      ),
      GoRoute(
        path: '/user/pesanan',
        name: 'user_pesanan',
        pageBuilder: (c, s) => _push(s.pageKey, const UserPesananPage()),
      ),
      GoRoute(
        path: '/user/scrim/:idScrim',
        name: 'detail_scrim',
        pageBuilder: (c, s) {
          final idScrim = int.parse(s.pathParameters['idScrim']!);
          return _push(s.pageKey, ScrimDetailPage(scrimId: idScrim));
        },
      ),
      GoRoute(
        path: '/user/booking-scrim/:idScrim',
        name: 'booking_scrim',
        pageBuilder: (c, s) {
          final idScrim = int.parse(s.pathParameters['idScrim']!);
          return _modal(s.pageKey, BookingScrimPage(scrimId: idScrim));
        },
      ),
      GoRoute(
        path: '/user/booking/:idSesi',
        name: 'booking',
        pageBuilder: (c, s) {
          final idSesi = int.parse(s.pathParameters['idSesi']!);
          return _modal(s.pageKey, BookingFormPage(sesiId: idSesi));
        },
      ),
      GoRoute(
        path: '/user/payment/:idPendaftaran',
        name: 'payment',
        pageBuilder: (c, s) {
          final idPendaftaran = int.parse(s.pathParameters['idPendaftaran']!);
          return _modal(s.pageKey, PaymentCheckoutPage(pendaftaranId: idPendaftaran));
        },
      ),
      GoRoute(
        path: '/user/leaderboard/:idSesi',
        name: 'leaderboard',
        pageBuilder: (c, s) {
          final idSesi = int.parse(s.pathParameters['idSesi']!);
          return _push(s.pageKey, LeaderboardPage(sesiId: idSesi));
        },
      ),
      GoRoute(
        path: '/user/history',
        name: 'history',
        pageBuilder: (c, s) => _push(s.pageKey, const HistoryScrimPage()),
      ),
      GoRoute(
        path: '/user/history-detail',
        name: 'history_detail',
        pageBuilder: (c, s) {
          final idPendaftaran = int.tryParse(s.extra?.toString() ?? '0') ?? 0;
          return _push(s.pageKey, HistoryDetailScrimPage(idPendaftaran: idPendaftaran));
        },
      ),
      GoRoute(
        path: '/user/klaim/:idPendaftaran',
        name: 'klaim',
        pageBuilder: (c, s) {
          final idPendaftaran = int.parse(s.pathParameters['idPendaftaran']!);
          return _modal(s.pageKey, ClaimPrizePage(pendaftaranId: idPendaftaran));
        },
      ),
      GoRoute(
        path: '/user/premium',
        name: 'premium',
        pageBuilder: (c, s) => _modal(s.pageKey, const UserPremiumPage()),
      ),
      GoRoute(
        path: '/user/klaim-hadiah',
        name: 'klaim_hadiah',
        pageBuilder: (c, s) => _modal(s.pageKey, const UserClaimRewardsPage()),
      ),
      GoRoute(
        path: '/user/notifikasi',
        name: 'notifikasi',
        pageBuilder: (c, s) => _push(s.pageKey, const UserNotificationPage()),
      ),
      GoRoute(
        path: '/user/financial',
        name: 'financial',
        pageBuilder: (c, s) => _push(s.pageKey, const UserFinancialScreen()),
      ),
      GoRoute(
        path: '/financial/withdraw',
        name: 'withdraw',
        pageBuilder: (c, s) {
          final saldo = s.extra as SaldoPengguna;
          return _modal(s.pageKey, WithdrawPage(saldo: saldo));
        },
      ),
      GoRoute(
        path: '/financial/detail',
        name: 'financial_detail',
        pageBuilder: (c, s) {
          final transaksi = s.extra as TransaksiKeuangan;
          return _push(s.pageKey, TransactionDetailPage(transaksi: transaksi));
        },
      ),
      GoRoute(
        path: '/financial/history',
        name: 'financial_history',
        pageBuilder: (c, s) => _push(s.pageKey, const TransactionHistoryPage()),
      ),
    ],
  );
}
