class LocationSelectionResult {
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String? locationName;
  final String? locationAddress;

  const LocationSelectionResult({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.locationName,
    this.locationAddress,
  });
}
