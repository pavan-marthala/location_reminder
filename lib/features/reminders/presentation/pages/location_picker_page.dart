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
import 'package:reminders/core/di/injection.dart';
import 'package:reminders/core/services/mapbox_service.dart';

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

  PointAnnotation? _handleAnnotation;

  double? _centerLat;
  double? _centerLng;
  double _radiusMeters = 200.0;
  bool _isLoadingLocation = false;

  Uint8List? _centerMarkerBytes;
  Uint8List? _handleMarkerBytes;
  Uint8List? _handleMarkerDraggingBytes;
  Uint8List? _circleRasterBytes;

  late final ValueNotifier<double> _radiusMetersNotifier;

  @override
  void initState() {
    super.initState();
    _centerLat = widget.initialLatitude;
    _centerLng = widget.initialLongitude;
    _radiusMeters = widget.initialRadiusMeters ?? 200.0;
    _radiusMetersNotifier = ValueNotifier<double>(_radiusMeters);
  }

  @override
  void dispose() {
    _radiusMetersNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadMarkerIcons() async {
    _centerMarkerBytes = await _createCenterMarkerBytes();
    _handleMarkerBytes = await _createCircularHandleBytes(dragging: false);
    _handleMarkerDraggingBytes = await _createCircularHandleBytes(dragging: true);
    _circleRasterBytes = await _createCircleRasterBytes();
  }

  Future<Uint8List> _createCenterMarkerBytes() async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const double width = 128.0;
    const double height = 128.0;
    final double cx = width / 2;
    final double cy = height / 2;

    // 1. Soft outer shadow for elevation
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawCircle(Offset(cx, cy + 2.0), 30.0, shadowPaint);

    // 2. Translucent outer blue accuracy/pulse ring
    final Paint haloPaint = Paint()
      ..color = const Color(0xFF00B0FF).withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 28.0, haloPaint);

    // 3. Crisp white concentric border ring
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 16.0, borderPaint);

    // 4. Vibrant blue core circle
    final Paint corePaint = Paint()
      ..color = const Color(0xFF00B0FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 12.0, corePaint);

    // 5. Light-source reflection highlight on the blue core
    final Paint highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 3.0, cy - 3.0), 3.5, highlightPaint);

    final ui.Image image = await recorder.endRecording().toImage(width.toInt(), height.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _createCircularHandleBytes({required bool dragging}) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const double width = 128.0;
    const double height = 128.0;
    final double cx = width / 2;
    final double cy = height / 2;

    // Google Maps-style circular drag handle
    // Base circle radius is 20.0. When dragging, it scales up to 25.0.
    final double radius = dragging ? 25.0 : 20.0;

    // 1. Soft outer drop shadow for elevation
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: dragging ? 0.35 : 0.25)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, dragging ? 8.0 : 4.0);
    canvas.drawCircle(Offset(cx, cy + (dragging ? 3.0 : 1.5)), radius, shadowPaint);

    // 2. Base white fill
    final Paint fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), radius, fillPaint);

    // 3. Vibrant blue border
    final Paint borderPaint = Paint()
      ..color = const Color(0xFF00B0FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(Offset(cx, cy), radius, borderPaint);

    // 4. Subtle inner light highlight
    final Paint innerHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset(cx, cy), radius - 1.5, innerHighlight);

    final ui.Image image = await recorder.endRecording().toImage(width.toInt(), height.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _createCircleRasterBytes() async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const double size = 512.0;
    final double cx = size / 2;
    final double cy = size / 2;
    // We leave a 16px margin for the soft glow, so radius is 240px
    const double radius = 240.0;

    // 1. Soft Blue Radial Gradient Fill (80-90% Map Visibility)
    final Paint fillPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(cx, cy),
        radius,
        [
          const Color(0xFF00B0FF).withValues(alpha: 0.03), // Lighter center (97% visibility)
          const Color(0xFF00B0FF).withValues(alpha: 0.20), // Darker edge (80% visibility)
        ],
      )
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), radius, fillPaint);

    // 2. Outer Blue Soft Glow (Thick, highly blurred)
    final Paint glowPaint = Paint()
      ..color = const Color(0xFF00B0FF).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    _drawDashedCircle(canvas, Offset(cx, cy), radius, glowPaint);

    // 3. Blue Base Border
    final Paint baseBorderPaint = Paint()
      ..color = const Color(0xFF00B0FF).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    _drawDashedCircle(canvas, Offset(cx, cy), radius, baseBorderPaint);

    // 4. White Highlight Stroke (Crisp inner reflection)
    final Paint highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    _drawDashedCircle(canvas, Offset(cx, cy), radius, highlightPaint);

    final ui.Image image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius, Paint paint, {double dashLength = 5.0, double spaceLength = 5.0}) {
    final double circumference = 2 * pi * radius;
    final int dashCount = (circumference / (dashLength + spaceLength)).floor();
    final double angleStep = 2 * pi / dashCount;
    final double dashAngle = angleStep * (dashLength / (dashLength + spaceLength));
    for (int i = 0; i < dashCount; i++) {
      final double startAngle = i * angleStep;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
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

    // Listen to handle dragging natively
    _handlePointManager!.dragEvents(
      onBegin: (annotation) {
        if (_handleAnnotation != null && _handleMarkerDraggingBytes != null) {
          _handleAnnotation!.image = _handleMarkerDraggingBytes;
          _handlePointManager!.update(_handleAnnotation!);
        }
      },
      onChanged: (annotation) async {
        if (_centerLat == null || _centerLng == null) return;
        if (_handleAnnotation == null) return;

        final handleCoords = annotation.geometry.coordinates;
        final distance = geo.Geolocator.distanceBetween(
          _centerLat!,
          _centerLng!,
          handleCoords.lat.toDouble(),
          handleCoords.lng.toDouble(),
        );

        final clamped = distance.clamp(100.0, 10000.0);
        
        _radiusMeters = clamped;
        _radiusMetersNotifier.value = clamped;

        // Calculate bearing and snap handle exactly to clamped circumference
        final bearingRad = _calculateBearing(
          _centerLat!,
          _centerLng!,
          handleCoords.lat.toDouble(),
          handleCoords.lng.toDouble(),
        );
        final snappedPos = _getPositionAlongBearing(_centerLat!, _centerLng!, _radiusMeters, bearingRad);

        // Update geometries in memory
        _handleAnnotation!.geometry = Point(coordinates: snappedPos);
        if (_handleMarkerDraggingBytes != null) {
          _handleAnnotation!.image = _handleMarkerDraggingBytes;
        }

        // Calculate bounding box for geofence circle
        const double earthRadius = 6378137.0;
        final double latOffset = (_radiusMeters / earthRadius) * (180.0 / pi);
        final double latRad = _centerLat! * pi / 180.0;
        final double lngOffset = (_radiusMeters / (earthRadius * cos(latRad))) * (180.0 / pi);

        final List<List<double>> coordinates = [
          [_centerLng! - lngOffset, _centerLat! + latOffset], // top-left
          [_centerLng! + lngOffset, _centerLat! + latOffset], // top-right
          [_centerLng! + lngOffset, _centerLat! - latOffset], // bottom-right
          [_centerLng! - lngOffset, _centerLat! - latOffset], // bottom-left
        ];

        // Concurrently update native handle and geofence coordinates
        Future.wait([
          _handlePointManager!.update(_handleAnnotation!),
          mapboxMap.style.setStyleSourceProperty('geofence-image-source', 'coordinates', coordinates),
        ]).catchError((e) {
          debugPrint('Error updating geofence annotations: $e');
          return const <void>[];
        });
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

  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final lat1Rad = lat1 * pi / 180;
    final lat2Rad = lat2 * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;

    final y = sin(dLon) * cos(lat2Rad);
    final x = cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(dLon);
    return atan2(y, x);
  }

  Position _getPositionAlongBearing(double latitude, double longitude, double radiusMeters, double bearingRad) {
    const double earthRadius = 6378137;
    final latRad = latitude * pi / 180;
    final radial = radiusMeters / earthRadius;
    final newLatRad = asin(sin(latRad) * cos(radial) + cos(latRad) * sin(radial) * cos(bearingRad));
    final newLngRad = (longitude * pi / 180) +
        atan2(sin(bearingRad) * sin(radial) * cos(latRad),
            cos(radial) - sin(latRad) * sin(newLatRad));
    return Position(newLngRad * 180 / pi, newLatRad * 180 / pi);
  }

  Position _getHandlePosition(double latitude, double longitude, double radiusMeters) {
    return _getPositionAlongBearing(latitude, longitude, radiusMeters, pi / 2);
  }

  Future<void> _drawCircleAndHandle() async {
    if (_centerLat == null || _centerLng == null) return;

    // 1. Draw Center Annotation (Native Ground Anchor Marker)
    if (_centerPointManager != null && _centerMarkerBytes != null) {
      await _centerPointManager!.deleteAll();
      await _centerPointManager!.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(_centerLng!, _centerLat!)),
          image: _centerMarkerBytes,
          iconAnchor: IconAnchor.CENTER,
        ),
      );
    }

    await _drawCircleAndHandleOnly();
  }

  Future<void> _drawCircleAndHandleOnly() async {
    if (_centerLat == null || _centerLng == null || _mapboxMap == null) return;

    final style = _mapboxMap!.style;
    final sourceId = 'geofence-image-source';
    final layerId = 'geofence-raster-layer';

    // Calculate geofence bounding box
    const double earthRadius = 6378137.0;
    final double latOffset = (_radiusMeters / earthRadius) * (180.0 / pi);
    final double latRad = _centerLat! * pi / 180.0;
    final double lngOffset = (_radiusMeters / (earthRadius * cos(latRad))) * (180.0 / pi);

    final List<List<double>> coordinates = [
      [_centerLng! - lngOffset, _centerLat! + latOffset], // top-left
      [_centerLng! + lngOffset, _centerLat! + latOffset], // top-right
      [_centerLng! + lngOffset, _centerLat! - latOffset], // bottom-right
      [_centerLng! - lngOffset, _centerLat! - latOffset], // bottom-left
    ];

    // Add or update the native ImageSource
    final existsSource = await style.styleSourceExists(sourceId);
    if (!existsSource) {
      final source = ImageSource(
        id: sourceId,
        coordinates: coordinates,
      );
      await style.addSource(source);

      if (_circleRasterBytes != null) {
        final mbxImage = MbxImage(width: 512, height: 512, data: _circleRasterBytes!);
        await style.updateStyleImageSourceImage(sourceId, mbxImage);
      }
    } else {
      await style.setStyleSourceProperty(sourceId, 'coordinates', coordinates);
    }

    // Add RasterLayer if it doesn't exist, placing it below map symbol/label layers
    final existsLayer = await style.styleLayerExists(layerId);
    if (!existsLayer) {
      String? firstSymbolId;
      try {
        final layers = await style.getStyleLayers();
        for (final layerInfo in layers) {
          if (layerInfo != null && layerInfo.type == 'symbol') {
            firstSymbolId = layerInfo.id;
            break;
          }
        }
      } catch (e) {
        debugPrint('Failed to get style layers: $e');
      }

      final layer = RasterLayer(
        id: layerId,
        sourceId: sourceId,
      );

      if (firstSymbolId != null) {
        await style.addLayerAt(layer, LayerPosition(below: firstSymbolId));
      } else {
        await style.addLayer(layer);
      }
    }

    // 3. Draw Draggable Handle Annotation (Draggable Circle)
    if (_handlePointManager != null && _handleMarkerBytes != null) {
      await _handlePointManager!.deleteAll();
      final handlePos = _getHandlePosition(_centerLat!, _centerLng!, _radiusMeters);

      _handleAnnotation = await _handlePointManager!.create(
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

  Future<void> _onConfirm() async {
    if (_centerLat == null || _centerLng == null) {
      showErrorToast(message: 'Please tap the map to select a location');
      return;
    }

    setState(() => _isLoadingLocation = true);

    try {
      final mapboxService = getIt<MapboxService>();
      final geocodeResult = await mapboxService.reverseGeocode(_centerLat!, _centerLng!);

      final result = LocationSelectionResult(
        latitude: _centerLat!,
        longitude: _centerLng!,
        radiusMeters: _radiusMeters,
        locationName: geocodeResult['name'],
        locationAddress: geocodeResult['address'],
      );

      if (mounted) {
        context.pop(result);
      }
    } catch (e) {
      final result = LocationSelectionResult(
        latitude: _centerLat!,
        longitude: _centerLng!,
        radiusMeters: _radiusMeters,
        locationName: 'Location (${_centerLat!.toStringAsFixed(4)}, ${_centerLng!.toStringAsFixed(4)})',
        locationAddress: 'Coordinates: ${_centerLat!.toStringAsFixed(6)}, ${_centerLng!.toStringAsFixed(6)}',
      );
      if (mounted) {
        context.pop(result);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
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
                    ValueListenableBuilder<double>(
                      valueListenable: _radiusMetersNotifier,
                      builder: (context, radius, child) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatRadius(radius),
                              style: typography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Drag handle on the edge to resize',
                              style: typography.bodySmall.copyWith(color: colors.textTertiary),
                            ),
                          ],
                        );
                      },
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
