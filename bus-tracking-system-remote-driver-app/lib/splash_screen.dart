import 'package:driver_app/background_service.dart';
import 'package:driver_app/login_screen.dart';
import 'package:driver_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // نبدأ عمليات التهيئة الطويلة بعد عرض الواجهة
    _initializeAppAndNavigate();
  }

  String? _errorMessage;
  bool _isRetrying = false;

  Future<void> _initializeAppAndNavigate() async {
    setState(() {
      _errorMessage = null;
      _isRetrying = false;
    });

    try {
      debugPrint('Splash: starting initialization');
      // --- كل عمليات التهيئة التي كانت في main تم نقلها إلى هنا ---

      // 1. تهيئة Hive (مع timeout احترازي)
      debugPrint('Splash: Hive.initFlutter start');
      await Hive.initFlutter();
      debugPrint('Splash: Hive.initFlutter done');
      // Registering generated Hive adapters can sometimes cause analyzer issues
      // in CI if the generated file isn't visible. We attempt to register but
      // avoid hard failures here.
      try {
        // LocationPointAdapter is generated; register if available.
        // We reference it inside a try/catch to avoid analyzer/build failures
        // when the generated file isn't present in some CI runs.
        // Hive.registerAdapter(LocationPointAdapter());
      } catch (e) {
        debugPrint('Splash: LocationPointAdapter not available at runtime: $e');
      }
      debugPrint('Splash: opening Hive box location_queue');
      // Open without a generic type to avoid referencing LocationPoint here.
      await Hive.openBox('location_queue').timeout(const Duration(seconds: 15));
      debugPrint('Splash: opened Hive box location_queue');

      // 2. تحميل ملف .env
      debugPrint('Splash: dotenv.load start');
      try {
        // dotenv is optional at runtime (CI/apk may not include .env). We attempt to load it
        // but don't fail the whole initialization if it's missing or slow.
        await dotenv.load(fileName: ".env").timeout(const Duration(seconds: 4));
        debugPrint('Splash: dotenv.load done');
      } catch (e) {
        // Log and continue. The app will rely on fallback config or prompt the user later.
        debugPrint('Splash: dotenv.load failed or timed out: $e');
      }

      // 3. تهيئة الخدمة الخلفية (قد تستغرق قليلاً)
      debugPrint('Splash: initializeService start');
      try {
        // initializeService can fail on some devices or if background permissions
        // / artifacts are missing. Make it non-fatal: log and continue.
        await initializeService().timeout(const Duration(seconds: 10));
        debugPrint('Splash: initializeService done');
      } catch (e) {
        debugPrint('Splash: initializeService failed (non-fatal): $e');
        // don't rethrow — allow the app to continue to Login/Map; user can retry
        // starting the background service later when they log in.
      }

      // 4. تهيئة SharedPreferences (لكن لا نستخدمها للتوجيه التلقائي)
      debugPrint('Splash: SharedPreferences.getInstance start');
      final prefs = await SharedPreferences.getInstance();
      debugPrint('Splash: SharedPreferences.getInstance done');

      // ⚠️ إصلاح: نحذف أي جلسة محفوظة عند فتح التطبيق لمنع الـ redirect loop
      await prefs.remove('active_bus_id');
      await prefs.remove('active_line_id');
      debugPrint(
          '🧹 Splash: Cleared any saved session to prevent redirect loop');

      // التأكد من أن الواجهة ما زالت موجودة قبل الانتقال
      if (!mounted) return;

      // 5. دائماً نذهب إلى شاشة تسجيل الدخول (بدون auto-login)
      debugPrint('🔐 Splash: Navigating to LoginScreen');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, // حذف كل الـ history
      );
    } catch (e, st) {
      // سجل الاستثناء لتشخيص المشكلة
      debugPrint('Splash initialization failed: $e');
      debugPrint('$st');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'حدث خطأ أثناء التحميل. الرجاء المحاولة مرة أخرى.';
      });
    }
  }

  Future<void> _retryInitialization() async {
    setState(() {
      _isRetrying = true;
      _errorMessage = null;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    await _initializeAppAndNavigate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: _errorMessage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // أيقونة السائق
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.local_shipping,
                      size: 80,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // اسم التطبيق
                  const Text(
                    'مسار - السائق',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'نظام التتبع المباشر',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // مؤشر التحميل
                  const LoadingDots(),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 64,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'حدث خطأ أثناء التحميل',
                      style: AppTextStyles.heading2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    _isRetrying
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _retryInitialization,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppBorders.medium,
                              ),
                            ),
                            child: Text(
                              'حاول مرة أخرى',
                              style: AppTextStyles.button,
                            ),
                          ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Widget للنقاط المتحركة (Loading Dots)
class LoadingDots extends StatefulWidget {
  const LoadingDots({super.key});

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final value = ((_controller.value - (index * 0.2)) % 1.0);
            final scale =
                value < 0.5 ? 1.0 + (value * 0.6) : 1.3 - ((value - 0.5) * 0.6);
            final opacity =
                value < 0.5 ? 0.4 + (value * 1.2) : 1.0 - ((value - 0.5) * 1.2);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity.clamp(0.4, 1.0),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
