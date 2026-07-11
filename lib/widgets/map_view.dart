import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show BitmapDescriptor;
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/activity.dart';
import '../services/activity_service.dart';
import '../screens/detail_screen.dart';
import 'app_map/app_map.dart';
import 'app_map/app_map_controller.dart';
import 'app_map/app_map_types.dart';
import 'activity_bottom_sheet.dart';
import 'filter_panel.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with TickerProviderStateMixin {
  final AppMapController _mapController = AppMapController(initialZoom: 13.5);
  Activity? _selectedActivity;
  MapFilter _mapFilter = const MapFilter();
  final _searchController = TextEditingController();
  final Map<String, BitmapDescriptor> _activitySchoolIcons = {};
  final Map<String, BitmapDescriptor> _activityPublicIcons = {};
  final Map<String, Widget> _activitySchoolWebIcons = {};
  final Map<String, Widget> _activityPublicWebIcons = {};

  late AnimationController _sheetController;
  late Animation<double> _sheetAnimation;

  static const _initialCenter = AppLatLng(13.8200, 100.5700);

  @override
  void initState() {
    super.initState();
    _sheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _sheetAnimation = CurvedAnimation(
      parent: _sheetController,
      curve: Curves.easeOutCubic,
    );
    _goToMyLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityService>().fetchActivities().then((_) => _buildActivityIcons());
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ── Location ──────────────────────────────────────────────────────────────

  Future<void> _goToMyLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;
    final pos = await Geolocator.getCurrentPosition();
    _mapController.animateTo(AppLatLng(pos.latitude, pos.longitude), zoom: 15);
  }

  // ── Filter helpers ────────────────────────────────────────────────────────

  List<Activity> get _filteredActivities {
    final all = context
        .read<ActivityService>()
        .activities
        .where((a) => a.latitude != null && a.longitude != null);
    if (_mapFilter.showActivities) return all.toList();
    return all.where((a) => a.isPublic).toList();
  }

  // ── Markers ───────────────────────────────────────────────────────────────

  List<AppMarker> get _markers {
    return _filteredActivities.map((a) => AppMarker(
      id: 'activity_${a.id}',
      position: AppLatLng(a.latitude!, a.longitude!),
      mobileIcon: kIsWeb
          ? null
          : (_mapFilter.showActivities
              ? (_activitySchoolIcons[a.id] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet))
              : (_activityPublicIcons[a.id] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow))),
      webIcon: _mapFilter.showActivities
          ? _activitySchoolWebIcons[a.id]
          : _activityPublicWebIcons[a.id],
      hue: _mapFilter.showActivities ? BitmapDescriptor.hueViolet : BitmapDescriptor.hueYellow,
      onTap: () => _selectActivity(a),
    )).toList();
  }

  // ── Icon builders ─────────────────────────────────────────────────────────

  Future<void> _buildActivityIcons() async {
    const schoolColor = Color(0xFF6C63FF);
    const publicColor = Color(0xFFF59E0B);
    final all = context
        .read<ActivityService>()
        .activities
        .where((a) => a.latitude != null && a.longitude != null);
    for (final a in all) {
      if (!_activitySchoolIcons.containsKey(a.id)) {
        if (!kIsWeb) {
          _activitySchoolIcons[a.id] = await _buildMarkerIcon(
            label: a.title,
            iconData: Icons.school_rounded,
            color: schoolColor,
          );
        }
        _activitySchoolWebIcons[a.id] = _buildWebMarkerIcon(
          label: a.title,
          iconData: Icons.school_rounded,
          color: schoolColor,
        );
      }
      if (!_activityPublicIcons.containsKey(a.id)) {
        if (!kIsWeb) {
          _activityPublicIcons[a.id] = await _buildMarkerIcon(
            label: a.title,
            iconData: Icons.public_rounded,
            color: publicColor,
          );
        }
        _activityPublicWebIcons[a.id] = _buildWebMarkerIcon(
          label: a.title,
          iconData: Icons.public_rounded,
          color: publicColor,
        );
      }
    }
    if (mounted) setState(() {});
  }

  Widget _buildWebMarkerIcon({
    required String label,
    required IconData iconData,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
        ],
      ),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  Future<BitmapDescriptor> _buildMarkerIcon({
    required String label,
    required IconData iconData,
    required Color color,
    ui.Image? thumbnail,
  }) async {
    const double w = 200, h = 80, pin = 14, img = 56, pad = 10, r = 14;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, w, h + pin));

    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(2, 3, w - 4, h - 2), const Radius.circular(r)),
      Paint()..color = Colors.black.withValues(alpha: 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    final bubble = RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, w, h), const Radius.circular(r));
    canvas.drawRRect(bubble, Paint()..color = Colors.white);
    canvas.drawRRect(bubble, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.5);

    final pin0 = Path()
      ..moveTo(w / 2 - 12, h - 1)..lineTo(w / 2, h + pin)..lineTo(w / 2 + 12, h - 1)..close();
    canvas.drawPath(pin0, Paint()..color = Colors.white);
    canvas.drawPath(pin0, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.5);
    canvas.drawRect(Rect.fromLTWH(w / 2 - 12, h - 4, 24, 5), Paint()..color = Colors.white);

    const imgL = pad, imgT = (h - img) / 2;
    if (thumbnail != null) {
      canvas.save();
      canvas.clipRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(imgL, imgT, img, img), const Radius.circular(10)));
      canvas.drawImageRect(thumbnail,
        Rect.fromLTWH(0, 0, thumbnail.width.toDouble(), thumbnail.height.toDouble()),
        const Rect.fromLTWH(imgL, imgT, img, img), Paint());
      canvas.restore();
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(imgL, imgT, img, img), const Radius.circular(10)),
        Paint()..color = color.withValues(alpha: 0.12),
      );
      final ic = TextPainter(textDirection: TextDirection.ltr)
        ..text = TextSpan(
          text: String.fromCharCode(iconData.codePoint),
          style: TextStyle(fontSize: 28, fontFamily: iconData.fontFamily, package: iconData.fontPackage, color: color),
        )..layout();
      ic.paint(canvas, Offset(imgL + img / 2 - ic.width / 2, imgT + img / 2 - ic.height / 2));
    }

    const tl = imgL + img + 10;
    final lbl = label.length > 12 ? '${label.substring(0, 12)}...' : label;
    final tp = TextPainter(
      text: TextSpan(text: lbl, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF222222))),
      textDirection: TextDirection.ltr, maxLines: 2, ellipsis: '..',
    )..layout(maxWidth: w - tl - pad);
    tp.paint(canvas, Offset(tl, h / 2 - tp.height / 2));

    final pic = recorder.endRecording();
    final image = await pic.toImage(w.toInt(), (h + pin).toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  // ── Selection ─────────────────────────────────────────────────────────────

  void _selectActivity(Activity a) {
    setState(() { _selectedActivity = a; });
    _sheetController.forward(from: 0);
    _mapController.animateTo(AppLatLng(a.latitude!, a.longitude!));
  }

  void _clearSelection() {
    _sheetController.reverse().then((_) {
      if (mounted) setState(() { _selectedActivity = null; });
    });
  }

  void _openActivityDetail(Activity a) {
    Navigator.of(context, rootNavigator: true).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => DetailScreen.activity(activity: a),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  void _showFilterPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterPanel(
        current: _mapFilter,
        onChanged: (f) { setState(() => _mapFilter = f); Navigator.pop(context); },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    context.watch<ActivityService>();

    return Stack(
      children: [
        AppMap(
          initialCenter: _initialCenter,
          initialZoom: 13.5,
          controller: _mapController,
          markers: _markers,
          myLocationEnabled: true,
          onTap: (_) => _clearSelection(),
          mobileMapStyle: _mapStyle,
        ),
        _buildTopBar(),
        Positioned(
          right: 16,
          bottom: _selectedActivity != null ? 220 : 100,
          child: Column(
            children: [
              _mapBtn(Icons.add, () => _mapController.zoomIn()),
              const SizedBox(height: 8),
              _mapBtn(Icons.remove, () => _mapController.zoomOut()),
              const SizedBox(height: 8),
              _mapBtn(Icons.my_location, _goToMyLocation),
            ],
          ),
        ),
        if (_selectedActivity != null)
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                  .animate(_sheetAnimation),
              child: ActivityBottomSheet(
                activity: _selectedActivity!,
                onExpand: () => _openActivityDetail(_selectedActivity!),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppTheme.radiusMd,
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      const Icon(Icons.search, color: AppTheme.textSecondary, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'ค้นหากิจกรรม...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                          ),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _showFilterPanel,
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppTheme.radiusMd,
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.tune_rounded, color: AppTheme.textPrimary, size: 22),
                      if (!_mapFilter.showActivities)
                        Positioned(
                          top: 8, right: 8,
                          child: Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.markerUrgent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mapBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.radiusMd,
          boxShadow: AppTheme.softShadow,
        ),
        child: Icon(icon, color: AppTheme.textPrimary, size: 22),
      ),
    );
  }
}

const String _mapStyle = '''[
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]}
]''';
