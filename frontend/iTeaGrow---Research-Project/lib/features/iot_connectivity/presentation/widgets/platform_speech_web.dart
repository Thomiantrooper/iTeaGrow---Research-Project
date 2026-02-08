// This file is platform-specific (Web)
import 'dart:js_interop';
import 'package:web/web.dart' as web;

typedef SpeechResultCallback = void Function(
    String finalTranscript, String interimTranscript,);
typedef SpeechErrorCallback = void Function(String error);
typedef SpeechStateCallback = void Function(bool isListening);

class PlatformSpeechRecognizer {
  dynamic _recognition;
  bool _isListening = false;

  final SpeechResultCallback onResult;
  final SpeechErrorCallback onError;
  final SpeechStateCallback onStateChanged;

  PlatformSpeechRecognizer({
    required this.onResult,
    required this.onError,
    required this.onStateChanged,
  });

  bool get isSupported => true;

  void initialize(String languageCode) {
    try {
      // Try webkit first (Chrome, Edge, Safari), then standard
      try {
        _recognition = WebkitSpeechRecognition();
      } catch (e) {
        try {
          _recognition = SpeechRecognition();
        } catch (e2) {
          onError('Speech not supported');
          return;
        }
      }

      if (_recognition != null) {
        _setupHandlers(languageCode);
      }
    } catch (e) {
      onError('Initialization failed: $e');
    }
  }

  void _setupHandlers(String languageCode) {
    if (_recognition == null) return;

    _recognition.continuous = false;
    _recognition.interimResults = true;
    _recognition.lang = languageCode;

    _recognition.onresult = ((web.SpeechRecognitionEvent event) {
      String finalT = '';
      String interimT = '';

      final results = event.results;
      for (int i = 0; i < results.length; i++) {
        final result = results.item(i);
        final alternative = result.item(0);
        final transcript = alternative.transcript;
        if (result.isFinal) {
          finalT += transcript;
        } else {
          interimT += transcript;
        }
                  }
      onResult(finalT, interimT);
    }).toJS;

    _recognition.onerror = ((web.SpeechRecognitionErrorEvent event) {
      onError(event.error);
    }).toJS;

    _recognition.onend = (() {
      _isListening = false;
      onStateChanged(false);
    }).toJS;

    _recognition.onstart = (() {
      _isListening = true;
      onStateChanged(true);
    }).toJS;
  }

  void start() {
    if (_recognition != null) {
      try {
        _recognition.start();
      } catch (e) {
        onError('Start failed: $e');
      }
    }
  }

  void stop() {
    if (_recognition != null) {
      try {
        _recognition.stop();
      } catch (e) {
        // ignore
      }
    }
  }

  void setLanguage(String langCode) {
    if (_recognition != null) {
      _recognition.lang = langCode;
    }
  }

  void speak(String text, String langCode) {
    try {
      web.window.speechSynthesis.cancel();
      final utterance = web.SpeechSynthesisUtterance(text);
      utterance.lang = langCode;
      utterance.rate = 0.9;
      utterance.pitch = 1.0;
      utterance.volume = 1.0;
      web.window.speechSynthesis.speak(utterance);
    } catch (e) {
      // ignore
    }
  }
}

// JS Interop definitions
@JS('webkitSpeechRecognition')
@staticInterop
class WebkitSpeechRecognition {
  external factory WebkitSpeechRecognition();
}

extension WebkitSpeechRecognitionExtension on WebkitSpeechRecognition {
  external set continuous(bool value);
  external set interimResults(bool value);
  external set lang(String value);
  external set onresult(JSFunction? callback);
  external set onerror(JSFunction? callback);
  external set onend(JSFunction? callback);
  external set onstart(JSFunction? callback);
  external void start();
  external void stop();
}

@JS('SpeechRecognition')
@staticInterop
class SpeechRecognition {
  external factory SpeechRecognition();
}

extension SpeechRecognitionExtension on SpeechRecognition {
  external set continuous(bool value);
  external set interimResults(bool value);
  external set lang(String value);
  external set onresult(JSFunction? callback);
  external set onerror(JSFunction? callback);
  external set onend(JSFunction? callback);
  external set onstart(JSFunction? callback);
  external void start();
  external void stop();
}
