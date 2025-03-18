import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:medcave/common/api/api.dart';

class MedicalRecordParser {
  MedicalRecordParser()
      : _model = GenerativeModel(
          model: 'gemini-1.5-flash-latest',
          apiKey: geminiApi,
        );

  final GenerativeModel _model;

  /// Parse a medical record image to extract heading, date, and description
  ///
  /// [imagePath] The file path to the medical record image
  /// Returns a Map with heading, date, and description keys
  Future<Map<String, dynamic>> parseMedicalRecord(String imagePath) async {
    try {
      File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw GeminierrorException('Image file not found: $imagePath');
      }

      final bytes = await imageFile.readAsBytes();

      // Get the analysis from Gemini
      final analysis = await _extractMedicalRecordDetails(bytes);
      if (analysis == null) {
        return _getDefaultResponse();
      }

      Map<String, dynamic> parsedData;
      try {
        parsedData = jsonDecode(analysis);
      } catch (e) {
        return _getDefaultResponse();
      }

      // Process date if available
      String date = parsedData['date']?.toString() ?? '';
      if (date.isEmpty) {
        // Use current date if no date found
        date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      } else {
        // Attempt to standardize the date format if a date was extracted
        date = _standardizeDate(date);
      }

      return {
        'heading': parsedData['heading']?.toString() ?? 'Medical Record',
        'date': date,
        'description': parsedData['description']?.toString() ?? '',
      };
    } on GenerativeAIException catch (e) {
      if (kDebugMode) {
        print('Gemini API Exception: ${e.message}');
      }
      return _getDefaultResponse();
    } catch (e) {
      if (e is GeminierrorException) rethrow;
      if (kDebugMode) {
        print('Error parsing medical record: $e');
      }
      return _getDefaultResponse();
    }
  }

  /// Standardize date format to yyyy-MM-dd
  String _standardizeDate(String dateStr) {
    try {
      // Common date formats to try
      final formats = [
        'yyyy-MM-dd',
        'dd/MM/yyyy',
        'MM/dd/yyyy',
        'dd-MM-yyyy',
        'MM-dd-yyyy',
        'd MMM yyyy',
        'MMM d, yyyy',
        'MMMM d, yyyy',
        'd MMMM yyyy',
      ];

      for (var format in formats) {
        try {
          final date = DateFormat(format).parse(dateStr);
          return DateFormat('yyyy-MM-dd').format(date);
        } catch (_) {
          // Try next format
        }
      }

      // If no format works, return the original string
      return dateStr;
    } catch (_) {
      // If any error occurs, return current date
      return DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
  }

  /// Extract medical record details from image bytes using Gemini
  Future<String?> _extractMedicalRecordDetails(List<int> imageBytes) async {
    final prompt = '''
You are a medical document analyst. Analyze the medical document image and extract:

1. Heading (REQUIRED - the title or type of the document, e.g., "Prescription", "Lab Report", "Diagnostic Test")
2. Date (REQUIRED - the date mentioned in the document in format YYYY-MM-DD if possible)
3. Description (REQUIRED - a detailed summary of the document content, including medications, dosages, test results, diagnoses, etc.)

Provide your response as a JSON object with the following schema:
{"heading": "", "date": "", "description": ""}

Only the JSON object is needed in your response.
If the date is not found, leave the date field empty.
If multiple dates are found, use the most recent one that appears to be the document date.
''';

    // Convert image bytes to base64
    final base64Image = base64Encode(imageBytes);

    // Create content for the request with text and image
    final content = [
      Content.text(prompt),
      Content.text("data:image/jpeg;base64,$base64Image")
    ];

    // Make the API call
    final response = await _model.generateContent(content);
    return response.text;
  }

  /// Get default response when parsing fails
  Map<String, dynamic> _getDefaultResponse() {
    return {
      'heading': 'Medical Record',
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'description': 'Unable to extract details from the medical document.'
    };
  }
}

class GeminierrorException implements Exception {
  const GeminierrorException([this.message = 'Unknown problem']);
  final String message;
  @override
  String toString() => 'GeminierrorException: $message';
}
