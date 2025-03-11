import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:medcave/common/api/api.dart';

class Geminifunction {
  Geminifunction()
      : _model = GenerativeModel(
          model: 'gemini-1.5-flash-latest',
          apiKey: geminiApi,
        );

  final GenerativeModel _model;

  // Define valid values for strictly validated fields
  static const List<String> validSeverity = ['Critical', 'Moderate', 'Stable'];
  static const List<String> validConsciousness = [
    'Conscious',
    'Semi-conscious',
    'Unconscious'
  ];
  static const List<String> validBreathing = ['Normal', 'Labored', 'Absent'];

  // Define emergency categories
  static const Map<String, List<String>> emergencyCategories = {
    'Accident': ['accident', 'crash', 'collision', 'fall', 'injury'],
    'Pregnancy': ['pregnancy', 'labor', 'contractions', 'water broke'],
    'Cardiac': ['chest pain', 'heart attack', 'cardiac', 'palpitations'],
    'Respiratory': ['breathing', 'asthma', 'shortness of breath', 'choking'],
    'Trauma': ['bleeding', 'wound', 'fracture', 'burn'],
    'Neurological': ['stroke', 'seizure', 'unconscious', 'fainting'],
    'Medical': ['fever', 'allergic', 'poisoning', 'infection']
  };

  Future<Map<String, dynamic>> analyzeEmergency(String description) async {
    try {
      final analysis = await getEmergencyAnalysis(description);
      if (analysis == null) {
        return _getDefaultResponse(description);
      }

      final jsonData = jsonDecode(analysis);
      if (jsonData is! Map) {
        return _getDefaultResponse(description);
      }

      // Determine the primary emergency category
      String reason = _determineEmergencyCategory(description.toLowerCase());
      
      // Get a compact 2-word explanation for detailedReason if available, otherwise use the category
      String detailedReason = jsonData['reason']?.toString() ?? reason;
      if (detailedReason.split(' ').length > 2) {
        // Try to create a more concise version
        detailedReason = await getCompactDescription(detailedReason);
      }

      return {
        'reason': reason,
        'detailedReason': detailedReason,
        'customDescription': description, // Store the original user description
        'type': jsonData['type']?.toString() ?? 'Unknown',
        'severity':
            _validateField(jsonData['severity'], validSeverity, 'Stable'),
        'consciousness': _validateField(
            jsonData['consciousness'], validConsciousness, 'Conscious'),
        'breathing':
            _validateField(jsonData['breathing'], validBreathing, 'Normal'),
        'visibleInjuries': jsonData['visibleInjuries']?.toString() ?? 'None',
      };
    } on GenerativeAIException {
      return _getDefaultResponse(description);
    } catch (e) {
      if (e is GeminierrorException) rethrow;
      if (kDebugMode) {
        print('/////////////// ERROR EXCEPTION //////////////////');
      }
      return _getDefaultResponse(description);
    }
  }

  String _determineEmergencyCategory(String description) {
    for (var entry in emergencyCategories.entries) {
      for (var keyword in entry.value) {
        if (description.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return 'General Medical';
  }

  String _validateField(
      dynamic value, List<String> validValues, String defaultValue) {
    if (value != null && validValues.contains(value.toString())) {
      return value.toString();
    }
    return defaultValue;
  }

  Map<String, dynamic> _getDefaultResponse(String description) {
    final category = _determineEmergencyCategory(description.toLowerCase());
    return {
      'reason': category,
      'detailedReason': category,
      'customDescription': description, // Store the original user description
      'type': 'Unknown',
      'severity': 'Stable',
      'consciousness': 'Conscious',
      'breathing': 'Normal',
      'visibleInjuries': 'None'
    };
  }

  Future<String?> getEmergencyAnalysis(String description) async {
    final prompt = '''
You are an emergency medical analyst. Analyze the emergency description and determine:
1. Main reason for emergency request (REQUIRED - be specific and descriptive)
2. Type of emergency (Be specific about the medical condition or situation)
3. Severity level (Must be exactly: Critical, Moderate, or Stable)
4. Consciousness status (Must be exactly: Conscious, Semi-conscious, or Unconscious)
5. Breathing status (Must be exactly: Normal, Labored, or Absent)
6. Visible injuries (Be specific and descriptive about any injuries observed)

Provide your response as a JSON object with the following schema:
{"reason": "", "type": "", "severity": "", "consciousness": "", "breathing": "", "visibleInjuries": ""}

Only JSON object is needed.
The reason, type, and visibleInjuries can be descriptive.
Severity, consciousness, and breathing must use exact terms as specified.
Analyze this emergency: $description
''';

    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text;
  }
  
  // New method to create a compact 2-word description
  Future<String> getCompactDescription(String originalDescription) async {
    try {
      final prompt = '''
Given this emergency description: "$originalDescription"
Provide a concise 2-word label that best describes this medical emergency.
Only provide the 2 words, nothing else. For example: "Heart Attack", "Severe Bleeding", etc.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final compactDescription = response.text?.trim() ?? originalDescription;
      
      // If still more than 2 words or empty, use first 2 words of original or default
      final words = compactDescription.split(' ');
      if (words.length != 2 || compactDescription.isEmpty) {
        final originalWords = originalDescription.split(' ');
        if (originalWords.length >= 2) {
          return '${originalWords[0]} ${originalWords[1]}';
        } else if (originalWords.isNotEmpty) {
          return originalWords[0];
        } else {
          return 'Medical Emergency';
        }
      }
      
      return compactDescription;
    } catch (e) {
      // If any error occurs, use the first 2 words of the original description
      final words = originalDescription.split(' ');
      if (words.length >= 2) {
        return '${words[0]} ${words[1]}';
      } else if (words.isNotEmpty) {
        return words[0];
      } else {
        return 'Medical Emergency';
      }
    }
  }
}

class GeminierrorException implements Exception {
  const GeminierrorException([this.message = 'Unknown problem']);
  final String message;
  @override
  String toString() => 'GeminierrorException: $message';
}