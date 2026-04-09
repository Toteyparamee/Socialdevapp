import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/problem_report.dart';
import '../services/problem_service.dart';
import '../widgets/problem_bottom_sheet.dart';
import '../widgets/filter_panel.dart';

import 'problem_detail_screen.dart';

class MapHomeScreen extends StatefulWidget {
  const MapHomeScreen({super.key});

  @override
  State<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends State<MapHomeScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  ProblemReport? _selectedProblem;
  final Set<ProblemCategory> _activeFilters = ProblemCategory.values.toSet();
  final _searchController = TextEditingController();
  final Map<String, BitmapDescriptor> _customIcons = {};

  late AnimationController _sheetController;
  late Animation<double> _sheetAnimation;

  static const _initialCamera = CameraPosition(
    target: LatLng(13.8200, 100.5700),
    zoom: 13.5,
  );

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
    // โหลดข้อมูลจาก API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProblemService>().fetchProblems().then((_) {
        _buildCustomMarkers();
      });
    });
  }

  Future<void> _goToMyLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        15,
      ),
    );
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  List<ProblemReport> get _filteredProblems {
    final problems = context.read<ProblemService>().problems;
    return problems.where((p) => _activeFilters.contains(p.category)).toList();
  }

  Set<Marker> get _markers {
    return _filteredProblems.map((p) {
      return Marker(
        markerId: MarkerId(p.id),
        position: p.location,
        icon: _customIcons[p.id] ?? BitmapDescriptor.defaultMarker,
        onTap: () => _selectProblem(p),
      );
    }).toSet();
  }

  IconData _categoryIcon(ProblemCategory category) {
    return switch (category) {
      ProblemCategory.flood => Icons.water_drop,
      ProblemCategory.trash => Icons.delete_outline,
      ProblemCategory.traffic => Icons.traffic,
      ProblemCategory.infrastructure => Icons.build,
      ProblemCategory.other => Icons.info_outline,
    };
  }

  Color _sourceColor(ProblemSource source) {
    return switch (source) {
      ProblemSource.user => Colors.red.shade600,
      ProblemSource.government => Colors.blue.shade600,
      ProblemSource.urgent => Colors.orange.shade700,
    };
  }

  Future<void> _buildCustomMarkers() async {
    for (final p in _filteredProblems) {
      if (_customIcons.containsKey(p.id)) continue;

      ui.Image? thumbnail;
      if (p.imageUrls.isNotEmpty) {
        try {
          final response = await http.get(Uri.parse(p.imageUrls.first));
          if (response.statusCode == 200) {
            final codec = await ui.instantiateImageCodec(response.bodyBytes);
            final frame = await codec.getNextFrame();
            thumbnail = frame.image;
          }
        } catch (_) {}
      }

      final icon = await _createCustomMarker(
        label: p.title,
        iconData: _categoryIcon(p.category),
        color: _sourceColor(p.source),
        thumbnail: thumbnail,
      );
      _customIcons[p.id] = icon;
    }
    if (mounted) setState(() {});
  }

  Future<BitmapDescriptor> _createCustomMarker({
    required String label,
    required IconData iconData,
    required Color color,
    ui.Image? thumbnail,
  }) async {
    const double width = 200;
    const double height = 80;
    const double pinHeight = 14;
    const double imgSize = 56;
    const double padding = 10;
    const double borderRadius = 14;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height + pinHeight));

    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(2, 3, width - 4, height - 2),
        const Radius.circular(borderRadius),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Bubble background
    final bubbleRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(borderRadius),
    );
    canvas.drawRRect(bubbleRect, Paint()..color = Colors.white);
    canvas.drawRRect(
      bubbleRect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Pin triangle
    final pinPath = Path()
      ..moveTo(width / 2 - 12, height - 1)
      ..lineTo(width / 2, height + pinHeight)
      ..lineTo(width / 2 + 12, height - 1)
      ..close();
    canvas.drawPath(pinPath, Paint()..color = Colors.white);
    canvas.drawPath(
      pinPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawRect(
      Rect.fromLTWH(width / 2 - 12, height - 4, 24, 5),
      Paint()..color = Colors.white,
    );

    // Thumbnail or icon
    const imgLeft = padding;
    const imgTop = (height - imgSize) / 2;

    if (thumbnail != null) {
      // Clip rounded rect for image
      canvas.save();
      canvas.clipRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(imgLeft, imgTop, imgSize, imgSize),
        const Radius.circular(10),
      ));
      final src = Rect.fromLTWH(0, 0, thumbnail.width.toDouble(), thumbnail.height.toDouble());
      const dst = Rect.fromLTWH(imgLeft, imgTop, imgSize, imgSize);
      canvas.drawImageRect(thumbnail, src, dst, Paint());
      canvas.restore();

      // Image border
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(imgLeft, imgTop, imgSize, imgSize),
          const Radius.circular(10),
        ),
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    } else {
      // Fallback: icon circle
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(imgLeft, imgTop, imgSize, imgSize),
          const Radius.circular(10),
        ),
        Paint()..color = color.withValues(alpha: 0.12),
      );
      final iconPainter = TextPainter(textDirection: TextDirection.ltr);
      iconPainter.text = TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: 28,
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
          color: color,
        ),
      );
      iconPainter.layout();
      iconPainter.paint(
        canvas,
        Offset(
          imgLeft + imgSize / 2 - iconPainter.width / 2,
          imgTop + imgSize / 2 - iconPainter.height / 2,
        ),
      );
    }

    // Category icon badge (top-right of image)
    if (thumbnail != null) {
      const badgeSize = 22.0;
      const badgeX = imgLeft + imgSize - badgeSize / 2;
      const badgeY = imgTop - badgeSize / 2 + 4;
      canvas.drawCircle(
        const Offset(badgeX + badgeSize / 2, badgeY + badgeSize / 2),
        badgeSize / 2 + 2,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        const Offset(badgeX + badgeSize / 2, badgeY + badgeSize / 2),
        badgeSize / 2,
        Paint()..color = color,
      );
      final badgeIcon = TextPainter(textDirection: TextDirection.ltr);
      badgeIcon.text = TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: 13,
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
          color: Colors.white,
        ),
      );
      badgeIcon.layout();
      badgeIcon.paint(
        canvas,
        Offset(
          badgeX + badgeSize / 2 - badgeIcon.width / 2,
          badgeY + badgeSize / 2 - badgeIcon.height / 2,
        ),
      );
    }

    // Label text
    const textLeft = imgLeft + imgSize + 10;
    final displayLabel = label.length > 12 ? '${label.substring(0, 12)}...' : label;
    final labelPainter = TextPainter(
      text: TextSpan(
        text: displayLabel,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF222222),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '..',
    );
    labelPainter.layout(maxWidth: width - textLeft - padding);
    labelPainter.paint(canvas, Offset(textLeft, height / 2 - labelPainter.height / 2));

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), (height + pinHeight).toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  void _selectProblem(ProblemReport problem) {
    setState(() => _selectedProblem = problem);
    _sheetController.forward(from: 0);
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(problem.location),
    );
  }

  void _clearSelection() {
    _sheetController.reverse().then((_) {
      if (mounted) setState(() => _selectedProblem = null);
    });
  }

  void _openDetail(ProblemReport problem) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ProblemDetailScreen(problem: problem),
        transitionsBuilder: (_, anim, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _showFilterPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterPanel(
        activeFilters: _activeFilters,
        onChanged: (filters) {
          setState(() {
            _activeFilters
              ..clear()
              ..addAll(filters);
          });
          _buildCustomMarkers();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // watch เพื่อ rebuild เมื่อข้อมูลเปลี่ยน
    context.watch<ProblemService>();

    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: _initialCamera,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (c) => _mapController = c,
            onTap: (_) => _clearSelection(),
            style: _mapStyle,
          ),

          // Top bar overlay
          _buildTopBar(),

          // Map controls (zoom + my location)
          Positioned(
            right: 16,
            bottom: _selectedProblem != null ? 220 : 100,
            child: Column(
              children: [
                _buildMapButton(
                  icon: Icons.add,
                  onTap: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                ),
                const SizedBox(height: 8),
                _buildMapButton(
                  icon: Icons.remove,
                  onTap: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                ),
                const SizedBox(height: 8),
                _buildMapButton(
                  icon: Icons.my_location,
                  onTap: _goToMyLocation,
                ),
              ],
            ),
          ),

          // Bottom sheet
          if (_selectedProblem != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(_sheetAnimation),
                child: ProblemBottomSheet(
                  problem: _selectedProblem!,
                  onExpand: () => _openDetail(_selectedProblem!),
                ),
              ),
            ),
        ],
      ),

    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              // Search bar
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
                            hintText: 'ค้นหาปัญหา...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            hintStyle: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 15,
                            ),
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
              // Filter button
              GestureDetector(
                onTap: _showFilterPanel,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppTheme.radiusMd,
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.tune_rounded,
                          color: AppTheme.textPrimary, size: 22),
                      if (_activeFilters.length < ProblemCategory.values.length)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 8,
                            height: 8,
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

  Widget _buildMapButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
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

// Minimal clean map style
const String _mapStyle = '''[
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]}
]''';
