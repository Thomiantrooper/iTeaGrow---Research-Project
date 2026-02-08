// This file is platform-specific (Stub for Android/iOS)

typedef SpeechResultCallback = void Function(
    String finalTranscript, String interimTranscript,);
typedef SpeechErrorCallback = void Function(String error);
typedef SpeechStateCallback = void Function(bool isListening);

class PlatformSpeechRecognizer {
  final SpeechResultCallback onResult;
  final SpeechErrorCallback onError;
  final SpeechStateCallback onStateChanged;

  PlatformSpeechRecognizer({
    required this.onResult,
    required this.onError,
    required this.onStateChanged,
  });

  bool get isSupported => false;

  void initialize(String languageCode) {
    // No-op on non-web
    onError('Voice assistant only works on web');
  }

  void start() {
    onError('Voice assistant only works on web');
  }

  void stop() {}

  void setLanguage(String langCode) {}

  void speak(String text, String langCode) {
    // No-op or use generic TTS plugin if available later
  }
}
