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

    final timer = Timer(timeout, () async {
      if (!completer.isCompleted) {
        await _speech.stop();
        completer.complete(VoiceResult.error('No voice detected. Please try again.'));
      }
    });

    unawaited(
      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            timer.cancel();
            _speech.stop();
            if (!completer.isCompleted) {
              completer.complete(_parse(result.recognizedWords));
            }
          }
        },
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.confirmation,
          cancelOnError: true,
        ),
      ).catchError((e) {
        timer.cancel();
        if (!completer.isCompleted) {
          completer.complete(VoiceResult.error('Voice input failed: $e'));
        }
      }),
    );

    return completer.future;
  }

  static Future<void> stop() async {
    if (_initialized) await _speech.stop();
  }

  static VoiceResult _parse(String text) {
    final lower = text.toLowerCase();
    // Extract amount including thousands separators
    final amountMatch = RegExp(r'\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?').firstMatch(text);
    final amount = amountMatch != null ? _parseAmount(amountMatch.group(0)!) : null;

    if (amount == null || amount <= 0) {
      return VoiceResult.error('Could not understand the amount. Try saying "Coffee 4.50".');
    }

    // Credit or debit
    bool isCredit = lower.contains('income') || lower.contains('salary') || lower.contains('deposit') || lower.contains('received');
    final type = isCredit ? 'CR' : 'DR';

    // Title: remove the matched amount and common words
    final matched = amountMatch?.group(0);
    String title = text;
    if (matched != null) {
      title = title.replaceFirst(matched, '');
    }
    title = title
        .replaceAll(RegExp(r'\b(income|expense|salary|deposit|received|paid|spent|bought|for)\b', caseSensitive: false), '')
        .trim();
    if (title.isEmpty) title = isCredit ? 'Income' : 'Expense';

    return VoiceResult(text: text, amount: amount, title: title, type: type);
  }

  static double? _parseAmount(String raw) {
    if (raw.isEmpty) return null;
    // Identify the last separator and decide whether it's decimal or thousands
    final dotIndex = raw.lastIndexOf('.');
    final commaIndex = raw.lastIndexOf(',');
    final lastSepIndex = dotIndex > commaIndex ? dotIndex : commaIndex;
    if (lastSepIndex == -1) return double.tryParse(raw);

    final after = raw.substring(lastSepIndex + 1);
    final lastSep = raw[lastSepIndex];
    if (after.length == 2) {
      // Treat the last separator as the decimal point
      final otherSep = lastSep == '.' ? ',' : '.';
      final normalized = raw.replaceAll(otherSep, '').replaceFirst(lastSep, '.', lastSepIndex);
      return double.tryParse(normalized);
    } else if (after.length == 3) {
      // Treat it as a thousands separator and remove all separators
      return double.tryParse(raw.replaceAll(RegExp(r'[.,]'), ''));
    }
    return double.tryParse(raw.replaceAll(',', '.'));
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

  bool get isSuccess {
    final amt = amount;
    return error == null && amt != null && amt > 0;
  }
}
