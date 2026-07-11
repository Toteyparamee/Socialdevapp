import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as ll;
import 'app_map_types.dart';

class AppMapController {
  gmaps.GoogleMapController? _googleController;
  fmap.MapController? _flutterMapController;
  double _zoom;

  AppMapController({double initialZoom = 15}) : _zoom = initialZoom;

  // ignore: use_setters_to_change_properties
  void attachGoogle(gmaps.GoogleMapController controller) {
    _googleController = controller;
  }

  void attachFlutterMap(fmap.MapController controller) {
    _flutterMapController = controller;
  }

  Future<void> animateTo(AppLatLng target, {double? zoom}) async {
    if (zoom != null) _zoom = zoom;
    if (kIsWeb) {
      _flutterMapController?.move(
        ll.LatLng(target.latitude, target.longitude),
        _zoom,
      );
    } else {
      await _googleController?.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(
          gmaps.LatLng(target.latitude, target.longitude),
          _zoom,
        ),
      );
    }
  }

  Future<void> zoomIn() => _zoomBy(1);
  Future<void> zoomOut() => _zoomBy(-1);

  Future<void> _zoomBy(double delta) async {
    _zoom = (_zoom + delta).clamp(1, 20);
    if (kIsWeb) {
      final camera = _flutterMapController?.camera;
      if (camera != null) {
        _flutterMapController?.move(camera.center, _zoom);
      }
    } else {
      await _googleController?.animateCamera(
        delta > 0 ? gmaps.CameraUpdate.zoomIn() : gmaps.CameraUpdate.zoomOut(),
      );
    }
  }

  Future<void> setZoom(double zoom) async {
    _zoom = zoom.clamp(1, 20);
    if (kIsWeb) {
      final camera = _flutterMapController?.camera;
      if (camera != null) {
        _flutterMapController?.move(camera.center, _zoom);
      }
    } else {
      await _googleController?.animateCamera(gmaps.CameraUpdate.zoomTo(_zoom));
    }
  }

  void dispose() {
    _googleController?.dispose();
  }
}
