// في ملف: lib/location_point.dart

import 'package:hive/hive.dart';

// هذا السطر مهم ليتم إنشاء الملف المساعد تلقائياً
part 'location_point.g.dart';

@HiveType(typeId: 0)
class LocationPoint extends HiveObject {
  @HiveField(0)
  late String latitude;

  @HiveField(1)
  late String longitude;

  @HiveField(2)
  late String speed;

  // دالة لتحويل الكائن إلى Map لإرساله كـ JSON
  Map<String, String> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
    };
  }
}
