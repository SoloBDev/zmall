import 'dart:math';

import 'package:zmall/utils/constants.dart';

/// Address Validation Service for courier delivery.
/// Provides utilities to compare addresses and detect duplicate/similar locations.
class AddressValidationService {
  /// Minimum distance in meters to consider two addresses as different.
  // static const double kMinimumDistanceThreshold = 50.0; // 50 meters

  /// Validates that pickup and dropoff addresses are not the same or too close.
  static AddressValidationResult validateAddresses({
    required double? pickupLat,
    required double? pickupLon,
    required double? dropoffLat,
    required double? dropoffLon,
    double? customThreshold,
  }) {
    // check for null coordinates
    if (pickupLat == null || pickupLon == null) {
      return AddressValidationResult(
        isValid: false,
        errorType: AddressValidationError.pickupNotSet,
        distance: 0,
      );
    }

    if(dropoffLat == null || dropoffLon == null) {
      return AddressValidationResult(
        isValid: false,
        errorType: AddressValidationError.dropoffNotSet,
        distance: 0,
      );
    }

    // Calculate distance between pickup and dropoff
    final distanceInMeters = calculateDistanceInMeters(
      pickupLat,
      pickupLon,
      dropoffLat,
      dropoffLon,
    );

    final threshold = customThreshold ?? kMinimumDistanceThreshold;

    // Check if locations are too close
    if (distanceInMeters < threshold) {
      return AddressValidationResult(
        isValid: false,
        errorType: AddressValidationError.sameLocation,
        distance: distanceInMeters,
      );
    }

    return AddressValidationResult(
      isValid: true,
      errorType: null,
      distance: distanceInMeters,
    );
  }

  /// Calculates the distance between two geographic coordinates in meters (Haversine formula).
  static double calculateDistanceInMeters(
    double lat1, double lon1, double lat2, double lon2,
  ) {
    const double earthRadiusMeters = 6371000; // Earth's radius in meters

    final double latDifferenceRadians = _degreesToRadians(lat2 - lat1);
    final double lonDifferenceRadians = _degreesToRadians(lon2 - lon1);

    // Convert latitiudes to radians
    final double lat1Radians = _degreesToRadians(lat1);
    final double lat2Radians = _degreesToRadians(lat2);

    final double squareOfHalfChordLength = 
      sin(latDifferenceRadians / 2) * sin(latDifferenceRadians / 2) +
      cos(lat1Radians) *
         cos(lat2Radians) *
         sin(lonDifferenceRadians / 2) *
         sin(lonDifferenceRadians / 2);
    
    final double angularDistanceRadians = 2 * atan2(
      sqrt(squareOfHalfChordLength),
      sqrt(1 - squareOfHalfChordLength),
    );

    final double distanceMeters = earthRadiusMeters * angularDistanceRadians;

    return distanceMeters;
  }

  static double _degreesToRadians(double degrees) => degrees * pi / 180.0;

  /// Returns a user-friendly error message based on the validation result.
  static String getErrorMessage(AddressValidationError? errorType) {
    switch (errorType) {
      case AddressValidationError.pickupNotSet:
        return 'Please select a pickup address.';
      case AddressValidationError.dropoffNotSet:
        return 'Please select a dropoff address.';
      case AddressValidationError.sameLocation:
        return 'Pickup and dropoff addresses cannot be the same or too close.';
      case null:
        return '';
    }
  }
}

/// Enum representing different types of address validation errors.
enum AddressValidationError {
  pickupNotSet,
  dropoffNotSet,
  sameLocation,
}

/// Result class for address validation operations.
class AddressValidationResult {
  final bool isValid;
  final AddressValidationError? errorType;
  final double distance;

  const AddressValidationResult({
    required this.isValid,
    required this.errorType,
    required this.distance,
  });

  String get errorMessage => AddressValidationService.getErrorMessage(errorType);
}