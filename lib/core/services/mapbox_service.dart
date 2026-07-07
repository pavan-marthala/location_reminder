import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:injectable/injectable.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:dio/dio.dart';

class MapboxPrediction {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  MapboxPrediction({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

abstract class MapboxService {
  Future<void> init();
  String getAccessToken();
  Future<Map<String, String>> reverseGeocode(double lat, double lng);
  Future<List<MapboxPrediction>> searchPlaces(String query);
}

@LazySingleton(as: MapboxService)
class MapboxServiceImpl implements MapboxService {
  final Map<String, List<MapboxPrediction>> _sessionCache = {};

  @override
  Future<void> init() async {
    final token = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
    MapboxOptions.setAccessToken(token);
  }

  @override
  String getAccessToken() {
    return dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
  }

  @override
  Future<List<MapboxPrediction>> searchPlaces(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.length < 3) return [];
    if (_sessionCache.containsKey(clean)) {
      return _sessionCache[clean]!;
    }

    final token = getAccessToken();
    if (token.isEmpty) return [];

    try {
      final dio = Dio();
      final encodedQuery = Uri.encodeComponent(query);
      final url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/$encodedQuery.json?access_token=$token&limit=10';
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final features = response.data['features'] as List?;
        if (features != null) {
          final List<MapboxPrediction> results = [];
          for (final f in features) {
            final placeName = f['place_name'] as String?;
            final text = f['text'] as String?;
            final center = f['center'] as List?;
            if (placeName != null && center != null && center.length == 2) {
              final lng = (center[0] as num).toDouble();
              final lat = (center[1] as num).toDouble();

              final name = text ?? placeName.split(',').first.trim();
              String address = '';
              if (f['context'] != null) {
                final contextList = f['context'] as List;
                final contextParts = contextList
                    .map((c) => c['text'] as String?)
                    .where((t) => t != null && t != name)
                    .map((t) => t!)
                    .toList();
                if (contextParts.isNotEmpty) {
                  address = contextParts.join(', ');
                }
              }
              if (address.isEmpty) {
                if (text != null && placeName.startsWith(text)) {
                  address = placeName.substring(text.length).trim();
                  if (address.startsWith(',')) {
                    address = address.substring(1).trim();
                  }
                } else {
                  final parts = placeName.split(',');
                  address = parts.skip(1).join(', ').trim();
                }
              }
              if (address.isEmpty) {
                address = placeName;
              }

              results.add(MapboxPrediction(
                name: name,
                address: address,
                latitude: lat,
                longitude: lng,
              ));
            }
          }
          _sessionCache[clean] = results;
          return results;
        }
      }
    } catch (e) {
      debugPrint('Mapbox geocoding search failed: $e');
      rethrow;
    }
    return [];
  }

  @override
  Future<Map<String, String>> reverseGeocode(double lat, double lng) async {
    final token = getAccessToken();
    if (token.isEmpty) {
      return {
        'name': 'Selected Location',
        'address': 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}',
      };
    }
    try {
      final dio = Dio();
      final url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json?access_token=$token&limit=1';
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final features = response.data['features'] as List?;
        if (features != null && features.isNotEmpty) {
          final first = features.first;
          final placeName = first['place_name'] as String?;
          final text = first['text'] as String?;
          if (placeName != null) {
            final name = text ?? placeName.split(',').first.trim();
            String address = '';
            if (first['context'] != null) {
              final contextList = first['context'] as List;
              final contextParts = contextList
                  .map((c) => c['text'] as String?)
                  .where((t) => t != null && t != name)
                  .map((t) => t!)
                  .toList();
              if (contextParts.isNotEmpty) {
                address = contextParts.join(', ');
              }
            }
            if (address.isEmpty) {
              if (text != null && placeName.startsWith(text)) {
                address = placeName.substring(text.length).trim();
                if (address.startsWith(',')) {
                  address = address.substring(1).trim();
                }
              } else {
                final parts = placeName.split(',');
                address = parts.skip(1).join(', ').trim();
              }
            }
            if (address.isEmpty) {
              address = placeName;
            }
            return {
              'name': name,
              'address': address,
            };
          }
        }
      }
    } catch (e) {
      debugPrint('Mapbox reverse geocoding failed: $e');
    }
    return {
      'name': 'Location (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})',
      'address': 'Coordinates: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
    };
  }
}
