import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceTransactionService {
  static final SpeechToText _speech = SpeechToText();
  static bool _initialized = false;

  static bool get isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  static Future<bool> initialize() async {
    if (!isSupported) return false;
    if (_initialized) return true;
    try {
      _initialized = await _speech.initialize(
        onError: (e) => debugPrint('Speech error: $e'),
        onStatus: (s) => debugPrint('Speech status: $s'),
      );
    } catch (e) {
      debugPrint('Speech init failed: $e');
    }
    return _initialized;
  }

  static Future<VoiceResult> listen({Duration timeout = const Duration(seconds: 10)}) async {
    if (!isSupported) return VoiceResult.error('Voice input is not supported on this device.');
    final ready = await initialize();
    if (!ready) return VoiceResult.error('Voice input is unavailable. Check microphone permission.');

    final completer = Completer<VoiceResult>();
    Timer? timer;

    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          timer?.cancel();
          _speech.stop();
          completer.complete(_parse(result.recognizedWords));
        }
      },
      listenMode: ListenMode.confirmation,
      cancelOnError: true,
    );

    timer = Timer(timeout, () async {
      if (!completer.isCompleted) {
        await _speech.stop();
        completer.complete(VoiceResult.error('No voice detected. Please try again.'));
      }
    });

    return completer.future;
  }

  static Future<void> stop() async {
    if (_initialized) await _speech.stop();
  }

  static VoiceResult _parse(String text) {
    final lower = text.toLowerCase();
    // Extract amount
    final amountMatch = RegExp(r'(\d+(?:[.,]\d{1,2})?)').firstMatch(lower);
    final amount = amountMatch != null ? double.tryParse(amountMatch.group(1)!.replaceAll(',', '.')) : null;

    if (amount == null || amount <= 0) {
      return VoiceResult.error('Could not understand the amount. Try saying "Coffee 4.50".');
    }

    // Credit or debit
    bool isCredit = lower.contains('income') || lower.contains('salary') || lower.contains('deposit') || lower.contains('received');
    final type = isCredit ? 'CR' : 'DR';

    // Title: remove amount and common words
    String title = text
        .replaceAll(RegExp(r'\d+(?:[.,]\d{1,2})?'), '')
        .replaceAll(RegExp(r'\b(income|expense|salary|deposit|received|paid|spent|bought|for)\b', caseSensitive: false), '')
        .trim();
    if (title.isEmpty) title = isCredit ? 'Income' : 'Expense';

    return VoiceResult(text: text, amount: amount, title: title, type: type);
  }
}

class VoiceResult {
  final String? text;
  final double? amount;
  final String? title;
  final String? type;
  final String? error;

  VoiceResult({this.text, this.amount, this.title, this.type, this.error});
  VoiceResult.error(String message) : this(error: message);

  bool get isSuccess => error == null && amount != null && amount! > 0;
}
