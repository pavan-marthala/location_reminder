import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:reminders/core/services/location_service.dart';
import 'package:reminders/core/services/notification_service.dart';
import 'package:reminders/core/services/background_service.dart';

class DeviceInfo {
  final String manufacturer;
  final String brand;
  final String model;
  final int sdkInt;
  final bool isOppoOrColorOS;

  const DeviceInfo({
    required this.manufacturer,
    required this.brand,
    required this.model,
    required this.sdkInt,
    required this.isOppoOrColorOS,
  });

  factory DeviceInfo.fromMap(Map<String, dynamic> map) {
    return DeviceInfo(
      manufacturer: map['manufacturer'] as String? ?? '',
      brand: map['brand'] as String? ?? '',
      model: map['model'] as String? ?? '',
      sdkInt: map['sdkInt'] as int? ?? 0,
      isOppoOrColorOS: map['isOppoOrColorOS'] as bool? ?? false,
    );
  }
}

enum ProtectionOverallState {
  protected,
  partiallyProtected,
  needsAttention,
}

class ProtectionStatus {
  final ProtectionOverallState overallState;
  final bool isBatteryOptimizationExempt;
  final bool isLocationAlwaysGranted;
  final bool isNotificationGranted;
  final bool isOppoOrColorOS;
  final bool oemReviewNeeded;
  final bool isForegroundServiceRunning;

  const ProtectionStatus({
    required this.overallState,
    required this.isBatteryOptimizationExempt,
    required this.isLocationAlwaysGranted,
    required this.isNotificationGranted,
    required this.isOppoOrColorOS,
    required this.oemReviewNeeded,
    required this.isForegroundServiceRunning,
  });
}

abstract class BackgroundProtectionService {
  Future<DeviceInfo> getDeviceInfo();
  Future<bool> isIgnoringBatteryOptimizations();
  Future<bool> requestBatteryOptimizationExemption();
  Future<bool> openBatteryOptimizationSettings();
  Future<bool> openApplicationDetails();
  Future<bool> openOppoAutoLaunchSettings();
  Future<bool> openOppoAppBatterySettings();
  Future<ProtectionStatus> getProtectionStatus();
}

@LazySingleton(as: BackgroundProtectionService)
class BackgroundProtectionServiceImpl implements BackgroundProtectionService {
  static const MethodChannel _channel =
      MethodChannel('com.example.reminders/background_protection');

  final LocationService _locationService;
  final NotificationService _notificationService;
  final BackgroundService _backgroundService;

  DeviceInfo? _cachedDeviceInfo;

  BackgroundProtectionServiceImpl(
    this._locationService,
    this._notificationService,
    this._backgroundService,
  );

  void _log(String tag, String message) {
    final formatted = '[$tag] $message';
    debugPrint(formatted);
  }

  @override
  Future<DeviceInfo> getDeviceInfo() async {
    if (_cachedDeviceInfo != null) return _cachedDeviceInfo!;
    try {
      final result =
          await _channel.invokeMapMethod<String, dynamic>('getDeviceInfo');
      if (result != null) {
        _cachedDeviceInfo = DeviceInfo.fromMap(result);
        _log(
          'BACKGROUND_PROTECTION',
          'DEVICE_INFO: manufacturer=${_cachedDeviceInfo!.manufacturer}, brand=${_cachedDeviceInfo!.brand}, model=${_cachedDeviceInfo!.model}, sdkInt=${_cachedDeviceInfo!.sdkInt}, isOppo=${_cachedDeviceInfo!.isOppoOrColorOS}',
        );
        return _cachedDeviceInfo!;
      }
    } catch (e) {
      _log('BACKGROUND_PROTECTION', 'DEVICE_INFO_ERROR: $e');
    }
    _cachedDeviceInfo = const DeviceInfo(
      manufacturer: 'Unknown',
      brand: 'Unknown',
      model: 'Unknown',
      sdkInt: 0,
      isOppoOrColorOS: false,
    );
    return _cachedDeviceInfo!;
  }

  @override
  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final isExempt =
          await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      final result = isExempt ?? true;
      _log('BACKGROUND_PROTECTION', 'BATTERY_OPTIMIZATION_STATUS: exempt=$result');
      return result;
    } catch (e) {
      _log('BACKGROUND_PROTECTION', 'BATTERY_OPTIMIZATION_CHECK_ERROR: $e');
      return true;
    }
  }

  @override
  Future<bool> requestBatteryOptimizationExemption() async {
    _log('BACKGROUND_PROTECTION', 'BATTERY_EXEMPTION_REQUEST initiated');
    try {
      final success = await _channel
          .invokeMethod<bool>('requestBatteryOptimizationExemption');
      final res = success ?? false;
      _log('BACKGROUND_PROTECTION', 'BATTERY_EXEMPTION_RESULT: success=$res');
      return res;
    } catch (e) {
      _log('BACKGROUND_PROTECTION', 'BATTERY_EXEMPTION_REQUEST_ERROR: $e');
      return false;
    }
  }

  @override
  Future<bool> openBatteryOptimizationSettings() async {
    _log('BACKGROUND_PROTECTION', 'OPENING_BATTERY_SETTINGS');
    try {
      final res = await _channel.invokeMethod<bool>('openBatteryOptimizationSettings');
      return res ?? false;
    } catch (e) {
      _log('BACKGROUND_PROTECTION', 'OPEN_BATTERY_SETTINGS_ERROR: $e');
      return openApplicationDetails();
    }
  }

  @override
  Future<bool> openApplicationDetails() async {
    _log('BACKGROUND_PROTECTION', 'OPENING_APP_DETAILS');
    try {
      final res = await _channel.invokeMethod<bool>('openApplicationDetails');
      return res ?? false;
    } catch (e) {
      _log('BACKGROUND_PROTECTION', 'OPEN_APP_DETAILS_ERROR: $e');
      return false;
    }
  }

  @override
  Future<bool> openOppoAutoLaunchSettings() async {
    _log('BACKGROUND_PROTECTION', 'OEM_SETTINGS_OPENED: Oppo AutoLaunch');
    try {
      final res = await _channel.invokeMethod<bool>('openOppoAutoLaunchSettings');
      if (res != true) {
        _log('BACKGROUND_PROTECTION', 'OEM_SETTINGS_FALLBACK: App Details');
      }
      return res ?? false;
    } catch (e) {
      _log('BACKGROUND_PROTECTION', 'OEM_SETTINGS_ERROR: $e. Falling back.');
      return openApplicationDetails();
    }
  }

  @override
  Future<bool> openOppoAppBatterySettings() async {
    _log('BACKGROUND_PROTECTION', 'OEM_SETTINGS_OPENED: Oppo App Battery Settings');
    try {
      final res = await _channel.invokeMethod<bool>('openOppoAppBatterySettings');
      return res ?? false;
    } catch (e) {
      _log('BACKGROUND_PROTECTION', 'OEM_SETTINGS_BATTERY_ERROR: $e. Falling back.');
      return openApplicationDetails();
    }
  }

  @override
  Future<ProtectionStatus> getProtectionStatus() async {
    final deviceInfo = await getDeviceInfo();
    if (deviceInfo.isOppoOrColorOS) {
      _log('BACKGROUND_PROTECTION', 'OEM_DETECTED: Oppo/ColorOS');
    }

    final isBatteryExempt = await isIgnoringBatteryOptimizations();

    final locPerm = await _locationService.checkPermission();
    final isLocationAlwaysGranted = locPerm == LocationPermission.always;

    final isNotificationGranted =
        await _notificationService.areNotificationsEnabled();

    final isForegroundServiceRunning = await _backgroundService.isRunning();

    final oemReviewNeeded = deviceInfo.isOppoOrColorOS;

    ProtectionOverallState overallState;
    if (!isLocationAlwaysGranted || !isNotificationGranted) {
      overallState = ProtectionOverallState.needsAttention;
    } else if (!isBatteryExempt || oemReviewNeeded) {
      overallState = ProtectionOverallState.partiallyProtected;
    } else {
      overallState = ProtectionOverallState.protected;
    }

    return ProtectionStatus(
      overallState: overallState,
      isBatteryOptimizationExempt: isBatteryExempt,
      isLocationAlwaysGranted: isLocationAlwaysGranted,
      isNotificationGranted: isNotificationGranted,
      isOppoOrColorOS: deviceInfo.isOppoOrColorOS,
      oemReviewNeeded: oemReviewNeeded,
      isForegroundServiceRunning: isForegroundServiceRunning,
    );
  }
}
