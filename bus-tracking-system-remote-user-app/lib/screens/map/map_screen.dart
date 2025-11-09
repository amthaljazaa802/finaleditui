import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../repositories/transport_repository.dart';
import 'bloc/map_bloc.dart';

class MapScreen extends StatelessWidget {
  final String lineId;

  const MapScreen({Key? key, required this.lineId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          MapBloc(repository: context.read<TransportRepository>())
            ..add(MapStarted(lineId)), // بدء تحميل بيانات الخط المحدد
      child: const MapView(),
    );
  }
}

class MapView extends StatelessWidget {
  const MapView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          if (state is MapLoadInProgress || state is MapInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MapLoadSuccess) {
            return FlutterMap(
              options: MapOptions(
                // اجعل الخريطة تتمركز على أول موقف في الخط
                initialCenter: state.line.stops.isNotEmpty
                    ? state.line.stops.first.position
                    : const LatLng(33.5138, 36.2765),
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                // --- 1. عرض مسار الخط (إذا كان متوفرًا) ---
                if (state.line.path.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: state.line.path,
                        strokeWidth: 5.0,
                        color: Colors.blue.shade700,
                      ),
                    ],
                  ),
                // --- 2. عرض مواقف الخط ---
                MarkerLayer(
                  markers: state.line.stops.map((stop) {
                    return Marker(
                      point: stop.position,
                      width: 40,
                      height: 40,
                      child: Image.asset(
                        'lib/assets/images/thumbnail.png',
                      ), // استخدم أيقونتك المخصصة
                    );
                  }).toList(),
                ),
                // --- 3. عرض حافلات الخط ---
                MarkerLayer(
                  markers: state.buses.map((bus) {
                    return Marker(
                      width: 40.0,
                      height: 40.0,
                      point: bus.position,
                      child: Icon(
                        Icons.directions_bus_rounded,
                        color: Colors.green, // يمكنك تخصيص اللون لاحقًا
                        size: 35,
                      ),
                    );
                  }).toList(),
                ),
                // --- AppBar مخصص عائم فوق الخريطة ---
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AppBar(
                    title: Text(state.line.name), // عرض اسم الخط المحدد
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                  ),
                ),
              ],
            );
          }

          if (state is MapLoadFailure) {
            return Center(child: Text('حدث خطأ: ${state.errorMessage}'));
          }

          return const Center(child: Text('حالة غير معروفة'));
        },
      ),
    );
  }
}
