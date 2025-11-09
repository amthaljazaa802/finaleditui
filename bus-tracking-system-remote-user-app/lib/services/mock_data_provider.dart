import 'package:latlong2/latlong.dart';
import '../models/bus.dart';
import '../models/bus_stop.dart';
import '../models/bus_line.dart';

// هذا كلاس ثابت (static) يحتوي على كل بياناتنا الوهمية
class MockDataProvider {
  // أضف هذه الدالة الجديدة داخل كلاس MockDataProvider

  static List<BusLine> getMockBusLines() {
    // لاحقًا، يمكنك إضافة قائمة المحطات والمسارات لكل خط هنا
    return [
      BusLine(
        id: 'line_1',
        name: 'خط الجامعة',
        description: 'يمر عبر المناطق: برامكة، مواساة، كلية الهندسة',
        stops: [], // يمكن تركها فارغة حاليًا
        path: [], // يمكن تركها فارغة حاليًا
      ),
      BusLine(
        id: 'line_2',
        name: 'خط كفرسوسة',
        description: 'يمر عبر المناطق: تنظيم، دوار البلدية، جامع الإيمان',
        stops: [],
        path: [],
      ),
      BusLine(
        id: 'line_3',
        name: 'خط التجارة',
        description: 'يمر عبر المناطق: شارع بغداد، ساحة السبع بحرات',
        stops: [],
        path: [],
      ),
    ];
  }

  // دالة تُرجع قائمة من المواقف الوهمية
  static List<BusStop> getMockStops() {
    return [
      BusStop(
        id: 'stop_1',
        name: 'موقف الجامعة',
        latitude: 33.5106,
        longitude: 36.2764,
      ),
      BusStop(
        id: 'stop_2',
        name: 'موقف التجارة',
        latitude: 33.5150,
        longitude: 36.2780,
      ),
      BusStop(
        id: 'stop_3',
        name: 'موقف البرامكة',
        latitude: 33.5138,
        longitude: 36.2890,
      ),
      BusStop(
        id: 'stop_4',
        name: 'موقف كفرسوسة',
        latitude: 33.4920,
        longitude: 36.2625,
      ),
    ];
  }

  // دالة تُرجع قائمة من الباصات الوهمية
  static List<Bus> getMockBuses() {
    return [
      Bus(
        id: 'bus_101',
        licensePlate: 'AB-123',
        position: LatLng(33.5115, 36.2770),
        lineId: 'line_1',
        status: BusStatus.IN_SERVICE,
      ),
      Bus(
        id: 'bus_102',
        licensePlate: 'CD-456',
        position: LatLng(33.5145, 36.2820),
        lineId: 'line_1',
        status: BusStatus.DELAYED,
      ),
      Bus(
        id: 'bus_201',
        licensePlate: 'EF-789',
        position: LatLng(33.5130, 36.2850),
        lineId: 'line_2',
        status: BusStatus.NOT_IN_SERVICE,
      ),
      Bus(
        id: 'bus_202',
        licensePlate: 'GH-012',
        position: LatLng(33.4955, 36.2640),
        lineId: 'line_2',
        status: BusStatus.IN_SERVICE,
      ),
    ];
  }
}
