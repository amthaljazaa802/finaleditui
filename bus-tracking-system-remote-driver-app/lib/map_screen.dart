import 'dart:async';
import 'package:driver_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:driver_app/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  final String busId;
  final dynamic lineId;

  const MapScreen({super.key, required this.busId, required this.lineId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Timer? _timer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _duration = Duration(seconds: _duration.inSeconds + 1);
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.textOnPrimary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'التتبع المباشر فعّال',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // الخريطة - 20% من الشاشة
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.20,
            child: Container(
              decoration: BoxDecoration(boxShadow: AppShadows.card),
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(37.7749, -122.4194),
                  zoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                    subdomains: ['a', 'b', 'c'],
                  ),
                ],
              ),
            ),
          ),

          // معلومات الجلسة - باقي الشاشة
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // بطاقة معلومات الحافلة
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppBorders.large,
                      boxShadow: AppShadows.card,
                    ),
                    child: Column(
                      children: [
                        // أيقونة الحالة
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_on,
                            size: 40,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text('جلسة التتبع نشطة', style: AppTextStyles.heading3),
                        const SizedBox(height: 24),

                        // معلومات الحافلة
                        _buildInfoRow(
                          icon: Icons.directions_bus,
                          label: 'رقم الحافلة',
                          value: widget.busId,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                        Divider(color: AppColors.divider, height: 1),
                        const SizedBox(height: 12),

                        _buildInfoRow(
                          icon: Icons.route,
                          label: 'رقم الخط',
                          value: widget.lineId.toString(),
                          color: AppColors.accent,
                        ),
                        const SizedBox(height: 12),
                        Divider(color: AppColors.divider, height: 1),
                        const SizedBox(height: 12),

                        _buildInfoRow(
                          icon: Icons.timer,
                          label: 'مدة الجلسة',
                          value: _formatDuration(_duration),
                          color: AppColors.success,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // زر إيقاف التتبع
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _showStopConfirmation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.textOnPrimary,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppBorders.medium,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.stop_circle, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'إيقاف التتبع',
                            style: AppTextStyles.button.copyWith(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: AppBorders.small,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodySmall),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showStopConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppBorders.medium),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            const SizedBox(width: 12),
            Text('تأكيد الإيقاف', style: AppTextStyles.heading3),
          ],
        ),
        content: Text(
          'هل أنت متأكد من إيقاف التتبع المباشر؟',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'إلغاء',
              style: AppTextStyles.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _stopTracking();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: AppBorders.small),
            ),
            child: Text('إيقاف', style: AppTextStyles.button),
          ),
        ],
      ),
    );
  }

  Future<void> _stopTracking() async {
    debugPrint('🔴 MapScreen: Stop button pressed!');

    // 1. التقط كل ما تحتاجه من السياق قبل أي عملية await
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // 2. قم بتنفيذ العمليات المتزامنة وغير المتزامنة
    final service = FlutterBackgroundService();
    service.invoke("stopService");
    debugPrint('🔴 MapScreen: flutter_background_service.stopService invoked');

    // --- إيقاف Native Foreground Service ---
    debugPrint(
      '🔴 MapScreen: About to call stopNativeService via MethodChannel',
    );
    const fgChannel = MethodChannel('com.example.driver_app/foreground');
    try {
      final result = await fgChannel.invokeMethod('stopNativeService');
      debugPrint('✅ MapScreen: Native service stop result: $result');
    } catch (e) {
      debugPrint('❌ MapScreen: Failed to stop native service: $e');
    }
    // --- نهاية إيقاف Native Service ---

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_bus_id');
    await prefs.remove('active_line_id');

    // 3. تحقق من أن الواجهة ما زالت موجودة
    if (!mounted) return;

    // 4. استخدم المتغيرات التي التقطتها بأمان
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'تم إيقاف التتبع بنجاح',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppBorders.medium),
      ),
    );

    // استخدام pushAndRemoveUntil لحذف كل الـ history ومنع الـ redirect loop
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
