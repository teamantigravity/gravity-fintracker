import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class ReceiptScannerService {
  static TextRecognizer? _recognizer;

  static TextRecognizer get _recognizerInstance {
    _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _recognizer!;
  }

  static bool get isSupported {
    return !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
  }

  static Future<ReceiptScanResult> scanFromCamera() async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1200, maxHeight: 1600);
    if (image == null) return ReceiptScanResult.empty();
    return _process(image);
  }

  static Future<ReceiptScanResult> scanFromGallery() async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, maxHeight: 1600);
    if (image == null) return ReceiptScanResult.empty();
    return _process(image);
  }

  static Future<ReceiptScanResult> _process(XFile image) async {
    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final recognized = await _recognizerInstance.processImage(inputImage);
      final text = recognized.text;
      final lines = recognized.blocks
          .expand((b) => b.lines)
          .map((l) => l.text)
          .where((t) => t.trim().isNotEmpty)
          .toList();
      return _parse(text, lines, image.path);
    } catch (e) {
      return ReceiptScanResult.error('OCR failed: $e');
    }
  }

  static ReceiptScanResult _parse(String rawText, List<String> lines, String imagePath) {
    final amounts = <double>[];
    DateTime? date;
    String? merchant;

    for (final line in lines) {
      final clean = line.trim();
      if (clean.isEmpty) continue;

      if (merchant == null && !RegExp(r'\d').hasMatch(clean)) {
        merchant = clean;
      }

      final dateMatch = _extractDate(clean);
      if (date == null && dateMatch != null) date = dateMatch;

      final amount = _extractAmount(clean);
      if (amount != null) amounts.add(amount);
    }

    double total = 0;
    if (amounts.isNotEmpty) {
      amounts.sort();
      total = amounts.last;
    }

    return ReceiptScanResult(
      merchant: merchant ?? 'Merchant',
      total: total,
      date: date ?? DateTime.now(),
      rawText: rawText,
      imagePath: imagePath,
    );
  }

  static DateTime? _extractDate(String line) {
    final patterns = [
      RegExp(r'(\d{4})[\/\-.](\d{1,2})[\/\-.](\d{1,2})'),
      RegExp(r'(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{2,4})'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(line);
      if (m != null) {
        try {
          final parts = m.group(0)!.split(RegExp(r'[\/\-.]'));
          if (parts.length == 3) {
            final a = int.parse(parts[0]);
            final b = int.parse(parts[1]);
            final c = int.parse(parts[2]);
            if (a > 1000) {
              // ISO-like: yyyy-mm-dd
              return DateTime(a, b, c);
            } else if (c > 1000) {
              // day/month/year or month/day/year
              final year = c;
              // prefer day/month/year; if a > 12 it must be day
              if (a <= 12 && b <= 12) {
                // ambiguous: try day/month/year first; if invalid, try month/day/year
                return _safeDate(year, b, a) ?? _safeDate(year, a, b);
              }
              return _safeDate(year, b, a);
            } else {
              // two-digit year
              final year = c < 50 ? 2000 + c : 1900 + c;
              if (a <= 12 && b <= 12) {
                return _safeDate(year, b, a) ?? _safeDate(year, a, b);
              }
              return _safeDate(year, b, a);
            }
          }
        } catch (e) {
          debugPrint('Receipt date parse error: $e');
        }
      }
    }
    return null;
  }

  static DateTime? _safeDate(int year, int month, int day) {
    try {
      return DateTime(year, month, day);
    } catch (e) {
      debugPrint('Receipt safeDate error: $e');
      return null;
    }
  }

  static double? _extractAmount(String line) {
    final matches = RegExp(r'(?:^|\s|\$|€|£|₹|Rs\.?)(\d+(?:[.,]\d{1,2})?)\s*').allMatches(line);
    for (final m in matches) {
      final raw = m.group(1)!.replaceAll(',', '.');
      final value = double.tryParse(raw);
      if (value != null && value > 0) return value;
    }
    return null;
  }

  static void dispose() {
    _recognizer?.close();
    _recognizer = null;
  }
}

class ReceiptScanResult {
  final String merchant;
  final double total;
  final DateTime date;
  final String rawText;
  final String? imagePath;
  final String? error;

  ReceiptScanResult({
    required this.merchant,
    required this.total,
    required this.date,
    required this.rawText,
    this.imagePath,
    this.error,
  });

  ReceiptScanResult.empty() : this(merchant: '', total: 0, date: DateTime.now(), rawText: '', imagePath: null, error: null);

  ReceiptScanResult.error(String message) : this(merchant: '', total: 0, date: DateTime.now(), rawText: '', imagePath: null, error: message);

  bool get isEmpty => merchant.isEmpty && total == 0 && error == null;
}
