import 'dart:async';
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
import 'package:reminders/features/reminders/domain/entities/reminder_entity.dart';
import 'package:reminders/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:reminders/features/reminders/domain/services/duplicate_detection_service.dart';
import 'package:reminders/core/di/injection.dart';
import 'package:reminders/core/services/mapbox_service.dart';

class NearbyGeofenceRenderer {
  final MapboxMap mapboxMap;
  final PointAnnotationManager nearbyPointManager;
  final Uint8List markerBytes;
  final Uint8List circleBytes;
  final int? excludeId;

  final Set<int> _activeNearbyIds = {};
  final Map<String, ReminderEntity> annotationToReminder = {};

  NearbyGeofenceRenderer({
    required this.mapboxMap,
    required this.nearbyPointManager,
    required this.markerBytes,
    required this.circleBytes,
    this.excludeId,
  });

  Future<void> updateNearby({
    required List<ReminderEntity> allReminders,
    required double centerLat,
    required double centerLng,
    required double searchRadiusKm,
    required int limit,
  }) async {
    // 1. Filter reminders within search radius
    final filtered = allReminders.where((r) {
      if (excludeId != null && r.id == excludeId) return false;
      final distance = geo.Geolocator.distanceBetween(
        centerLat,
        centerLng,
        r.latitude,
        r.longitude,
      );
      return distance <= searchRadiusKm * 1000;
    }).toList();

    // 2. Sort by distance ascending
    filtered.sort((a, b) {
      final distA = geo.Geolocator.distanceBetween(centerLat, centerLng, a.latitude, a.longitude);
      final distB = geo.Geolocator.distanceBetween(centerLat, centerLng, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });

    // 3. Limit to top N closest reminders
    final nearby = filtered.take(limit).toList();
    final nearbyIds = nearby.map((r) => r.id!).toSet();

    // 4. Identify expired nearby geofences and remove them from Mapbox style layers
    final idsToRemove = _activeNearbyIds.difference(nearbyIds);
    final style = mapboxMap.style;

    for (final id in idsToRemove) {
      final layerId = 'geofence-layer-$id';
      final sourceId = 'geofence-source-$id';
      try {
        if (await style.styleLayerExists(layerId)) {
          await style.removeStyleLayer(layerId);
        }
        if (await style.styleSourceExists(sourceId)) {
          await style.removeStyleSource(sourceId);
        }
      } catch (e) {
        debugPrint('Error cleaning up nearby geofence: $e');
      }
      _activeNearbyIds.remove(id);
    }

    // 5. Clean up existing annotations
    await nearbyPointManager.deleteAll();
    annotationToReminder.clear();

    // 6. Draw each nearby reminder geofence circle (ImageSource + RasterLayer) & marker
    for (final r in nearby) {
      final id = r.id!;
      final sourceId = 'geofence-source-$id';
      final layerId = 'geofence-layer-$id';

      const double earthRadius = 6378137.0;
      final double latOffset = (r.radiusMeters / earthRadius) * (180.0 / pi);
      final double latRad = r.latitude * pi / 180.0;
      final double lngOffset = (r.radiusMeters / (earthRadius * cos(latRad))) * (180.0 / pi);

      final List<List<double>> coordinates = [
        [r.longitude - lngOffset, r.latitude + latOffset],
        [r.longitude + lngOffset, r.latitude + latOffset],
        [r.longitude + lngOffset, r.latitude - latOffset],
        [r.longitude - lngOffset, r.latitude - latOffset],
      ];

      try {
        final existsSource = await style.styleSourceExists(sourceId);
        if (!existsSource) {
          final source = ImageSource(id: sourceId, coordinates: coordinates);
          await style.addSource(source);
          final mbxImage = MbxImage(width: 512, height: 512, data: circleBytes);
          await style.updateStyleImageSourceImage(sourceId, mbxImage);
        } else {
          await style.setStyleSourceProperty(sourceId, 'coordinates', coordinates);
        }

        final existsLayer = await style.styleLayerExists(layerId);
        if (!existsLayer) {
          final layer = RasterLayer(id: layerId, sourceId: sourceId);
          // Place below main geofence layer to preserve active styling hierarchy
          await style.addLayerAt(layer, LayerPosition(below: 'geofence-raster-layer'));
        }
      } catch (e) {
        debugPrint('Error rendering nearby geofence raster for ID $id: $e');
      }

      // Add point marker
      final opt = PointAnnotationOptions(
        geometry: Point(coordinates: Position(r.longitude, r.latitude)),
        image: markerBytes,
        iconAnchor: IconAnchor.CENTER,
      );
      final annot = await nearbyPointManager.create(opt);
      annotationToReminder[annot.id] = r;
      _activeNearbyIds.add(id);
    }
  }

  Future<void> clearAll() async {
    try {
      final style = mapboxMap.style;
      for (final id in _activeNearbyIds) {
        final layerId = 'geofence-layer-$id';
        final sourceId = 'geofence-source-$id';
        try {
          if (await style.styleLayerExists(layerId)) {
            await style.removeStyleLayer(layerId);
          }
          if (await style.styleSourceExists(sourceId)) {
            await style.removeStyleSource(sourceId);
          }
        } catch (_) {}
      }
      _activeNearbyIds.clear();
      annotationToReminder.clear();
      await nearbyPointManager.deleteAll();
    } catch (_) {}
  }
}

class LocationPickerPage extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final double? initialRadiusMeters;
  final int? editingReminderId;

  const LocationPickerPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialRadiusMeters,
    this.editingReminderId,
  });

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _centerPointManager;
  PointAnnotationManager? _handlePointManager;

  PointAnnotation? _handleAnnotation;
  NearbyGeofenceRenderer? _nearbyRenderer;

  double? _centerLat;
  double? _centerLng;
  double _radiusMeters = 200.0;
  bool _isLoadingLocation = false;

  Uint8List? _centerMarkerBytes;
  Uint8List? _handleMarkerBytes;
  Uint8List? _handleMarkerDraggingBytes;
  Uint8List? _circleRasterBytes;
  Uint8List? _nearbyMarkerBytes;
  Uint8List? _nearbyCircleBytes;

  late final ValueNotifier<double> _radiusMetersNotifier;

  // Search enhancement variables
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  List<MapboxPrediction> _predictions = [];
  bool _isSearching = false;
  String? _searchError;
  Timer? _debounceTimer;

  // Nearby reminders variables
  List<ReminderEntity> _allReminders = [];
  static const double _nearbySearchRadiusKm = 5.0; // 5 km configurable constant
  static const int _nearbyRenderLimit = 15; // rendering queue limit constant

  @override
  void initState() {
    super.initState();
    _centerLat = widget.initialLatitude;
    _centerLng = widget.initialLongitude;
    _radiusMeters = widget.initialRadiusMeters ?? 200.0;
    _radiusMetersNotifier = ValueNotifier<double>(_radiusMeters);
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _loadAllReminders();
  }

  @override
  void dispose() {
    _radiusMetersNotifier.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAllReminders() async {
    try {
      final repository = getIt<ReminderRepository>();
      _allReminders = await repository.getAllReminders();
      _updateNearbyMarkers();
    } catch (e) {
      debugPrint('Failed to load existing reminders: $e');
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().length < 3) {
      setState(() {
        _predictions = [];
        _isSearching = false;
        _searchError = null;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      setState(() {
        _isSearching = true;
        _searchError = null;
      });
      try {
        final results = await getIt<MapboxService>().searchPlaces(query);
        if (mounted) {
          setState(() {
            _predictions = results;
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSearching = false;
            _searchError = 'Search failed. Check your internet connection.';
          });
        }
      }
    });
  }

  Future<void> _onPredictionSelected(MapboxPrediction prediction) async {
    // Dismiss suggestions list & keyboard
    setState(() {
      _predictions = [];
      _searchController.text = prediction.name;
    });
    _searchFocusNode.unfocus();

    // 1. Animate camera
    if (_mapboxMap != null) {
      await _mapboxMap!.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(prediction.longitude, prediction.latitude)),
          zoom: _getZoomLevelForRadius(_radiusMeters),
        ),
        MapAnimationOptions(duration: 900),
      );
    }

    // 2. Update center latitude/longitude
    setState(() {
      _centerLat = prediction.latitude;
      _centerLng = prediction.longitude;
    });

    // 3. Move center marker, radius handle, redraw geofence circles
    await _drawCircleAndHandle();

    // 4. Refresh displayed address (reverse geocoding to sync metadata)
    setState(() => _isLoadingLocation = true);
    try {
      await getIt<MapboxService>().reverseGeocode(_centerLat!, _centerLng!);
    } catch (_) {}
    setState(() => _isLoadingLocation = false);
  }

  Future<void> _loadMarkerIcons() async {
    _centerMarkerBytes = await _createCenterMarkerBytes();
    _handleMarkerBytes = await _createCircularHandleBytes(dragging: false);
    _handleMarkerDraggingBytes = await _createCircularHandleBytes(dragging: true);
    _circleRasterBytes = await _createCircleRasterBytes();
    _nearbyMarkerBytes = await _createNearbyMarkerBytes();
    _nearbyCircleBytes = await _createNearbyCircleRasterBytes();
  }

  Future<Uint8List> _createCenterMarkerBytes() async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const double width = 128.0;
    const double height = 128.0;
    final double cx = width / 2;
    final double cy = height / 2;

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawCircle(Offset(cx, cy + 2.0), 30.0, shadowPaint);

    final Paint haloPaint = Paint()
      ..color = const Color(0xFF00B0FF).withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 28.0, haloPaint);

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 16.0, borderPaint);

    final Paint corePaint = Paint()
      ..color = const Color(0xFF00B0FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 12.0, corePaint);

    final Paint highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 3.0, cy - 3.0), 3.5, highlightPaint);

    final ui.Image image = await recorder.endRecording().toImage(width.toInt(), height.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _createNearbyMarkerBytes() async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const double width = 96.0;
    const double height = 96.0;
    final double cx = width / 2;
    final double cy = height / 2;

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(Offset(cx, cy + 1.5), 18.0, shadowPaint);

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 14.0, borderPaint);

    final Paint corePaint = Paint()
      ..color = Colors.indigo
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 10.0, corePaint);

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

    final double radius = dragging ? 25.0 : 20.0;

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: dragging ? 0.35 : 0.25)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, dragging ? 8.0 : 4.0);
    canvas.drawCircle(Offset(cx, cy + (dragging ? 3.0 : 1.5)), radius, shadowPaint);

    final Paint fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), radius, fillPaint);

    final Paint borderPaint = Paint()
      ..color = const Color(0xFF00B0FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(Offset(cx, cy), radius, borderPaint);

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
    const double radius = 240.0;

    final Paint fillPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(cx, cy),
        radius,
        [
          const Color(0xFF00B0FF).withValues(alpha: 0.03),
          const Color(0xFF00B0FF).withValues(alpha: 0.20),
        ],
      )
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), radius, fillPaint);

    final Paint glowPaint = Paint()
      ..color = const Color(0xFF00B0FF).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    _drawDashedCircle(canvas, Offset(cx, cy), radius, glowPaint);

    final Paint baseBorderPaint = Paint()
      ..color = const Color(0xFF00B0FF).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    _drawDashedCircle(canvas, Offset(cx, cy), radius, baseBorderPaint);

    final Paint highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    _drawDashedCircle(canvas, Offset(cx, cy), radius, highlightPaint);

    final ui.Image image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _createNearbyCircleRasterBytes() async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const double size = 512.0;
    final double cx = size / 2;
    final double cy = size / 2;
    const double radius = 240.0;

    final Paint fillPaint = Paint()
      ..color = const Color(0xFFFF9800).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), radius, fillPaint);

    final Paint borderPaint = Paint()
      ..color = const Color(0xFFFF9800).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset(cx, cy), radius, borderPaint);

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

    _centerPointManager = await mapboxMap.annotations.createPointAnnotationManager();
    _handlePointManager = await mapboxMap.annotations.createPointAnnotationManager();
    final nearbyPointManager = await mapboxMap.annotations.createPointAnnotationManager();

    if (_nearbyMarkerBytes != null && _nearbyCircleBytes != null) {
      _nearbyRenderer = NearbyGeofenceRenderer(
        mapboxMap: mapboxMap,
        nearbyPointManager: nearbyPointManager,
        markerBytes: _nearbyMarkerBytes!,
        circleBytes: _nearbyCircleBytes!,
        excludeId: widget.editingReminderId,
      );

      nearbyPointManager.tapEvents(onTap: (annotation) {
        if (_nearbyRenderer != null) {
          final reminder = _nearbyRenderer!.annotationToReminder[annotation.id];
          if (reminder != null) {
            _showReminderInfoPopup(reminder);
          }
        }
      });
    }

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

        final bearingRad = _calculateBearing(
          _centerLat!,
          _centerLng!,
          handleCoords.lat.toDouble(),
          handleCoords.lng.toDouble(),
        );
        final snappedPos = _getPositionAlongBearing(_centerLat!, _centerLng!, _radiusMeters, bearingRad);

        _handleAnnotation!.geometry = Point(coordinates: snappedPos);
        if (_handleMarkerDraggingBytes != null) {
          _handleAnnotation!.image = _handleMarkerDraggingBytes;
        }

        const double earthRadius = 6378137.0;
        final double latOffset = (_radiusMeters / earthRadius) * (180.0 / pi);
        final double latRad = _centerLat! * pi / 180.0;
        final double lngOffset = (_radiusMeters / (earthRadius * cos(latRad))) * (180.0 / pi);

        final List<List<double>> coordinates = [
          [_centerLng! - lngOffset, _centerLat! + latOffset],
          [_centerLng! + lngOffset, _centerLat! + latOffset],
          [_centerLng! + lngOffset, _centerLat! - latOffset],
          [_centerLng! - lngOffset, _centerLat! - latOffset],
        ];

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

    if (_centerLat != null && _centerLng != null) {
      await _drawCircleAndHandle();
      await _mapboxMap!.setCamera(
        CameraOptions(
          center: Point(coordinates: Position(_centerLng!, _centerLat!)),
          zoom: _getZoomLevelForRadius(_radiusMeters),
        ),
      );
    } else {
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
      if (mounted) {
        setState(() {
          // If no coordinate has been selected, set the initial center to the user's current location
          if (_centerLat == null || _centerLng == null) {
            _centerLat = position.latitude;
            _centerLng = position.longitude;
          }
        });
        if (_mapboxMap != null) {
          await _mapboxMap!.setCamera(
            CameraOptions(
              center: Point(coordinates: Position(position.longitude, position.latitude)),
              zoom: 14.0,
            ),
          );
        }
        await _drawCircleAndHandle();
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

  Future<void> _updateNearbyMarkers() async {
    if (_centerLat == null || _centerLng == null || _nearbyRenderer == null) return;

    await _nearbyRenderer!.updateNearby(
      allReminders: _allReminders,
      centerLat: _centerLat!,
      centerLng: _centerLng!,
      searchRadiusKm: _nearbySearchRadiusKm,
      limit: _nearbyRenderLimit,
    );
  }

  void _showReminderInfoPopup(ReminderEntity reminder) {
    final colors = context.appColors;
    final typography = context.appTypography;

    final distance = geo.Geolocator.distanceBetween(
      _centerLat ?? reminder.latitude,
      _centerLng ?? reminder.longitude,
      reminder.latitude,
      reminder.longitude,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reminder.title,
                  style: typography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPopupRow(context, Icons.place_outlined, 'Distance', _formatDistance(distance)),
              const SizedBox(height: 8),
              _buildPopupRow(context, Icons.radar, 'Geofence Radius', '${reminder.radiusMeters.round()} m'),
              const SizedBox(height: 8),
              _buildPopupRow(
                context,
                Icons.info_outline,
                'Status',
                reminder.status.toUpperCase(),
                valueColor: reminder.isEnabled ? colors.primary : colors.textSecondary,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: colors.primary)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPopupRow(BuildContext context, IconData icon, String label, String value, {Color? valueColor}) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Row(
      children: [
        Icon(icon, size: 18, color: colors.textTertiary),
        const SizedBox(width: 8),
        Text('$label: ', style: typography.bodyMedium.copyWith(color: colors.textSecondary)),
        Expanded(
          child: Text(
            value,
            style: typography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    } else {
      return '${meters.round()} m';
    }
  }

  String _formatRadius(double meters) {
    if (meters >= 1000) {
      return 'Radius: ${(meters / 1000).toStringAsFixed(1)} km';
    } else {
      return 'Radius: ${meters.round()} m';
    }
  }

  Future<void> _drawCircleAndHandle() async {
    if (_centerLat == null || _centerLng == null) return;

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
    await _updateNearbyMarkers();
  }

  Future<void> _drawCircleAndHandleOnly() async {
    if (_centerLat == null || _centerLng == null || _mapboxMap == null) return;

    final style = _mapboxMap!.style;
    const sourceId = 'geofence-image-source';
    const layerId = 'geofence-raster-layer';

    const double earthRadius = 6378137.0;
    final double latOffset = (_radiusMeters / earthRadius) * (180.0 / pi);
    final double latRad = _centerLat! * pi / 180.0;
    final double lngOffset = (_radiusMeters / (earthRadius * cos(latRad))) * (180.0 / pi);

    final List<List<double>> coordinates = [
      [_centerLng! - lngOffset, _centerLat! + latOffset],
      [_centerLng! + lngOffset, _centerLat! + latOffset],
      [_centerLng! + lngOffset, _centerLat! - latOffset],
      [_centerLng! - lngOffset, _centerLat! - latOffset],
    ];

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

  Future<bool?> _showDuplicateWarningDialog(List<DuplicateReminder> duplicates) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: colors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Duplicate Reminder Detected',
                  style: typography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You already have one or more reminders very close to this location.',
                  style: typography.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nearby reminders:',
                  style: typography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: duplicates.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final dup = duplicates[index];
                      final distanceStr = dup.distanceMeters >= 1000
                          ? '${(dup.distanceMeters / 1000).toStringAsFixed(1)} km'
                          : '${dup.distanceMeters.round()} m';
                      final status = dup.reminder.status.isNotEmpty
                          ? '${dup.reminder.status[0].toUpperCase()}${dup.reminder.status.substring(1)}'
                          : '';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dup.reminder.title,
                                    style: typography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    status,
                                    style: typography.bodySmall.copyWith(
                                      color: dup.reminder.status == 'active'
                                          ? colors.primary
                                          : colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              distanceStr,
                              style: typography.bodyMedium.copyWith(
                                color: colors.warning,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Would you still like to create this reminder?',
                  style: typography.bodyMedium,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: typography.labelLarge.copyWith(color: colors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Create Anyway',
                style: typography.labelLarge.copyWith(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onConfirm() async {
    if (_centerLat == null || _centerLng == null) {
      showErrorToast(message: 'Please tap the map to select a location');
      return;
    }

    print('''
[DUPLICATE] Confirm location pressed
Selected:
Lat = $_centerLat
Lng = $_centerLng
Editing Reminder ID = ${widget.editingReminderId}
Total cached reminders = ${_allReminders.length}
''');

    print('[DUPLICATE] Calling DuplicateDetectionService');
    final duplicateService = getIt<DuplicateDetectionService>();
    final duplicates = duplicateService.checkForDuplicates(
      latitude: _centerLat!,
      longitude: _centerLng!,
      allReminders: _allReminders,
      excludeId: widget.editingReminderId,
    );
    print('[DUPLICATE] Duplicate count = ${duplicates.length}');

    if (duplicates.isNotEmpty) {
      print('[DUPLICATE] Showing duplicate dialog');
      final proceed = await _showDuplicateWarningDialog(duplicates);
      if (proceed != true) {
        return;
      }
    } else {
      print('[DUPLICATE] No duplicates found');
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

          // Instruction Overlay if no location is selected yet (and not searching)
          if (_centerLat == null && _predictions.isEmpty && !_isSearching)
            Positioned(
              top: 80,
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

          // Search Field Overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: colors.card,
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
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: typography.bodyMedium,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (val) {
                      _onSearchChanged(val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search places...',
                      prefixIcon: Icon(Icons.search, color: colors.textTertiary),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _predictions = [];
                                  _searchError = null;
                                });
                                _onSearchChanged('');
                              },
                            ),
                        ],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                if (_isSearching || _predictions.isNotEmpty || _searchError != null || (_searchController.text.trim().length >= 3 && _predictions.isEmpty)) ...[
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 280),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isSearching)
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: LinearProgressIndicator(),
                                ),
                              ),
                            if (_searchError != null)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  _searchError!,
                                  style: typography.bodyMedium.copyWith(color: colors.error),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            if (!_isSearching && _searchError == null && _searchController.text.trim().length >= 3 && _predictions.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'No results found.',
                                  style: typography.bodyMedium.copyWith(color: colors.textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ..._predictions.map((p) {
                              return ListTile(
                                leading: Icon(Icons.location_on_rounded, color: colors.primary),
                                title: Text(
                                  p.name,
                                  style: typography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  p.address,
                                  style: typography.bodySmall.copyWith(color: colors.textSecondary),
                                ),
                                onTap: () => _onPredictionSelected(p),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
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
