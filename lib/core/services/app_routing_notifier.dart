import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:reminders/core/services/permission_validation_service.dart';

@lazySingleton
class AppRoutingNotifier extends ChangeNotifier with WidgetsBindingObserver {
  final PermissionValidationService _permissionService;

  bool _isBootstrapped = false;
  bool get isBootstrapped => _isBootstrapped;

  bool _isValidationValid = false;
  bool get isValidationValid => _isValidationValid;

  AppRoutingNotifier(this._permissionService) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isBootstrapped) {
      _checkPermissions();
    }
  }

  Future<void> initialize() async {
    await _checkPermissions();
  }

  Future<void> notifyPermissionChanged() async {
    if (_isBootstrapped) {
      await _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final ready = await _permissionService.isAppReady();
    if (_isValidationValid != ready || !_isBootstrapped) {
      _isValidationValid = ready;
      _isBootstrapped = true;
      notifyListeners();
    }
  }
}
