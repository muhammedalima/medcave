// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:medcave/Users/Mobilescreens/commonWidget/customnavbar.dart';
import 'package:medcave/Users/Mobilescreens/features/ambulance_tracking/presentation/pages/user/ambulance_status.dart';
import 'package:medcave/common/database/Ambulancerequest/ambulance_request_db.dart';
import 'package:medcave/common/geminifunction/geminifunction.dart';
import 'package:medcave/common/googlemapfunction/mappiker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class Ambulancescreenuser extends StatefulWidget {
  const Ambulancescreenuser({super.key});

  @override
  State<Ambulancescreenuser> createState() => _AmbulancescreenuserState();
}

class _AmbulancescreenuserState extends State<Ambulancescreenuser> {
  final TextEditingController _situationController = TextEditingController();
  final Geminifunction _gemini = Geminifunction();
  final AmbulanceRequestDatabase _requestDatabase = AmbulanceRequestDatabase(); // Add database instance
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isLoading = false;
  bool _isListening = false;
  String _selectedLocationType = '';
  LatLng? _selectedLocation;
  String _address = '';

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      // ignore: avoid_print
      onError: (error) => print('Error: $error'),
    );
    if (!available && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
    }
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _situationController.text =
                  '${_situationController.text} ${result.recognizedWords}';
              _situationController.selection = TextSelection.fromPosition(
                TextPosition(offset: _situationController.text.length),
              );
            });
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  void dispose() {
    _situationController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      final locationData = await LocationService.getCurrentLocation();
      setState(() {
        _selectedLocation = locationData['location'] as LatLng;
        _address = locationData['address'] as String;
        _selectedLocationType = 'current';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
        final address = await LocationService.getAddressFromLatLng(result);
        setState(() {
          _selectedLocation = result;
          _address = address;
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
      final analysis = await _gemini.analyzeEmergency(_situationController.text);
      
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
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
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
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: CustomAppBar(icon: Icons.arrow_back, onPressed: () => Navigator.pop(context),),
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
                    TextField(
                      controller: _situationController,
                      maxLines: 10,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Describe the emergency situation...",
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
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
                  backgroundColor: const Color(0xFFF1D25E),
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