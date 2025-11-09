import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // كل هذا المنطق يبقى كما هو بدون أي تغيير
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    setState(() => _isProcessing = true);
    final qrData = barcodes.first.rawValue ?? 'بيانات غير معروفة';

    _scannerController.stop();
    _showConfirmationDialog(qrData);
  }

  void _showConfirmationDialog(String qrData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        const busId = 'BUS-07';
        const lineName = 'خط الجامعة';
        const amount = '500 ل.س';

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppBorders.medium),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: AppBorders.small,
                ),
                child: Icon(
                  Icons.qr_code_scanner,
                  color: AppColors.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text('تأكيد الدفع', style: AppTextStyles.heading3),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(Icons.directions_bus, 'معلومات الحافلة', busId),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.route, 'الخط', lineName),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: AppBorders.small,
                ),
                child: Column(
                  children: [
                    Text(
                      'المبلغ',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      amount,
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'بيانات QR: $qrData',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetScanner();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text('إلغاء', style: AppTextStyles.button),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showSuccessAndExit();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(borderRadius: AppBorders.small),
              ),
              child: Text('تأكيد الدفع', style: AppTextStyles.button),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showSuccessAndExit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم الدفع بنجاح! (محاكاة)'),
        backgroundColor: Colors.green,
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context);
    });
  }

  void _resetScanner() {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    _scannerController.start();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  // --- بداية التعديل الرئيسي على دالة build ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- 1. السماح للكاميرا بالامتداد خلف الـ AppBar ---
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'ادفع تذكرتك',
          style: AppTextStyles.heading3.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        // --- 2. جعل الـ AppBar شفافًا وبدون ظل ---
        backgroundColor: Colors.black.withValues(alpha: 0.3),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // عرض الكاميرا يملأ الشاشة بالكامل
          MobileScanner(controller: _scannerController, onDetect: _onDetect),

          // العناصر التوجيهية فوق الكاميرا مع تحسينات
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.success, width: 4),
                    borderRadius: AppBorders.medium,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.qr_code_scanner,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: AppBorders.small,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.camera_alt,
                        color: AppColors.success,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'وجّه الكاميرا نحو رمز QR',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الموجود داخل الحافلة',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

