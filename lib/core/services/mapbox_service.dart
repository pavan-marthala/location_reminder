import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:injectable/injectable.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

abstract class MapboxService {
  Future<void> init();
  String getAccessToken();
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
}
