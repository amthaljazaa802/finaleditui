/// مثال على كيفية استخدام WebSocket في شاشات Flutter
///
/// هذا ملف توضيحي فقط - لا تحتاج لإضافته للمشروع

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tracking_service.dart';
import '../models/bus.dart';

/// مثال 1: عرض قائمة الحافلات مع التحديثات المباشرة
class BusListExample extends StatefulWidget {
  const BusListExample({super.key});

  @override
  State<BusListExample> createState() => _BusListExampleState();
}

class _BusListExampleState extends State<BusListExample> {
  @override
  void initState() {
    super.initState();

    // بدء تحميل البيانات والاتصال بـ WebSocket
    final trackingService = context.read<TrackingService>();
    trackingService.fetchInitialData();
  }

  @override
  Widget build(BuildContext context) {
    final trackingService = context.read<TrackingService>();

    return Scaffold(
      appBar: AppBar(title: const Text('الحافلات المباشرة')),
      body: StreamBuilder<List<Bus>>(
        stream: trackingService.busStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }

          final buses = snapshot.data ?? [];

          if (buses.isEmpty) {
            return const Center(child: Text('لا توجد حافلات'));
          }

          return ListView.builder(
            itemCount: buses.length,
            itemBuilder: (context, index) {
              final bus = buses[index];
              return ListTile(
                leading: const Icon(Icons.directions_bus),
                title: Text(bus.licensePlate),
                subtitle: Text(
                  'الموقع: ${bus.position.latitude.toStringAsFixed(4)}, '
                  '${bus.position.longitude.toStringAsFixed(4)}',
                ),
                trailing: _buildStatusChip(bus.status),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(BusStatus status) {
    Color color;
    String label;

    switch (status) {
      case BusStatus.IN_SERVICE:
        color = Colors.green;
        label = 'في الخدمة';
        break;
      case BusStatus.DELAYED:
        color = Colors.orange;
        label = 'متأخر';
        break;
      case BusStatus.NOT_IN_SERVICE:
        color = Colors.red;
        label = 'خارج الخدمة';
        break;
      default:
        color = Colors.grey;
        label = 'غير معروف';
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }
}

/// مثال 2: عرض حافلة واحدة مع التحديثات المباشرة
class SingleBusTrackerExample extends StatefulWidget {
  final String busId;

  const SingleBusTrackerExample({super.key, required this.busId});

  @override
  State<SingleBusTrackerExample> createState() =>
      _SingleBusTrackerExampleState();
}

class _SingleBusTrackerExampleState extends State<SingleBusTrackerExample> {
  @override
  Widget build(BuildContext context) {
    final trackingService = context.read<TrackingService>();

    return StreamBuilder<List<Bus>>(
      stream: trackingService.busStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final buses = snapshot.data!;
        final bus = buses.firstWhere(
          (b) => b.id == widget.busId,
          orElse: () => throw Exception('Bus not found'),
        );

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حافلة: ${bus.licensePlate}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('خط الرحلة: ${bus.lineId}'),
                const SizedBox(height: 8),
                Text(
                  'الموقع الحالي:\n'
                  'خط العرض: ${bus.position.latitude.toStringAsFixed(6)}\n'
                  'خط الطول: ${bus.position.longitude.toStringAsFixed(6)}',
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('الحالة: '),
                    _buildStatusIndicator(bus.status),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(BusStatus status) {
    IconData icon;
    Color color;
    String text;

    switch (status) {
      case BusStatus.IN_SERVICE:
        icon = Icons.check_circle;
        color = Colors.green;
        text = 'في الخدمة';
        break;
      case BusStatus.DELAYED:
        icon = Icons.warning;
        color = Colors.orange;
        text = 'متأخر';
        break;
      case BusStatus.NOT_IN_SERVICE:
        icon = Icons.cancel;
        color = Colors.red;
        text = 'خارج الخدمة';
        break;
      default:
        icon = Icons.help;
        color = Colors.grey;
        text = 'غير معروف';
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color)),
      ],
    );
  }
}

/// مثال 3: استخدام البيانات المخزنة مباشرة (بدون Stream)
class BusListFromCacheExample extends StatelessWidget {
  const BusListFromCacheExample({super.key});

  @override
  Widget build(BuildContext context) {
    final trackingService = context.read<TrackingService>();

    // الحصول على البيانات المخزنة مباشرة
    final buses = trackingService.buses;

    return ListView.builder(
      itemCount: buses.length,
      itemBuilder: (context, index) {
        final bus = buses[index];
        return ListTile(
          title: Text(bus.licensePlate),
          subtitle: Text('خط: ${bus.lineId}'),
        );
      },
    );
  }
}

/// مثال 4: التحكم في WebSocket يدوياً
class WebSocketControlExample extends StatelessWidget {
  const WebSocketControlExample({super.key});

  @override
  Widget build(BuildContext context) {
    final trackingService = context.read<TrackingService>();

    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            trackingService.connectToWebSocket();
          },
          child: const Text('الاتصال بـ WebSocket'),
        ),
        ElevatedButton(
          onPressed: () {
            trackingService.disconnectWebSocket();
          },
          child: const Text('قطع الاتصال'),
        ),
        ElevatedButton(
          onPressed: () async {
            await trackingService.fetchInitialData();
          },
          child: const Text('تحميل البيانات'),
        ),
      ],
    );
  }
}
