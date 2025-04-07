// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:medcave/main/commonWidget/customnavbar.dart';
import 'package:medcave/main/features/ambulance_tracking/presentation/pages/user/ambulance_status.dart';
import 'package:medcave/common/database/model/Ambulancerequest/ambulance_request_db.dart';
import 'package:medcave/common/geminifunction/geminifunction.dart';
import 'package:medcave/common/googlemapfunction/mappiker.dart';
import 'package:medcave/config/colors/appcolor.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';

class Ambulancescreenuser extends StatefulWidget {
  const Ambulancescreenuser({super.key});

  @override
  State<Ambulancescreenuser> createState() => _AmbulancescreenuserState();
}

class _AmbulancescreenuserState extends State<Ambulancescreenuser> {
  final TextEditingController _situationController = TextEditingController();
  final Geminifunction _gemini = Geminifunction();
  final AmbulanceRequestDatabase _requestDatabase = AmbulanceRequestDatabase();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isLoading = false;
  bool _isCurrentLocationLoading = false;
  bool _isListening = false;
  String _selectedLocationType = '';
  LatLng? _selectedLocation;
  String _address = '';

  // Speech recognition variables
  String _lastRecognizedText = '';
  String _currentPartialText = '';
  bool _showSpeechHint = false;
  bool _isInitialized = false;
  Timer? _restartTimer;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: _handleSpeechStatus,
        onError: _handleSpeechError,
        debugLogging: kDebugMode,
      );

      _isInitialized = available;

      if (!available && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Speech recognition not available on this device')),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Speech initialization error: $e');
      }
      _isInitialized = false;
    }
  }

  // Handle speech status changes
  void _handleSpeechStatus(String status) {
    if (kDebugMode) {
      print('Speech status: $status');
    }

    // When speech service stops for any reason but we want to keep listening
    if ((status == 'done' || status == 'notListening') &&
        _isListening &&
        mounted) {
      _restartTimer?.cancel();

      // Restart listening after a short delay
      _restartTimer = Timer(const Duration(milliseconds: 300), () {
        if (_isListening && mounted) {
          if (kDebugMode) {
            print('Automatically restarting speech recognition');
          }
          _startListeningSession();
        }
      });
    }
  }

  // Handle speech recognition errors
  void _handleSpeechError(dynamic error) {
    if (kDebugMode) {
      print('Speech recognition error: $error');
    }

    if (mounted) {
      setState(() {
        _showSpeechHint = true;
      });

      // Hide the hint after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _showSpeechHint = false);
        }
      });
    }

    // If we're supposed to be listening, try to restart
    if (_isListening && mounted) {
      _restartTimer?.cancel();
      _restartTimer = Timer(const Duration(seconds: 1), () {
        if (_isListening && mounted) {
          _startListeningSession();
        }
      });
    }
  }

  // Start a new listening session
  Future<void> _startListeningSession() async {
    if (!_isInitialized) {
      // Try to initialize again if it wasn't successful
      await _initializeSpeech();
      if (!_isInitialized) return;
    }

    try {
      await _speech.listen(
        onResult: _handleSpeechResult,
        listenFor: const Duration(seconds: 600), // Increased to 10 minutes
        pauseFor: const Duration(seconds: 60), // Very long pause tolerance
        partialResults: true,
        cancelOnError: false, // Don't cancel on error
        listenMode: stt
            .ListenMode.dictation, // Using dictation mode for continuous speech
      );

      if (kDebugMode) {
        print('Started listening session');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error starting speech recognition: $e');
      }

      // If there's an error, wait a bit and try again
      if (_isListening && mounted) {
        _restartTimer?.cancel();
        _restartTimer = Timer(const Duration(seconds: 1), () {
          if (_isListening && mounted) {
            _startListeningSession();
          }
        });
      }
    }
  }

  // Handle speech recognition results
  void _handleSpeechResult(dynamic result) {
    if (!mounted) return;

    if (result.finalResult) {
      // Process final result
      if (result.recognizedWords.isNotEmpty) {
        String cleanedText = result.recognizedWords.trim();

        // Only add text if it's not a duplicate
        if (!_isDuplicateText(cleanedText)) {
          setState(() {
            // Add space if needed
            if (_situationController.text.isNotEmpty &&
                !_situationController.text.endsWith(' ')) {
              _situationController.text += ' ';
            }

            _situationController.text += cleanedText;

            // Update cursor position
            _situationController.selection = TextSelection.fromPosition(
              TextPosition(offset: _situationController.text.length),
            );

            _lastRecognizedText = cleanedText;
            _currentPartialText = '';
          });
        }
      }
    } else if (result.recognizedWords.isNotEmpty) {
      // Show partial results in real-time
      setState(() {
        _currentPartialText = result.recognizedWords;
      });
    }
  }

  // Check if text is too similar to previous text
  bool _isDuplicateText(String text) {
    if (_lastRecognizedText.isEmpty) return false;

    // Simple duplicate check
    if (text.toLowerCase() == _lastRecognizedText.toLowerCase()) return true;

    // Check for near-duplicates by similarity
    final String lastLower = _lastRecognizedText.toLowerCase();
    final String currentLower = text.toLowerCase();

    // Check if one is contained in the other
    if (lastLower.contains(currentLower) || currentLower.contains(lastLower)) {
      return true;
    }

    return false;
  }

  // Toggle listening state
  Future<void> _toggleListening() async {
    if (!_isListening) {
      // Start listening
      setState(() {
        _isListening = true;
        _showSpeechHint = true;
        _currentPartialText = '';
      });

      // Hide the hint after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _showSpeechHint = false);
        }
      });

      // Start the listening session
      await _startListeningSession();
    } else {
      // Stop listening
      _restartTimer?.cancel();
      await _speech.stop();

      setState(() {
        _isListening = false;
        _showSpeechHint = false;
        _currentPartialText = '';
      });
    }
  }

  @override
  void dispose() {
    _situationController.dispose();
    _speech.stop();
    _restartTimer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isCurrentLocationLoading = true);

    try {
      final locationData = await LocationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _selectedLocation = locationData['location'] as LatLng;

          // Check if the address is in the format like "MJ35+P8X"
          final String rawAddress = locationData['address'] as String;
          if (rawAddress.contains('+') && rawAddress.length < 10) {
            // This looks like a plus code, use a generic name instead
            _address = "Selected Location";
          } else {
            _address = rawAddress;
          }

          _selectedLocationType = 'current';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCurrentLocationLoading = false);
      }
    }
  }

  Future<void> _openLocationPicker() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPicker(initialLocation: _selectedLocation),
      ),
    );

    if (result != null) {
      try {
        final rawAddress = await LocationService.getAddressFromLatLng(result);

        // Process the address
        String processedAddress = rawAddress;

        // Check if the address is in the format like "MJ35+P8X"
        if (rawAddress.contains('+') && rawAddress.length < 10) {
          // This looks like a plus code, use a generic name instead
          processedAddress = "Selected Location";
        }

        setState(() {
          _selectedLocation = result;
          _address = processedAddress;
          _selectedLocationType = 'choose';
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error getting address: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _analyzeAndProceed() async {
    if (_situationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the situation')),
      );
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Analyze emergency using Gemini
      final analysis =
          await _gemini.analyzeEmergency(_situationController.text);

      // Add the user's description to the emergency data
      analysis['customDescription'] = _situationController.text.trim();

      // Prepare location data
      final locationData = {
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'address': _address,
        'locationType': _selectedLocationType,
      };

      // Create ambulance request in Firebase
      final requestId = await _requestDatabase.createAmbulanceRequest(
        emergencyData: analysis,
        locationData: locationData,
      );

      if (!mounted) return;

      // Navigate to the AmbulanceStatusPage with the request ID
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AmbulanceStatusPage(requestId: requestId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _locationButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.black : Colors.grey.shade300,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    strokeWidth: 2,
                  ),
                )
              else
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.black,
                  size: 24,
                ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        icon: Icons.arrow_back,
        onPressed: () => Navigator.pop(context),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Select the location",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _locationButton(
                    title: 'Current Location',
                    icon: Icons.my_location,
                    isSelected: _selectedLocationType == 'current',
                    onTap: _getCurrentLocation,
                    isLoading: _isCurrentLocationLoading,
                  ),
                  _locationButton(
                    title: 'Choose Location',
                    icon: Icons.map,
                    isSelected: _selectedLocationType == 'choose',
                    onTap: _openLocationPicker,
                  ),
                ],
              ),
              if (_address.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.black),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _address,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 30),
              const Text(
                "Share the Situation?",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Include conditions, injuries, and visible damage...",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _situationController,
                            maxLines: null,
                            expands: true,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "Describe the emergency situation...",
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        if (_isListening) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _currentPartialText.isNotEmpty
                                        ? "Listening: $_currentPartialText"
                                        : "Listening...",
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_showSpeechHint) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "Speak clearly and use short phrases for better recognition",
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: GestureDetector(
                        onTap: _toggleListening,
                        child: Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: _isListening ? Colors.red : Colors.black,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            _isListening ? Icons.stop : Icons.mic,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _analyzeAndProceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      )
                    : const Text(
                        "SEARCH AMBULANCE",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
