import 'package:flutter/material.dart';
import '../../../models/upcoming_stop.dart';

class UpcomingStopsWidget extends StatelessWidget {
  final BusStopInfo? busStopInfo;
  final bool isFilterActive;
  final VoidCallback onFilterToggle;

  const UpcomingStopsWidget({
    Key? key,
    required this.busStopInfo,
    this.isFilterActive = false,
    required this.onFilterToggle,
  }) : super(key: key);

  String _formatExpectedTime(int minutes) {
    final expected = DateTime.now().add(Duration(minutes: minutes));
    final hour = expected.hour;
    final minute = expected.minute;
    final period = hour >= 12 ? 'م' : 'ص';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    if (busStopInfo == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header - similar to bus stop popup
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'المواقف القادمة',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '${busStopInfo!.lineName} - ${busStopInfo!.busLicensePlate}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Filter Button - زر الفلترة
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onFilterToggle,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isFilterActive
                        ? Colors.blue.shade50
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFilterActive
                          ? Colors.blue.shade300
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isFilterActive
                            ? Icons.filter_alt
                            : Icons.filter_alt_outlined,
                        color: isFilterActive
                            ? Colors.blue.shade700
                            : Colors.grey.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isFilterActive
                            ? 'عرض كل المواقف'
                            : 'عرض مسار هذا الخط فقط',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isFilterActive
                              ? Colors.blue.shade700
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Upcoming stops list
          if (busStopInfo!.upcomingStops.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'لا توجد مواقف قادمة',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: busStopInfo!.upcomingStops.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, index) {
                  final stop = busStopInfo!.upcomingStops[index];
                  final isFirst = index == 0;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    color: isFirst ? Colors.green.shade50 : Colors.transparent,
                    child: Row(
                      children: [
                        // Stop number indicator
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isFirst
                                ? Colors.green
                                : Colors.blue.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${stop.stopIndex + 1}',
                              style: TextStyle(
                                color: isFirst
                                    ? Colors.white
                                    : Colors.blue.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Stop info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stop.stop.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isFirst
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(stop.distanceMeters / 1000).toStringAsFixed(1)} كم',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Time info - matching bus stop popup style
                        // Show "At Stop" if bus is at this stop
                        if (stop.atStop)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'على المحطة',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 16,
                                    color: isFirst ? Colors.green : Colors.blue,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${stop.estimatedTimeMinutes} د',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isFirst
                                          ? Colors.green
                                          : Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatExpectedTime(stop.estimatedTimeMinutes),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
