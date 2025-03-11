import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class LocationDistanceWidget extends StatelessWidget {
  final String destination;
  final String address;
  final String distanceToPickup;
  final String estimatedTime;
  
  // Add location coordinates for more precise distance calculation
  final double driverLatitude;
  final double driverLongitude;
  final double pickupLatitude;
  final double pickupLongitude;

  const LocationDistanceWidget({
    Key? key,
    this.destination = '',
    required this.address,
    required this.distanceToPickup,
    required this.estimatedTime,
    required this.driverLatitude,
    required this.driverLongitude,
    required this.pickupLatitude,
    required this.pickupLongitude,
  }) : super(key: key);

  // Launch Google Maps for navigation
  void _launchGoogleMapsNavigation() async {
    if (pickupLatitude == 0 || pickupLongitude == 0) {
      return; // Don't launch if no valid coordinates
    }
    
    // Create the Google Maps URL
    final String googleMapsUrl = Platform.isIOS 
        ? 'comgooglemaps://?daddr=$pickupLatitude,$pickupLongitude&directionsmode=driving'
        : 'google.navigation:q=$pickupLatitude,$pickupLongitude&mode=d';
    
    // Fallback URL for web browser if the app isn't installed
    final String fallbackUrl = 
        'https://www.google.com/maps/dir/?api=1&destination=$pickupLatitude,$pickupLongitude&travelmode=driving';
    
    // Try to launch the Google Maps app first
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } 
    // If the app isn't installed, try the web version
    else if (await canLaunch(fallbackUrl)) {
      await launch(fallbackUrl);
    }
  }
  
  // Calculate real-time distance and ETA
  String _calculateCurrentDistance() {
    if (pickupLatitude == 0 || pickupLongitude == 0 || 
        driverLatitude == 0 || driverLongitude == 0) {
      return "Calculating...";
    }
    
    double distanceInMeters = Geolocator.distanceBetween(
      driverLatitude,
      driverLongitude,
      pickupLatitude,
      pickupLongitude,
    );
    
    // Convert to kilometers with 1 decimal place
    double distanceInKm = distanceInMeters / 1000;
    return "${distanceInKm.toStringAsFixed(1)} km";
  }
  
  // Calculate estimated arrival time based on current distance
  String _calculateEstimatedTime() {
    if (pickupLatitude == 0 || pickupLongitude == 0 || 
        driverLatitude == 0 || driverLongitude == 0) {
      return "Calculating...";
    }
    
    double distanceInMeters = Geolocator.distanceBetween(
      driverLatitude,
      driverLongitude,
      pickupLatitude,
      pickupLongitude,
    );
    
    // Convert to kilometers
    double distanceInKm = distanceInMeters / 1000;
    
    // Estimate time: assuming average speed of 40 km/h for ambulance in traffic
    double timeInHours = distanceInKm / 40;
    int timeInMinutes = (timeInHours * 60).round();
    
    return "$timeInMinutes min";
  }

  @override
  Widget build(BuildContext context) {
    // Get real-time calculated distance and ETA
    final currentDistance = distanceToPickup.isEmpty ? _calculateCurrentDistance() : distanceToPickup;
    final currentEta = estimatedTime.isEmpty ? _calculateEstimatedTime() : estimatedTime;
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Navigation header with Google Maps button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.navigation, color: Colors.black87),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Navigate to Patient',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _launchGoogleMapsNavigation(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Start',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Pickup location
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_pin_circle,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pickup Location',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        address,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Distance and ETA info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Distance indicator
                Column(
                  children: [
                    const Icon(Icons.directions_car, color: Colors.green),
                    const SizedBox(height: 4),
                    Text(
                      currentDistance,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      'Distance',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey.withOpacity(0.3),
                ),
                
                // ETA indicator
                Column(
                  children: [
                    const Icon(Icons.access_time, color: Colors.orange),
                    const SizedBox(height: 4),
                    Text(
                      currentEta,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      'ETA',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}