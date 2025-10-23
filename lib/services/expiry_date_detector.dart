import 'dart:async';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

class ExpiryDateDetector {
  final TextRecognizer _textRecognizer;

  ExpiryDateDetector() : _textRecognizer = TextRecognizer();

  Future<String?> detectExpiryDateFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      return _extractExpiryDate(recognizedText.text);
    } catch (e) {
      print('Error processing image: $e');
      return null;
    }
  }

  // Simplified version that doesn't use CameraImage directly
  // We'll use takePicture() instead which gives us a file path
  Future<String?> detectExpiryDateFromCamera(CameraController controller) async {
    try {
      // Take a picture and get the file
      final image = await controller.takePicture();
      return await detectExpiryDateFromImage(image.path);
    } catch (e) {
      print('Error processing camera image: $e');
      return null;
    }
  }

  String? _extractExpiryDate(String text) {
    print("OCR Text detected: $text");
    
    // Common expiry date patterns
    final patterns = [
      // MM/DD/YYYY or MM-DD-YYYY
      RegExp(r'\b(0[1-9]|1[0-2])[/-](0[1-9]|[12][0-9]|3[01])[/-](20\d{2})\b'),
      // DD/MM/YYYY or DD-MM-YYYY
      RegExp(r'\b(0[1-9]|[12][0-9]|3[01])[/-](0[1-9]|1[0-2])[/-](20\d{2})\b'),
      // YYYY/MM/DD or YYYY-MM-DD
      RegExp(r'\b(20\d{2})[/-](0[1-9]|1[0-2])[/-](0[1-9]|[12][0-9]|3[01])\b'),
      // Month DD, YYYY (e.g., "Dec 25, 2024")
      RegExp(r'\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{1,2}),?\s+(20\d{2})\b', caseSensitive: false),
      // DD Month YYYY (e.g., "25 Dec 2024")
      RegExp(r'\b(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(20\d{2})\b', caseSensitive: false),
      // Simple year-month (e.g., "2024-12")
      RegExp(r'\b(20\d{2})[/-](0[1-9]|1[0-2])\b'),
    ];

    // Split text into lines for better processing
    final lines = text.split('\n');
    
    // First, look for lines with expiry-related keywords
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      
      // Check for expiry keywords
      if (lowerLine.contains('exp') || 
          lowerLine.contains('expiry') ||
          lowerLine.contains('use by') ||
          lowerLine.contains('best before') ||
          lowerLine.contains('use before') ||
          lowerLine.contains('sell by')) {
        
        print("Found expiry keyword in line: $line");
        
        // Try to extract date from this line
        for (final pattern in patterns) {
          final matches = pattern.allMatches(line);
          for (final match in matches) {
            final potentialDate = match.group(0);
            if (potentialDate != null && _isValidDate(potentialDate)) {
              print("Found expiry date: $potentialDate");
              return potentialDate;
            }
          }
        }
      }
    }
    
    // If no expiry keywords found, look for any date patterns in the entire text
    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final potentialDate = match.group(0);
        if (potentialDate != null && _isValidDate(potentialDate)) {
          print("Found general date: $potentialDate");
          return potentialDate;
        }
      }
    }

    print("No valid expiry date found");
    return null;
  }

  bool _isValidDate(String date) {
    try {
      final now = DateTime.now();
      final parsedDate = _parseDate(date);
      if (parsedDate == null) return false;
      
      // Allow dates from 2020 onwards and up to 10 years in future
      return parsedDate.isAfter(DateTime(2020)) && 
             parsedDate.isBefore(now.add(const Duration(days: 3650)));
    } catch (e) {
      return false;
    }
  }

  DateTime? _parseDate(String dateString) {
    try {
      // Remove common prefixes/suffixes
      String cleanDate = dateString.replaceAll(RegExp(r'^(exp|expiry|use by|best before)[:\s]*', caseSensitive: false), '');
      cleanDate = cleanDate.trim();
      
      // Try different date formats
      final formats = [
        RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})'),
        RegExp(r'(\d{4})[/-](\d{1,2})[/-](\d{1,2})'),
        RegExp(r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{4})', caseSensitive: false),
        RegExp(r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{1,2}),?\s+(\d{4})', caseSensitive: false),
      ];

      for (final format in formats) {
        final match = format.firstMatch(cleanDate);
        if (match != null) {
          if (format.pattern.contains('[a-z]')) {
            // Month name format
            final monthNames = {
              'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
              'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
            };
            final monthStr = match.group(2) ?? match.group(1);
            final dayStr = match.group(1) ?? match.group(2);
            final yearStr = match.group(3);
            
            if (monthStr != null && dayStr != null && yearStr != null) {
              final month = monthNames[monthStr.toLowerCase().substring(0, 3)];
              if (month != null) {
                return DateTime(int.parse(yearStr), month, int.parse(dayStr));
              }
            }
          } else {
            // Numeric format
            final parts = match.groups([1, 2, 3]);
            if (parts.every((part) => part != null)) {
              final first = int.parse(parts[0]!);
              final second = int.parse(parts[1]!);
              final year = int.parse(parts[2]!);
              
              // Heuristic: if first part > 12, it's probably DD/MM/YYYY
              if (first > 12) {
                return DateTime(year, second, first); // DD/MM/YYYY
              } else {
                return DateTime(year, first, second); // MM/DD/YYYY
              }
            }
          }
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}