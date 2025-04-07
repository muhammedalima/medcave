import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medcave/config/colors/appcolor.dart';
import 'package:medcave/common/googlemapfunction/location_update.dart'; // Import the location service

class AmbulanceSlider extends StatefulWidget {
  final Function(bool isActive) onSlideComplete;
  final String textInactive;
  final String textActive;
  final Color primaryColor;
  final Color secondaryColor;
  final String? driverId;
  final bool initialValue;

  const AmbulanceSlider({
    Key? key,
    required this.onSlideComplete,
    this.textInactive = 'Slide to take ride',
    this.textActive = 'Ready to take ride',
    this.primaryColor = AppColor.primaryGreen,
    this.secondaryColor = AppColor.darkBlack,
    this.driverId,
    this.initialValue = false,
  }) : super(key: key);

  @override
  State<AmbulanceSlider> createState() => _AmbulanceSliderState();
}

class _AmbulanceSliderState extends State<AmbulanceSlider> {
  double _position = 0;
  bool _isDragging = false;
  bool _isComplete = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _driverId;
  bool _isUpdatingFirebase = false;
  bool _listeningToFirebase = false;
  StreamSubscription<DocumentSnapshot>? _driverStatusSubscription;

  // Location service instance
  final DriverLocationService _locationService = DriverLocationService();

  @override
  void initState() {
    super.initState();
    _driverId = widget.driverId ?? FirebaseAuth.instance.currentUser?.uid ?? '';

    // Set initial state from widget parameter
    _isComplete = widget.initialValue;
    debugPrint('AmbulanceSlider initialized with isComplete: $_isComplete');

    // Set initial position based on value
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final screenWidth = MediaQuery.of(context).size.width;
        final sliderWidth = screenWidth;
        final buttonWidth = 80.0;
        _position = _isComplete ? sliderWidth - buttonWidth : 0;
        setState(() {}); // Ensure UI updates with correct position
      }
    });

    // Listen for changes in Firestore if we have a driver ID
    if (_driverId.isNotEmpty) {
      _setupFirebaseListener();
    }

    // Initialize location service
    _initializeLocationService();
  }

  // Initialize location service
  Future<void> _initializeLocationService() async {
    try {
      await _locationService.initialize();
    } catch (e) {
      debugPrint('Error initializing location service: $e');
    }
  }

  void _setupFirebaseListener() {
    if (_listeningToFirebase) return;

    _listeningToFirebase = true;
    _driverStatusSubscription = _firestore
        .collection('drivers')
        .doc(_driverId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || !mounted || _isUpdatingFirebase) return;

      final bool? isActive = snapshot.data()?['isDriverActive'] as bool?;
      debugPrint('Firestore listener received status: $isActive');

      if (isActive != null &&
          mounted &&
          !_isUpdatingFirebase &&
          isActive != _isComplete) {
        setState(() {
          _isComplete = isActive;
          // Update slider position based on status
          final screenWidth = MediaQuery.of(context).size.width;
          final sliderWidth = screenWidth;
          final buttonWidth = 80.0;
          _position = isActive ? sliderWidth - buttonWidth : 0;
        });

        // Notify parent of status change from Firebase
        widget.onSlideComplete(isActive);
      }
    }, onError: (error) {
      debugPrint('Error listening to driver status: $error');
    });
  }

  @override
  void dispose() {
    _driverStatusSubscription?.cancel();
    super.dispose();
  }

  // Rest of the existing methods remain the same...

  // Modify the _updateDriverStatus method to integrate location service
  Future<void> _updateDriverStatus(bool isActive) async {
    if (_driverId.isEmpty) {
      debugPrint('Error: Driver ID not available');
      return;
    }

    setState(() {
      _isUpdatingFirebase = true;
    });

    try {
      // Reference to the driver's document in Firestore
      final driverRef = _firestore.collection('drivers').doc(_driverId);

      // Update the isDriverActive field
      await driverRef.update({
        'isDriverActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
          'Driver status updated in Firestore: isDriverActive = $isActive');

      // Integrate with location service
      if (isActive) {
        // Start location updates when driver becomes active
        await _locationService.setDriverActiveStatus(true);

        // Force an immediate location update
        await _locationService.updateLocationNow();
      } else {
        // Stop location updates when driver becomes inactive
        await _locationService.setDriverActiveStatus(false);
      }

      // Notify parent of status change
      widget.onSlideComplete(isActive);
    } catch (e) {
      debugPrint('Error updating driver status: $e');
      // If there's an error, revert the UI
      if (mounted) {
        setState(() {
          _isComplete = !isActive;
          final screenWidth = MediaQuery.of(context).size.width;
          final sliderWidth = screenWidth;
          final buttonWidth = 80.0;
          _position = _isComplete ? sliderWidth - buttonWidth : 0;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingFirebase = false;
        });
      }
    }
  }

  // Modify _toggleSliderState to use the new _updateDriverStatus method
  void _toggleSliderState() {
    if (_isUpdatingFirebase) return;

    final bool newState = !_isComplete;
    setState(() {
      _isComplete = newState;
      final screenWidth = MediaQuery.of(context).size.width;
      final sliderWidth = screenWidth;
      final buttonWidth = 80.0;
      _position = newState ? sliderWidth - buttonWidth : 0;
    });

    // Update Firestore and location service
    _updateDriverStatus(newState).then((_) {
      widget.onSlideComplete(newState);
    });
  }

  // The rest of the build method and other methods remain the same as in the original code
  @override
  Widget build(BuildContext context) {
    // Existing build method code remains unchanged
    final screenWidth = MediaQuery.of(context).size.width;
    final sliderWidth = screenWidth - 16;
    final buttonWidth = 64.0;
    final sliderHeight = 60.0;
    final borderRadius = 16.0;

    return SizedBox(
      width: sliderWidth,
      height: sliderHeight,
      child: Stack(
        children: [
          // Background container with rounded rectangle shape
          Container(
            height: sliderHeight,
            width: sliderWidth,
            decoration: BoxDecoration(
              color: _isComplete ? widget.primaryColor : widget.secondaryColor,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Center(
              child: _isUpdatingFirebase
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _isComplete ? widget.textActive : widget.textInactive,
                      style: TextStyle(
                        color:
                            _isComplete ? widget.secondaryColor : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),

          // Draggable slider button with rounded rectangle shape
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            left: _isDragging
                ? _position
                : (_isComplete ? sliderWidth - buttonWidth : 0),
            top: 0,
            child: GestureDetector(
              onTap: _isUpdatingFirebase ? null : _toggleSliderState,
              onHorizontalDragStart: (details) {
                if (!_isUpdatingFirebase) {
                  setState(() {
                    _isDragging = true;
                  });
                }
              },
              onHorizontalDragUpdate: (details) {
                if (_isDragging && !_isUpdatingFirebase) {
                  setState(() {
                    _position += details.delta.dx;

                    // Clamp position
                    if (_position < 0) _position = 0;
                    if (_position > sliderWidth - buttonWidth)
                      _position = sliderWidth - buttonWidth;
                  });
                }
              },
              onHorizontalDragEnd: (details) {
                if (!_isUpdatingFirebase) {
                  // Calculate if slider should snap to end or beginning
                  final shouldComplete = _position > sliderWidth * 0.5;

                  setState(() {
                    _isDragging = false;
                    _isComplete = shouldComplete;

                    // Snap to position
                    _position = shouldComplete ? sliderWidth - buttonWidth : 0;
                  });

                  // Only update Firebase if the state changed
                  if (shouldComplete != widget.initialValue) {
                    _updateDriverStatus(shouldComplete).then((_) {
                      widget.onSlideComplete(shouldComplete);
                    });
                  }
                }
              },
              child: Container(
                width: buttonWidth,
                height: sliderHeight,
                decoration: BoxDecoration(
                  color:
                      _isComplete ? widget.secondaryColor : widget.primaryColor,
                  borderRadius: BorderRadius.circular(borderRadius),
                  // Add shadow for depth
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: _isUpdatingFirebase
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _isComplete ? Icons.arrow_back : Icons.arrow_forward,
                          color: _isComplete
                              ? Colors.white
                              : widget.secondaryColor,
                          size: 28, // Larger icon to match images
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
