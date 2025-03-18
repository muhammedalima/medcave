import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:medcave/common/api/api.dart';

class AlternateMedicineFinder {
  AlternateMedicineFinder()
      : _model = GenerativeModel(
          model: 'gemini-1.5-flash-latest',
          apiKey: geminiApi,
        );

  final GenerativeModel _model;

  /// Find alternative medicines based on a medicine name
  ///
  /// [medicineName] The name of the medicine to find alternatives for
  /// Returns a Map with original medicine information and a list of alternatives
  Future<Map<String, dynamic>> findAlternativesByName(String medicineName) async {
    try {
      if (medicineName.trim().isEmpty) {
        throw MedicineFinderException('Medicine name cannot be empty');
      }

      // Get the analysis from Gemini
      final analysis = await _getAlternativeMedicines(medicineName: medicineName);
      if (analysis == null) {
        return _getDefaultResponse();
      }

      // Clean and parse the JSON
      final cleanJson = _cleanJsonResponse(analysis);
      Map<String, dynamic> parsedData;
      try {
        parsedData = jsonDecode(cleanJson);
      } catch (e) {
        if (kDebugMode) {
          print('Error decoding JSON: $e');
          print('Raw response: $analysis');
          print('Cleaned JSON: $cleanJson');
        }
        return _getDefaultResponse(medicineName: medicineName);
      }

      return {
        'originalMedicine': parsedData['originalMedicine'] ?? medicineName,
        'genericName': parsedData['genericName'] ?? 'Unknown',
        'description': parsedData['description'] ?? 'No description available',
        'alternatives': parsedData['alternatives'] ?? [],
      };
    } on GenerativeAIException catch (e) {
      if (kDebugMode) {
        print('Gemini API Exception: ${e.message}');
      }
      return _getDefaultResponse(medicineName: medicineName);
    } catch (e) {
      if (e is MedicineFinderException) rethrow;
      if (kDebugMode) {
        print('Error finding alternative medicines: $e');
      }
      return _getDefaultResponse(medicineName: medicineName);
    }
  }

  /// Find alternative medicines based on a medicine image
  ///
  /// [imagePath] The file path to the medicine image
  /// Returns a Map with original medicine information and a list of alternatives
  Future<Map<String, dynamic>> findAlternativesByImage(String imagePath) async {
    try {
      File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw MedicineFinderException('Image file not found: $imagePath');
      }

      final bytes = await imageFile.readAsBytes();

      // Get the analysis from Gemini
      final analysis = await _getAlternativeMedicines(imageBytes: bytes);
      if (analysis == null) {
        return _getDefaultResponse();
      }

      // Clean and parse the JSON
      final cleanJson = _cleanJsonResponse(analysis);
      Map<String, dynamic> parsedData;
      try {
        parsedData = jsonDecode(cleanJson);
      } catch (e) {
        if (kDebugMode) {
          print('Error decoding JSON: $e');
          print('Raw response: $analysis');
          print('Cleaned JSON: $cleanJson');
        }
        return _getDefaultResponse();
      }

      return {
        'originalMedicine': parsedData['originalMedicine'] ?? 'Unknown Medicine',
        'genericName': parsedData['genericName'] ?? 'Unknown',
        'description': parsedData['description'] ?? 'No description available',
        'alternatives': parsedData['alternatives'] ?? [],
      };
    } on GenerativeAIException catch (e) {
      if (kDebugMode) {
        print('Gemini API Exception: ${e.message}');
      }
      return _getDefaultResponse();
    } catch (e) {
      if (e is MedicineFinderException) rethrow;
      if (kDebugMode) {
        print('Error finding alternative medicines: $e');
      }
      return _getDefaultResponse();
    }
  }

  /// Clean the JSON response from Gemini
  String _cleanJsonResponse(String response) {
    // Remove markdown code block markers
    String cleaned = response.replaceAll('```json', '').replaceAll('```', '');
    
    // Trim whitespace
    cleaned = cleaned.trim();
    
    // Check if the response is properly formatted JSON
    if (!cleaned.startsWith('{')) {
      // Try to find the JSON object in the text
      final jsonStart = cleaned.indexOf('{');
      final jsonEnd = cleaned.lastIndexOf('}');
      
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        cleaned = cleaned.substring(jsonStart, jsonEnd + 1);
      }
    }
    
    return cleaned;
  }

  /// Get alternative medicines from Gemini API using either text or image
  Future<String?> _getAlternativeMedicines({String? medicineName, List<int>? imageBytes}) async {
    final prompt = '''
You are a pharmaceutical expert. ${medicineName != null ? 'Analyze the medicine name provided: "$medicineName"' : 'Analyze the medicine shown in this image'} and provide:

1. Original Medicine Name (REQUIRED - identify the specific medicine)
2. Generic Name (REQUIRED - the generic or scientific name of the medicine)
3. Description (REQUIRED - a brief, clear description of what the medicine is used for, its class, and key information)
4. Alternatives (REQUIRED - a list of at least 5 alternative medicines that have the same Generic Name, including name)

Provide your response as a JSON object with the following schema:
{
  "originalMedicine": "",
  "genericName": "",
  "description": "",
  "alternatives": [
    {
      "name": "",
      "linktobuy": ""
    }
  ]
}

Only the JSON object is needed in your response.
For each alternative medicine, include its brand name and link to buy the medicine.
Ensure all alternatives are valid substitutes with similar therapeutic effects.
If you cannot identify the medicine with confidence, indicate this in your response.
''';

    List<Content> content = [];
    
    if (medicineName != null) {
      // Text-based query
      content = [Content.text(prompt)];
    } else if (imageBytes != null) {
      // Image-based query
      final base64Image = base64Encode(imageBytes);
      content = [
        Content.text(prompt),
        Content.text("data:image/jpeg;base64,$base64Image")
      ];
    } else {
      throw MedicineFinderException('Either medicine name or image must be provided');
    }

    // Make the API call
    final response = await _model.generateContent(content);
    return response.text;
  }

  /// Get default response when parsing fails
  Map<String, dynamic> _getDefaultResponse({String? medicineName}) {
    return {
      'originalMedicine': medicineName ?? 'Unknown Medicine',
      'genericName': 'Unable to identify',
      'description': 'Could not retrieve information for this medicine.',
      'alternatives': []
    };
  }
}

class MedicineFinderException implements Exception {
  const MedicineFinderException([this.message = 'Unknown problem']);
  final String message;
  @override
  String toString() => 'MedicineFinderException: $message';
}