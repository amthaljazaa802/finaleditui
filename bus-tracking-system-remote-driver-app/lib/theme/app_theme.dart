import 'package:flutter/material.dart';

/// نظام ألوان موحد ومتناسق لكل التطبيق
class AppColors {
  // ===== الألوان الأساسية (Primary) =====
  static const Color primary = Color(0xFF2196F3); // أزرق فاتح
  static const Color primaryDark = Color(0xFF1976D2); // أزرق غامق
  static const Color primaryLight = Color(0xFF64B5F6); // أزرق فاتح جداً

  // ===== الألوان الثانوية (Secondary/Accent) =====
  static const Color accent = Color(0xFFFF9800); // برتقالي
  static const Color accentDark = Color(0xFFF57C00);
  static const Color accentLight = Color(0xFFFFB74D);

  // ===== ألوان الخلفيات =====
  static const Color background = Color(0xFFF5F5F5); // رمادي فاتح جداً
  static const Color surface = Color(0xFFFFFFFF); // أبيض
  static const Color cardBackground = Color(0xFFFFFFFF);

  // ===== ألوان النصوص =====
  static const Color textPrimary = Color(0xFF212121); // رمادي غامق
  static const Color textSecondary = Color(0xFF757575); // رمادي متوسط
  static const Color textHint = Color(0xFFBDBDBD); // رمادي فاتح
  static const Color textOnPrimary = Color(0xFFFFFFFF); // أبيض

  // ===== ألوان الحالات =====
  static const Color success = Color(0xFF4CAF50); // أخضر
  static const Color warning = Color(0xFFFF9800); // برتقالي
  static const Color error = Color(0xFFF44336); // أحمر
  static const Color info = Color(0xFF2196F3); // أزرق

  // ===== ألوان خاصة بالخريطة =====
  static const Color busMarker = Color(0xFF1976D2); // أزرق للباص
  static const Color busStopMarker = Color(0xFFFF9800); // برتقالي للمحطة
  static const Color routeLine = Color(0xFF2196F3); // أزرق للخط

  // ===== ألوان الفلاتر =====
  static const Color filterActive = Color(0xFF2196F3);
  static const Color filterInactive = Color(0xFFE0E0E0);
  static const Color filterText = Color(0xFF212121);

  // ===== الظلال والحدود =====
  static const Color shadow = Color(0x1A000000); // ظل خفيف
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFBDBDBD);

  // ===== تدرجات لونية (Gradients) =====
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// أنماط النصوص الموحدة
class AppTextStyles {
  // ===== العناوين =====
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // ===== النصوص العادية =====
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // ===== نصوص الأزرار =====
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    letterSpacing: 0.5,
  );

  // ===== نصوص التلميحات =====
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textHint,
    height: 1.3,
  );
}

/// أنماط الظلال
class AppShadows {
  static const BoxShadow small = BoxShadow(
    color: AppColors.shadow,
    blurRadius: 4,
    offset: Offset(0, 2),
  );

  static const BoxShadow medium = BoxShadow(
    color: AppColors.shadow,
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  static const BoxShadow large = BoxShadow(
    color: AppColors.shadow,
    blurRadius: 16,
    offset: Offset(0, 8),
  );

  static const List<BoxShadow> card = [small];
  static const List<BoxShadow> button = [medium];
  static const List<BoxShadow> floating = [large];
}

/// أنماط الحدود
class AppBorders {
  static const BorderRadius small = BorderRadius.all(Radius.circular(8));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(12));
  static const BorderRadius large = BorderRadius.all(Radius.circular(16));
  static const BorderRadius circular = BorderRadius.all(Radius.circular(100));

  static const Border all = Border.fromBorderSide(
    BorderSide(color: AppColors.border, width: 1),
  );
}

/// المسافات الموحدة
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}
