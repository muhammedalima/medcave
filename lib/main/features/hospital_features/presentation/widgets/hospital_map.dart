// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:medcave/main/commonWidget/customnavbar.dart';
// import 'package:medcave/main/features/hospital_features/model/hospitaldata.dart';
// import 'package:medcave/config/colors/appcolor.dart';
// import 'package:medcave/config/fonts/font.dart';
// import 'dart:async';

// class HospitalMapSearch extends StatefulWidget {
//   const HospitalMapSearch({Key? key}) : super(key: key);

//   @override
//   State<HospitalMapSearch> createState() => _HospitalMapSearchState();
// }

// class _HospitalMapSearchState extends State<HospitalMapSearch> {
//   // Controller for the Google Map
//   final Completer<GoogleMapController> _mapController = Completer();

//   // Default camera position (centered on Mangaluru)
//   static const CameraPosition _defaultPosition = CameraPosition(
//     target: LatLng(12.9141, 74.8560), // Mangaluru coordinates
//     zoom: 12.0,
//   );

//   // Current user position
//   LatLng? _currentPosition;

//   // Collection of markers for hospitals
//   Set<Marker> _markers = {};

//   // Selected hospital info
//   Map<String, dynamic>? _selectedHospital;

//   // Loading state
//   bool _isLoading = true;

//   // Search query
//   String _searchQuery = '';

//   // Search results
//   List<Map<String, dynamic>> _searchResults = [];

//   // Filter options
//   double _radiusKm = 10.0; // Default radius in kilometers

//   @override
//   void initState() {
//     super.initState();
//     _getCurrentLocation();
//   }

//   // Get current user location
//   Future<void> _getCurrentLocation() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // Check location permissions
//       final LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         final LocationPermission requestPermission =
//             await Geolocator.requestPermission();
//         if (requestPermission == LocationPermission.denied) {
//           // Show message that we couldn't get location
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Location permission denied')),
//           );
//           _loadMapWithDefaultPosition();
//           return;
//         }
//       }

//       // Get current position
//       final Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );

//       setState(() {
//         _currentPosition = LatLng(position.latitude, position.longitude);
//         _isLoading = false;
//       });

//       // Move camera to current position
//       _moveCamera(_currentPosition!);

//       // Load hospital markers
//       _loadHospitalMarkers();
//     } catch (e) {
//       // If we can't get location, use default position
//       _loadMapWithDefaultPosition();
//     }
//   }

//   // Load map with default position if we can't get user location
//   void _loadMapWithDefaultPosition() {
//     setState(() {
//       _isLoading = false;
//     });
//     _loadHospitalMarkers();
//   }

//   // Move camera to specific position
//   Future<void> _moveCamera(LatLng position) async {
//     final GoogleMapController controller = await _mapController.future;
//     controller.animateCamera(CameraUpdate.newCameraPosition(
//       CameraPosition(
//         target: position,
//         zoom: 14.0,
//       ),
//     ));
//   }

//   // Load markers for all hospitals
//   void _loadHospitalMarkers() {
//     Set<Marker> markers = {};

//     for (var hospital in HospitalData.hospitals) {
//       final LatLng position = LatLng(
//           hospital['coordinates']['latitude'] as double,
//           hospital['coordinates']['longitude'] as double);

//       markers.add(
//         Marker(
//           markerId: MarkerId(hospital['id']),
//           position: position,
//           infoWindow: InfoWindow(
//             title: hospital['name'],
//             snippet: hospital['location'],
//           ),
//           onTap: () {
//             _onMarkerTapped(hospital);
//           },
//         ),
//       );
//     }

//     // Add current location marker if available
//     if (_currentPosition != null) {
//       markers.add(
//         Marker(
//           markerId: const MarkerId('currentLocation'),
//           position: _currentPosition!,
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
//           infoWindow: const InfoWindow(
//             title: 'Your Location',
//           ),
//         ),
//       );
//     }

//     setState(() {
//       _markers = markers;
//     });
//   }

//   // Handle marker tap
//   void _onMarkerTapped(Map<String, dynamic> hospital) {
//     setState(() {
//       _selectedHospital = hospital;
//     });
//   }

//   // Handle search
//   void _handleSearch(String query) {
//     setState(() {
//       _searchQuery = query;
//       _searchResults = HospitalData.searchHospitals(query);
//     });
//   }

//   // Select hospital from search
//   void _selectHospitalFromSearch(Map<String, dynamic> hospital) {
//     // Clear search
//     setState(() {
//       _searchQuery = '';
//       _searchResults = [];
//       _selectedHospital = hospital;
//     });

//     // Move camera to hospital
//     final LatLng position = LatLng(
//         hospital['coordinates']['latitude'] as double,
//         hospital['coordinates']['longitude'] as double);
//     _moveCamera(position);
//   }

//   // Navigate back with selected hospital
//   void _navigateToHospital() async {
//     if (_selectedHospital != null) {
//       // Save selected hospital ID to SharedPreferences
//       await HospitalData.saveSelectedHospitalId(_selectedHospital!['id']);

//       Navigator.pop(context, {
//         'hospitalId': _selectedHospital!['id'],
//         'hospitalData': _selectedHospital,
//       });
//     }
//   }

//   // Filter hospitals by radius
//   void _filterHospitalsByRadius() {
//     if (_currentPosition == null) return;

//     List<Map<String, dynamic>> nearby = HospitalData.getHospitalsNearby(
//         _currentPosition!.latitude, _currentPosition!.longitude, _radiusKm);

//     Set<Marker> markers = {};

//     // Add markers for nearby hospitals
//     for (var hospital in nearby) {
//       final LatLng position = LatLng(
//           hospital['coordinates']['latitude'] as double,
//           hospital['coordinates']['longitude'] as double);

//       markers.add(
//         Marker(
//           markerId: MarkerId(hospital['id']),
//           position: position,
//           infoWindow: InfoWindow(
//             title: hospital['name'],
//             snippet: hospital['location'],
//           ),
//           onTap: () {
//             _onMarkerTapped(hospital);
//           },
//         ),
//       );
//     }

//     // Add current location marker
//     markers.add(
//       Marker(
//         markerId: const MarkerId('currentLocation'),
//         position: _currentPosition!,
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
//         infoWindow: const InfoWindow(
//           title: 'Your Location',
//         ),
//       ),
//     );

//     setState(() {
//       _markers = markers;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CustomAppBar(
//         onPressed: () => Navigator.pop(context),
//         customTitle: 'Choose From Map',
//       ),
//       body: Stack(
//         children: [
//           // Google Map
//           GoogleMap(
//             initialCameraPosition: _defaultPosition,
//             mapType: MapType.normal,
//             myLocationEnabled: true,
//             myLocationButtonEnabled: false,
//             zoomControlsEnabled: false,
//             markers: _markers,
//             onMapCreated: (GoogleMapController controller) {
//               _mapController.complete(controller);
//             },
//           ),

//           // Loading indicator
//           if (_isLoading)
//             const Center(
//               child: CircularProgressIndicator(),
//             ),

//           // Search bar
//           Positioned(
//             top: 16,
//             left: 16,
//             right: 16,
//             child: Container(
//               height: 50,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.3),
//                     spreadRadius: 1,
//                     blurRadius: 3,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: TextField(
//                 decoration: const InputDecoration(
//                   hintText: 'Search hospitals',
//                   prefixIcon: Icon(Icons.search),
//                   border: InputBorder.none,
//                   contentPadding:
//                       EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                 ),
//                 onChanged: _handleSearch,
//               ),
//             ),
//           ),

//           // Search results
//           if (_searchResults.isNotEmpty)
//             Positioned(
//               top: 74,
//               left: 16,
//               right: 16,
//               child: Container(
//                 constraints: const BoxConstraints(maxHeight: 300),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(8),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.grey.withOpacity(0.3),
//                       spreadRadius: 1,
//                       blurRadius: 3,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: ListView.builder(
//                   shrinkWrap: true,
//                   itemCount: _searchResults.length,
//                   itemBuilder: (context, index) {
//                     final hospital = _searchResults[index];
//                     return ListTile(
//                       title: Text(hospital['name']),
//                       subtitle: Text(hospital['location']),
//                       onTap: () => _selectHospitalFromSearch(hospital),
//                     );
//                   },
//                 ),
//               ),
//             ),

//           // Radius filter
//           Positioned(
//             bottom: 180,
//             right: 16,
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.3),
//                     spreadRadius: 1,
//                     blurRadius: 3,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               padding: const EdgeInsets.all(8),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   const Text(
//                     'Radius (km)',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   Slider(
//                     value: _radiusKm,
//                     min: 1.0,
//                     max: 5000.0,
//                     divisions: 29,
//                     label: _radiusKm.round().toString(),
//                     onChanged: (value) {
//                       setState(() {
//                         _radiusKm = value;
//                       });
//                     },
//                     onChangeEnd: (value) {
//                       _filterHospitalsByRadius();
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // My location button
//           Positioned(
//             bottom: 120,
//             right: 16,
//             child: FloatingActionButton(
//               heroTag: 'locationButton',
//               backgroundColor: Colors.white,
//               foregroundColor: AppColor.primaryGreen,
//               mini: true,
//               onPressed: () {
//                 if (_currentPosition != null) {
//                   _moveCamera(_currentPosition!);
//                 } else {
//                   _getCurrentLocation();
//                 }
//               },
//               child: const Icon(Icons.my_location),
//             ),
//           ),

//           // Selected hospital info card
//           if (_selectedHospital != null)
//             Positioned(
//               bottom: 16,
//               left: 16,
//               right: 16,
//               child: Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.grey.withOpacity(0.3),
//                       spreadRadius: 2,
//                       blurRadius: 5,
//                       offset: const Offset(0, 3),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Row(
//                       children: [
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(8),
//                           child: Image.asset(
//                             'assets/hospitalsimages/1.png',
//                             width: 80,
//                             height: 80,
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 _selectedHospital!['name'],
//                                 style: FontStyles.heading,
//                               ),
//                               Text(
//                                 _selectedHospital!['location'],
//                                 style: FontStyles.bodyBase,
//                               ),
//                               Row(
//                                 children: [
//                                   const Icon(
//                                     Icons.star,
//                                     color: Colors.amber,
//                                     size: 16,
//                                   ),
//                                   const SizedBox(width: 4),
//                                   Text(
//                                     _selectedHospital!['rating'].toString(),
//                                     style: FontStyles.bodySmall,
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     Wrap(
//                       spacing: 8,
//                       children:
//                           (_selectedHospital!['specialties'] as List<dynamic>)
//                               .map((specialty) => Chip(
//                                     label: Text(
//                                       specialty,
//                                       style: FontStyles.bodySmall,
//                                     ),
//                                     backgroundColor: AppColor.backgroundWhite,
//                                   ))
//                               .toList(),
//                     ),
//                     const SizedBox(height: 16),
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: _navigateToHospital,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppColor.primaryGreen,
//                           foregroundColor: Colors.white,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                         ),
//                         child: const Text('Select Hospital'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
