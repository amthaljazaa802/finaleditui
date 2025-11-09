import 'package:driver_app/services/api_service.dart';
import 'package:driver_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:driver_app/map_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _busIdController = TextEditingController();
  bool _isLoading = false;
  bool _isProcessing = false; // 🔒 قفل فوري بدون setState
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.location.request();
    await Permission.notification.request();
  }

  Future<bool> _handleGpsService() async {
    bool isGpsEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isGpsEnabled) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('خدمة الموقع غير مفعلة'),
            content: const Text(
              'يرجى تفعيل خدمة تحديد المواقع (GPS) لبدء التتبع.',
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('إلغاء'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('فتح الإعدادات'),
                onPressed: () {
                  Geolocator.openLocationSettings();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
      return false;
    }
    return true;
  }

  Future<void> _login() async {
    // ⚠️ منع الضغط المتكرر (debouncing) - قفل فوري بمتغير عادي
    if (_isProcessing) {
      debugPrint('⚠️ Login already in progress, ignoring duplicate tap');
      return;
    }

    // 🔒 قفل فوري - لا ينتظر setState
    _isProcessing = true;

    // فحص بسيط قبل بدء العملية
    if (_busIdController.text.isEmpty) {
      _isProcessing = false; // فك القفل
      _showErrorDialog('خطأ في الإدخال', 'الرجاء إدخال رقم الحافلة.');
      return;
    }

    // 🎨 تحديث UI (يمكن أن يتأخر قليلاً لكن القفل الفوري أعلاه يحمينا)
    setState(() {
      _isLoading = true;
    });
    debugPrint('🔐 LoginScreen: Starting login process...');

    try {
      // فحص GPS بعد قفل الزر
      final bool isGpsReady = await _handleGpsService();
      if (!isGpsReady) {
        _isProcessing = false; // 🔓 فك القفل
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final busId = _busIdController.text;
      final busData = await _apiService.getBusData(busId);
      if (!mounted) return;
      final lineId = busData['bus_line']['route_id'];

      // لا نحفظ الجلسة - كل مرة تسجيل دخول جديد لمنع الـ redirect loop
      // لكن نحتاج prefs للإعدادات الأخرى (API config)
      final prefs = await SharedPreferences.getInstance();

      final service = FlutterBackgroundService();
      var isRunning = await service.isRunning();
      if (!mounted) return;
      if (!isRunning) {
        debugPrint('LoginScreen: starting background service...');
        await service.startService();
        // Wait (short) for the service to start
        var attempts = 0;
        while (!(isRunning = await service.isRunning()) && attempts < 10) {
          await Future.delayed(const Duration(milliseconds: 500));
          attempts++;
        }
        debugPrint(
          'LoginScreen: background service running=$isRunning after $attempts attempts',
        );
      } else {
        debugPrint('LoginScreen: background service already running');
      }

      // --- الخطوة 1: قراءة المتغيرات من dotenv وتمريرها ---
      final apiBaseUrl = dotenv.env['API_BASE_URL'];
      final authToken = dotenv.env['AUTH_TOKEN'];

      debugPrint(
        'LoginScreen: invoking startTracking with busId=$busId api=${apiBaseUrl != null} auth=${authToken != null}',
      );
      // Persist API config as a fallback for native service
      await prefs.setString('API_BASE_URL', apiBaseUrl ?? '');
      await prefs.setString('AUTH_TOKEN', authToken ?? '');

      // Try to start native foreground service via MethodChannel
      const fgChannel = MethodChannel('com.example.driver_app/foreground');
      try {
        await fgChannel.invokeMethod('startNativeService', {
          'api_base_url': apiBaseUrl,
          'auth_token': authToken,
          'bus_id': int.parse(busId),
        });
        debugPrint('LoginScreen: requested native service start');
      } catch (e) {
        debugPrint('LoginScreen: failed to start native service: $e');
        // fallback to flutter_background_service invoke
        service.invoke('startTracking', {
          'bus_id': int.parse(busId),
          'line_id': lineId,
          'api_base_url': apiBaseUrl,
          'auth_token': authToken,
        });
      }
      // --- نهاية الخطوة 1 ---

      // Use the context synchronously: check mounted immediately and
      // avoid capturing the surrounding BuildContext in the route builder.
      if (!mounted) return;

      debugPrint('✅ LoginScreen: Login successful! Navigating to MapScreen...');
      debugPrint('   Bus ID: $busId, Line ID: $lineId');

      final route = MaterialPageRoute(
        builder: (_) => MapScreen(busId: busId, lineId: lineId),
      );
      // استخدام pushAndRemoveUntil لحذف كل الـ history ومنع الـ redirect loop
      Navigator.of(context).pushAndRemoveUntil(route, (route) => false);
      debugPrint('✅ LoginScreen: Navigation completed');
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(
        'فشل تسجيل الدخول',
        e.toString().replaceFirst("Exception: ", ""),
      );
    } finally {
      // 🔓 فك القفل في جميع الحالات
      _isProcessing = false;
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('موافق'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // شعار التطبيق
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppBorders.large,
                    boxShadow: AppShadows.card,
                  ),
                  child: ClipRRect(
                    borderRadius: AppBorders.large,
                    child: Image.asset(
                      'lib/assets/images/logo.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // اسم التطبيق
                const Text(
                  'مسار - السائق',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'نظام التتبع المباشر',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),

                // بطاقة تسجيل الدخول
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppBorders.large,
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('تسجيل الدخول', style: AppTextStyles.heading2),
                      const SizedBox(height: 8),
                      Text(
                        'أدخل رقم الحافلة لبدء التتبع المباشر',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 24),

                      // حقل إدخال رقم الحافلة
                      TextField(
                        controller: _busIdController,
                        keyboardType: TextInputType.number,
                        style: AppTextStyles.bodyLarge,
                        decoration: InputDecoration(
                          labelText: 'رقم الحافلة',
                          labelStyle: TextStyle(color: AppColors.textSecondary),
                          hintText: 'مثال: 123',
                          hintStyle: TextStyle(color: AppColors.textHint),
                          prefixIcon: Icon(
                            Icons.directions_bus,
                            color: AppColors.primary,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: AppBorders.medium,
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppBorders.medium,
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppBorders.medium,
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: AppBorders.medium,
                            borderSide: BorderSide(color: AppColors.error),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // زر بدء التتبع
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: _isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              )
                            : ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.textOnPrimary,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppBorders.medium,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.play_arrow, size: 24),
                                    const SizedBox(width: 8),
                                    Text(
                                      'بدء التتبع',
                                      style: AppTextStyles.button,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // معلومات إضافية
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: AppBorders.medium,
                    border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.info, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'تأكد من تفعيل خدمة الموقع (GPS) قبل البدء',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _busIdController.dispose();
    super.dispose();
  }
}
