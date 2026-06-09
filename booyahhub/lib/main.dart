import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_session.dart';
import 'config/app_theme.dart';
import 'data/models/services/fcm_service.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase harus diinit sebelum FirebaseMessaging digunakan
  // CATATAN: Butuh google-services.json di android/app/ — lihat README setup FCM
  try {
    await Firebase.initializeApp();
    await FcmService().initialize();
  } catch (_) {
    // Firebase belum dikonfigurasi — app tetap jalan tanpa push notification
  }

  await Supabase.initialize(
    url: 'https://cswveniezmeyvjojsfls.supabase.co',
    anonKey: 'sb_publishable_iDsJBrqpI1cvRpjPwoohMg_0PCRXjET',
  );

  await AppSession.load();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BooyahHub',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
    );
  }
}