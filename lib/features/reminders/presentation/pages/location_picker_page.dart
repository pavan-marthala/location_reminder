import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:go_router/go_router.dart';
import 'package:reminders/core/theme/app_theme.dart';
import 'package:reminders/core/utils/app_button.dart';
import 'package:reminders/core/utils/app_toast.dart';
import 'package:reminders/features/reminders/domain/entities/location_selection_result.dart';

class LocationPickerPage extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final double? initialRadiusMeters;

  const LocationPickerPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialRadiusMeters,
  });

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _centerPointManager;
  PointAnnotationManager? _handlePointManager;
  PolygonAnnotationManager? _polygonAnnotationManager;

  double? _centerLat;
  double? _centerLng;
  double _radiusMeters = 200.0;
  bool _isLoadingLocation = false;

  Uint8List? _centerMarkerBytes;
  Uint8List? _handleMarkerBytes;

  @override
  void initState() {
    super.initState();
    _centerLat = widget.initialLatitude;
    _centerLng = widget.initialLongitude;
    _radiusMeters = widget.initialRadiusMeters ?? 200.0;
  }

  Future<void> _loadMarkerIcons() async {
    _centerMarkerBytes = await _createCenterMarkerBytes();
    _handleMarkerBytes = await _createHandleMarkerBytes();
  }

  Future<Uint8List> _createCenterMarkerBytes() async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const double width = 48.0;
    const double height = 64.0;

    final Path path = Path();
    path.moveTo(width / 2, 0);
    path.arcToPoint(
      const Offset(width, height * 0.4),
      radius: const Radius.circular(24),
      largeArc: false,
    );
    path.quadraticBezierTo(width, height * 0.7, width / 2, height);
    path.quadraticBezierTo(0, height * 0.7, 0, height * 0.4);
    path.arcToPoint(
      const Offset(width / 2, 0),
      radius: const Radius.circular(24),
      largeArc: false,
    );

    final Paint fillPaint = Paint()
      ..color = const Color(0xFFE53935)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawPath(path, borderPaint);

    final Paint innerCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(width / 2, height * 0.4), 8.0, innerCirclePaint);

    final Paint innerRedDotPaint = Paint()
      ..color = const Color(0xFFB71C1C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(width / 2, height * 0.4), 4.0, innerRedDotPaint);

    final ui.Image image = await recorder.endRecording().toImage(width.toInt(), height.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _createHandleMarkerBytes() async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const double size = 48.0;
    const double radius = size / 2;

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(const Offset(radius, radius + 2), radius - 6, shadowPaint);

    final Paint fillPaint = Paint()
      ..color = const Color(0xFF1976D2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(radius, radius), radius - 6, fillPaint);

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(const Offset(radius, radius), radius - 6, borderPaint);

    final Paint innerDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(radius, radius), 6.0, innerDotPaint);

    final ui.Image image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    await _loadMarkerIcons();

    // Enable location component (shows user location indicator)
    try {
      await mapboxMap.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
        ),
      );
    } catch (e) {
      debugPrint('Failed to enable Mapbox location component: $e');
    }

    // Initialize Annotation Managers
    _centerPointManager = await mapboxMap.annotations.createPointAnnotationManager();
    _handlePointManager = await mapboxMap.annotations.createPointAnnotationManager();
    _polygonAnnotationManager = await mapboxMap.annotations.createPolygonAnnotationManager();

    // Listen to handle dragging
    _handlePointManager!.dragEvents(
      onChanged: (annotation) {
        if (_centerLat == null || _centerLng == null) return;

        final handleCoords = annotation.geometry.coordinates;
        final distance = geo.Geolocator.distanceBetween(
          _centerLat!,
          _centerLng!,
          handleCoords.lat.toDouble(),
          handleCoords.lng.toDouble(),
        );

        final clamped = distance.clamp(100.0, 10000.0);
        setState(() {
          _radiusMeters = clamped;
        });

        _drawCircleAndHandleOnly();
      },
      onEnd: (annotation) {
        _drawCircleAndHandle();
      },
    );

    // If we have an existing location, load and zoom to it
    if (_centerLat != null && _centerLng != null) {
      await _drawCircleAndHandle();
      await _mapboxMap!.setCamera(
        CameraOptions(
          center: Point(coordinates: Position(_centerLng!, _centerLat!)),
          zoom: _getZoomLevelForRadius(_radiusMeters),
        ),
      );
    } else {
      // Otherwise zoom to current user position
      _zoomToUserLocation();
    }
  }

  Future<void> _zoomToUserLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );
      if (mounted && _mapboxMap != null) {
        await _mapboxMap!.setCamera(
          CameraOptions(
            center: Point(coordinates: Position(position.longitude, position.latitude)),
            zoom: 14.0,
          ),
        );
      }
    } catch (e) {
      showErrorToast(message: 'Failed to fetch current location');
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  double _getZoomLevelForRadius(double radius) {
    if (radius <= 200) return 15.0;
    if (radius <= 500) return 14.0;
    if (radius <= 1000) return 13.0;
    if (radius <= 3000) return 12.0;
    if (radius <= 6000) return 11.0;
    return 10.0;
  }

  List<List<Position>> _generateCirclePolygon(double latitude, double longitude, double radiusMeters) {
    const int points = 64;
    final List<Position> coordinates = [];
    const double earthRadius = 6378137; // in meters

    final latRad = latitude * pi / 180;
    final lngRad = longitude * pi / 180;

    for (int i = 0; i <= points; i++) {
      final angle = i * 2 * pi / points;

      final radial = radiusMeters / earthRadius;
      final newLatRad = asin(sin(latRad) * cos(radial) + cos(latRad) * sin(radial) * cos(angle));
      final newLngRad = lngRad +
          atan2(sin(angle) * sin(radial) * cos(latRad),
              cos(radial) - sin(latRad) * sin(newLatRad));

      coordinates.add(Position(newLngRad * 180 / pi, newLatRad * 180 / pi));
    }
    return [coordinates];
  }

  Position _getHandlePosition(double latitude, double longitude, double radiusMeters) {
    const double earthRadius = 6378137;
    final latRad = latitude * pi / 180;
    final radial = radiusMeters / earthRadius;
    final newLatRad = asin(sin(latRad) * cos(radial) + cos(latRad) * sin(radial) * cos(pi / 2));
    final newLngRad = (longitude * pi / 180) +
        atan2(sin(pi / 2) * sin(radial) * cos(latRad),
            cos(radial) - sin(latRad) * sin(newLatRad));
    return Position(newLngRad * 180 / pi, newLatRad * 180 / pi);
  }

  Future<void> _drawCircleAndHandle() async {
    if (_centerLat == null || _centerLng == null) return;

    // 1. Draw Center Annotation
    if (_centerPointManager != null && _centerMarkerBytes != null) {
      await _centerPointManager!.deleteAll();
      await _centerPointManager!.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(_centerLng!, _centerLat!)),
          image: _centerMarkerBytes,
          iconAnchor: IconAnchor.BOTTOM,
        ),
      );
    }

    await _drawCircleAndHandleOnly();
  }

  Future<void> _drawCircleAndHandleOnly() async {
    if (_centerLat == null || _centerLng == null) return;

    // 2. Draw Geofence Circle Polygon
    if (_polygonAnnotationManager != null) {
      await _polygonAnnotationManager!.deleteAll();
      final circlePolygon = _generateCirclePolygon(_centerLat!, _centerLng!, _radiusMeters);
      await _polygonAnnotationManager!.create(
        PolygonAnnotationOptions(
          geometry: Polygon(coordinates: circlePolygon),
          fillColor: Colors.blue.withValues(alpha: 0.18).toARGB32(),
          fillOutlineColor: Colors.blue.toARGB32(),
        ),
      );
    }

    // 3. Draw Draggable Handle Annotation
    if (_handlePointManager != null && _handleMarkerBytes != null) {
      await _handlePointManager!.deleteAll();
      final handlePos = _getHandlePosition(_centerLat!, _centerLng!, _radiusMeters);
      await _handlePointManager!.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: handlePos),
          image: _handleMarkerBytes,
          iconAnchor: IconAnchor.CENTER,
          isDraggable: true,
        ),
      );
    }
  }

  void _onMapTapped(Position pos) {
    setState(() {
      _centerLat = pos.lat.toDouble();
      _centerLng = pos.lng.toDouble();
    });
    _drawCircleAndHandle();
  }

  String _formatRadius(double meters) {
    if (meters >= 1000) {
      return 'Radius: ${(meters / 1000).toStringAsFixed(1)} km';
    } else {
      return 'Radius: ${meters.round()} m';
    }
  }

  void _onConfirm() {
    if (_centerLat == null || _centerLng == null) {
      showErrorToast(message: 'Please tap the map to select a location');
      return;
    }

    final result = LocationSelectionResult(
      latitude: _centerLat!,
      longitude: _centerLng!,
      radiusMeters: _radiusMeters,
      locationName: 'Location (${_centerLat!.toStringAsFixed(4)}, ${_centerLng!.toStringAsFixed(4)})',
    );

    context.pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Geofence Picker'),
        actions: [
          IconButton(
            icon: _isLoadingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.my_location_rounded),
            onPressed: _isLoadingLocation ? null : _zoomToUserLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapbox Widget
          MapWidget(
            key: const ValueKey("locationPickerMap"),
            cameraOptions: CameraOptions(
              zoom: 12.0,
            ),
            onMapCreated: _onMapCreated,
            onTapListener: (context) {
              _onMapTapped(context.point.coordinates);
            },
          ),

          // Instruction Overlay if no location is selected yet
          if (_centerLat == null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.card.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.touch_app_rounded, color: colors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tap anywhere on the map to set a location geofence.',
                        style: typography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Control Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: colors.border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_centerLat != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatRadius(_radiusMeters),
                          style: typography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Drag handle on the edge to resize',
                          style: typography.bodySmall.copyWith(color: colors.textTertiary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  AppButton(
                    width: double.infinity,
                    text: 'Confirm Location',
                    color: colors.primary,
                    onPressed: _centerLat != null ? _onConfirm : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
