import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:injectable/injectable.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:dio/dio.dart';

abstract class MapboxService {
  Future<void> init();
  String getAccessToken();
  Future<Map<String, String>> reverseGeocode(double lat, double lng);
}

@LazySingleton(as: MapboxService)
class MapboxServiceImpl implements MapboxService {
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
