import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as ll;
import 'app_map_controller.dart';
import 'app_map_types.dart';

class AppMap extends StatefulWidget {
  final AppLatLng initialCenter;
  final double initialZoom;
  final List<AppMarker> markers;
  final AppMapController? controller;
  final void Function(AppMapController controller)? onMapCreated;
  final void Function(AppLatLng position)? onTap;
  final bool myLocationEnabled;

  /// Google Maps JSON style string (mobile only, ignored on web).
  final String? mobileMapStyle;

  const AppMap({
    super.key,
    required this.initialCenter,
    this.initialZoom = 15,
    this.markers = const [],
    this.controller,
    this.onMapCreated,
    this.onTap,
    this.myLocationEnabled = false,
    this.mobileMapStyle,
  });

  @override
  State<AppMap> createState() => _AppMapState();
}

class _AppMapState extends State<AppMap> {
  late final AppMapController _controller =
      widget.controller ?? AppMapController(initialZoom: widget.initialZoom);
  fmap.MapController? _flutterMapController;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _flutterMapController = fmap.MapController();
      _controller.attachFlutterMap(_flutterMapController!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onMapCreated?.call(_controller);
      });
    }
  }

  @override
  void dispose() {
    _flutterMapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildFlutterMap() : _buildGoogleMap();
  }

  Widget _buildGoogleMap() {
    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(
          widget.initialCenter.latitude,
          widget.initialCenter.longitude,
        ),
        zoom: widget.initialZoom,
      ),
      markers: widget.markers.map((m) => gmaps.Marker(
        markerId: gmaps.MarkerId(m.id),
        position: gmaps.LatLng(m.position.latitude, m.position.longitude),
        icon: m.mobileIcon ?? gmaps.BitmapDescriptor.defaultMarkerWithHue(m.hue),
        infoWindow: (m.title != null || m.snippet != null)
            ? gmaps.InfoWindow(title: m.title, snippet: m.snippet)
            : gmaps.InfoWindow.noText,
        onTap: m.onTap,
      )).toSet(),
      onMapCreated: (c) {
        _controller.attachGoogle(c);
        widget.onMapCreated?.call(_controller);
      },
      onTap: widget.onTap == null
          ? null
          : (pos) => widget.onTap!(AppLatLng(pos.latitude, pos.longitude)),
      myLocationEnabled: widget.myLocationEnabled,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      style: widget.mobileMapStyle,
    );
  }

  Widget _buildFlutterMap() {
    return fmap.FlutterMap(
      mapController: _flutterMapController,
      options: fmap.MapOptions(
        initialCenter: ll.LatLng(
          widget.initialCenter.latitude,
          widget.initialCenter.longitude,
        ),
        initialZoom: widget.initialZoom,
        interactionOptions: const fmap.InteractionOptions(
          flags: fmap.InteractiveFlag.all,
        ),
        onTap: widget.onTap == null
            ? null
            : (_, point) =>
                widget.onTap!(AppLatLng(point.latitude, point.longitude)),
      ),
      children: [
        fmap.TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.socialdev.community_report',
        ),
        fmap.MarkerLayer(
          markers: widget.markers.map((m) => fmap.Marker(
            point: ll.LatLng(m.position.latitude, m.position.longitude),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: m.onTap,
              child: m.webIcon ??
                  Icon(Icons.location_pin,
                      color: HSVColor.fromAHSV(1, m.hue, 1, 1).toColor(),
                      size: 40),
            ),
          )).toList(),
        ),
      ],
    );
  }
}
