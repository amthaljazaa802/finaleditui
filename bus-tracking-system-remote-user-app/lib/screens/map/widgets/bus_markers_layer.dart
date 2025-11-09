// lib/screens/map/widgets/bus_markers_layer.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/bus.dart';
import 'bus_info_popup.dart';

/// This widget is compatible with flutter_map_marker_popup v8.
class BusMarkersLayer extends StatelessWidget {
  final List<Bus> buses;
  final void Function(String) onBusTapped;

  const BusMarkersLayer({
    super.key,
    required this.buses,
    required this.onBusTapped,
  });

  Color _getBusColor(BusStatus status) {
    switch (status) {
      case BusStatus.IN_SERVICE:
        return Colors.green;
      case BusStatus.NOT_IN_SERVICE:
        return Colors.red;
      case BusStatus.DELAYED:
        return Colors.orange;
      case BusStatus.UNKNOWN:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMarkerLayer(
      options: PopupMarkerLayerOptions(
        markers: buses.map((bus) {
          return Marker(
            key: ValueKey(bus.id),
            point: bus.position,
            width: 50,
            height: 50,
            child: Icon(
              Icons.directions_bus_rounded,
              color: _getBusColor(bus.status),
              size: 35,
            ),
          );
        }).toList(),
        popupDisplayOptions: PopupDisplayOptions(
          builder: (BuildContext context, Marker marker) {
            final bus = buses.firstWhere(
              (b) => b.id == (marker.key as ValueKey).value,
              orElse: () => Bus(
                id: '',
                licensePlate: 'N/A',
                position: const LatLng(0, 0),
                lineId: '',
              ),
            );
            return BusInfoPopup(bus: bus);
          },
        ),
        onPopupEvent: (_, List<Marker> selectedMarkers) {
          if (selectedMarkers.isNotEmpty) {
            final tappedMarker = selectedMarkers.first;
            if (tappedMarker.key is ValueKey) {
              final busId = (tappedMarker.key as ValueKey).value as String;
              onBusTapped(busId);
            }
          }
        },
      ),
    );
  }
}
