import 'package:flutter/material.dart';
import '../../../models/bus.dart';

class BusInfoPopup extends StatelessWidget {
  final Bus bus;

  const BusInfoPopup({Key? key, required this.bus}) : super(key: key);

  // دالة مساعدة لترجمة حالة الحافلة إلى نص عربي أنيق
  String _getBusStatusText(BusStatus status) {
    switch (status) {
      case BusStatus.IN_SERVICE:
        return 'في الخدمة';
      case BusStatus.DELAYED:
        return 'متأخر';
      case BusStatus.NOT_IN_SERVICE:
        return 'خارج الخدمة';
      default:
        return 'غير معروف';
    }
  }

  // دالة مساعدة لاختيار لون الحالة
  Color _getBusStatusColor(BusStatus status) {
    switch (status) {
      case BusStatus.IN_SERVICE:
        return Colors.green;
      case BusStatus.DELAYED:
        return Colors.orange;
      case BusStatus.NOT_IN_SERVICE:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- الجزء العلوي: الأيقونة والعنوان ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.directions_bus_filled,
                  color: _getBusStatusColor(bus.status),
                ),
                const SizedBox(width: 8),
                const Text(
                  'معلومات الحافلة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // --- الجزء الأوسط: المعلومات ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'رقم اللوحة:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      bus.licensePlate, // <-- رقم اللوحة الديناميكي
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('الحالة:', style: TextStyle(color: Colors.grey)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getBusStatusColor(
                          bus.status,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getBusStatusText(bus.status), // <-- الحالة الديناميكية
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getBusStatusColor(bus.status),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
