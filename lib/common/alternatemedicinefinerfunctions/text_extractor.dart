import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MedicineTextExtractor {
  MedicineTextExtractor();

  // Text recognizer for image processing
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extract medicine name from an image
  ///
  /// [imagePath] The file path to the medicine image
  /// Returns a potential medicine name or null if not found
  Future<String?> extractMedicineNameFromImage(String imagePath) async {
    try {
      File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw MedicineExtractorException('Image file not found: $imagePath');
      }

      // Process the image using MLKit
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Extract potential medicine names from the recognized text
      final List<String> potentialMedicineNames =
          _extractMedicineNames(recognizedText.text);

      if (potentialMedicineNames.isEmpty) {
        return null;
      }

      // Return the first potential medicine name
      return potentialMedicineNames.first;
    } catch (e) {
      if (e is MedicineExtractorException) rethrow;
      if (kDebugMode) {
        print('Error extracting medicine name from image: $e');
      }
      return null;
    } finally {
      // Always close the text recognizer when done
      _textRecognizer.close();
    }
  }
  

  /// Extract potential medicine names from recognized text
  List<String> _extractMedicineNames(String text) {
    final List<String> potentialNames = [];

    // Split text into lines and words
    final lines = text.split('\n');

    for (String line in lines) {
      // Check if line likely contains a medicine name
      if (_isLikelyMedicineName(line)) {
        potentialNames.add(line.trim());
      }

      // Also add individual words that might be medicine names
      final words = line
          .split(' ')
          .where((word) => word.length > 3 && _isLikelyMedicineName(word))
          .toList();

      potentialNames.addAll(words);
    }

    return potentialNames;
  }

  /// Check if text is likely to be a medicine name
  bool _isLikelyMedicineName(String text) {
    // Remove common packaging text indicators
    final lowerText = text.toLowerCase();

    // Filter out common non-medicine text
    if (lowerText.contains('tablet') ||
        lowerText.contains('capsule') ||
        lowerText.contains('mg') ||
        lowerText.contains('ml') ||
        // Add more medicine-related keywords
        (text.length > 3 && text[0].toUpperCase() == text[0])) {
      // Filter out obvious non-medicine texts
      if (!lowerText.contains('expiry') &&
          !lowerText.contains('batch') &&
          !lowerText.contains('mfg') &&
          !lowerText.contains('store')) {
        return true;
      }
    }

    return false;
  }
}

class MedicineExtractorException implements Exception {
  const MedicineExtractorException([this.message = 'Unknown problem']);
  final String message;
  @override
  String toString() => 'MedicineExtractorException: $message';
}
