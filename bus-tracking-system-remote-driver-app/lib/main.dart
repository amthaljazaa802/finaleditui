import 'dart:io';
import 'package:driver_app/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// =====================================================================
/// SSL/TLS Certificate Handling
/// =====================================================================
/// كلاس للتعامل مع التحقق من شهادة SSL بشكل آمن
///
/// في الإنتاج (PRODUCTION): استخدم شهادة صحيحة والتحقق الكامل
/// في التطوير (DEBUG): يمكن تخطي التحقق مؤقتاً (فقط للـ dev)
///
/// الاتصال: Driver ↔ Server عبر HTTPS (آمن)
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      // ⚠️ تحذير: تجاهل التحقق من الشهادة فقط في بيئة التطوير
      // NEVER disable SSL verification in production!
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // في الإنتاج، يجب التحقق من صحة الشهادة
        if (kDebugMode) {
          // في التطوير، السماح بـ self-signed certificates
          return true;
        }
        // في الإنتاج، فرض التحقق الكامل
        return false;
      };
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ⚠️ تحذير أمني: تعطيل التحقق من SSL فقط في debug mode
  // في الإنتاج (release)، هذا الكود لن يُنفذ
  if (kDebugMode) {
    HttpOverrides.global = MyHttpOverrides();
  }

  // تشغيل التطبيق
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bus Tracking - Driver App',
      debugShowCheckedModeBanner: kDebugMode,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
    );
  }
}
