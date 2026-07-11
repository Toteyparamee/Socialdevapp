import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show BitmapDescriptor;

class AppLatLng {
  final double latitude;
  final double longitude;
  const AppLatLng(this.latitude, this.longitude);
}

class AppMarker {
  final String id;
  final AppLatLng position;
  final String? title;
  final String? snippet;

  /// Icon used on mobile (Google Maps). Falls back to [hue] if null.
  final BitmapDescriptor? mobileIcon;

  /// Icon widget used on web (flutter_map). Falls back to a pin colored by
  /// [hue] if null.
  final Widget? webIcon;

  final double hue;
  final VoidCallback? onTap;

  const AppMarker({
    required this.id,
    required this.position,
    this.title,
    this.snippet,
    this.mobileIcon,
    this.webIcon,
    this.hue = 0,
    this.onTap,
  });
}
