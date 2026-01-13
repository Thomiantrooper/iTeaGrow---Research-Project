import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Voice interaction service for speech-to-text and text-to-speech
/// Supports English, Sinhala, and Tamil languages

enum VoiceLanguage {
  english('en-US', 'English'),
  sinhala('si-LK', 'Sinhala'),
  tamil('ta-LK', 'Tamil');

  final String code;
  final String name;
  const VoiceLanguage(this.code, this.name);
}

enum VoiceState {
  idle,
  listening,
  processing,
  speaking,
  error,
}

class VoiceServiceState {
  final VoiceState state;
  final String? transcript;
  final String? errorMessage;
  final VoiceLanguage language;
  final double? confidence;
  final bool isAvailable;

  const VoiceServiceState({
    this.state = VoiceState.idle,
    this.transcript,
    this.errorMessage,
    this.language = VoiceLanguage.english,
    this.confidence,
    this.isAvailable = true,
  });

  VoiceServiceState copyWith({
    VoiceState? state,
    String? transcript,
    String? errorMessage,
    VoiceLanguage? language,
    double? confidence,
    bool? isAvailable,
  }) {
    return VoiceServiceState(
      state: state ?? this.state,
      transcript: transcript ?? this.transcript,
      errorMessage: errorMessage ?? this.errorMessage,
      language: language ?? this.language,
      confidence: confidence ?? this.confidence,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

class VoiceService extends StateNotifier<VoiceServiceState> {
  VoiceService() : super(const VoiceServiceState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize speech recognition and TTS
    // For now, we'll simulate availability
    state = state.copyWith(isAvailable: true);
  }

  /// Start listening for voice input
  Future<void> startListening() async {
    if (state.state == VoiceState.listening) return;

    state = state.copyWith(
      state: VoiceState.listening,
      transcript: null,
      errorMessage: null,
    );

    // Simulate listening - in production, use speech_to_text package
    // This is a placeholder that can be connected to actual speech recognition
    debugPrint('VoiceService: Started listening in ${state.language.name}');
  }

  /// Stop listening and process the audio
  Future<String?> stopListening() async {
    if (state.state != VoiceState.listening) return null;

    state = state.copyWith(state: VoiceState.processing);

    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 500));

    // In production, this would return the actual transcript
    state = state.copyWith(state: VoiceState.idle);
    return state.transcript;
  }

  /// Cancel listening without processing
  void cancelListening() {
    if (state.state == VoiceState.listening) {
      state = state.copyWith(
        state: VoiceState.idle,
        transcript: null,
      );
    }
  }

  /// Speak text using text-to-speech
  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    state = state.copyWith(state: VoiceState.speaking);

    // Simulate speaking - in production, use flutter_tts package
    debugPrint('VoiceService: Speaking - "$text"');

    // Estimate speaking duration (roughly 150ms per word)
    final wordCount = text.split(' ').length;
    final duration = Duration(milliseconds: wordCount * 150 + 500);
    await Future.delayed(duration);

    state = state.copyWith(state: VoiceState.idle);
  }

  /// Stop speaking
  void stopSpeaking() {
    if (state.state == VoiceState.speaking) {
      state = state.copyWith(state: VoiceState.idle);
    }
  }

  /// Change the voice language
  void setLanguage(VoiceLanguage language) {
    state = state.copyWith(language: language);
  }

  /// Update transcript (called during speech recognition)
  void updateTranscript(String transcript, {double? confidence}) {
    state = state.copyWith(
      transcript: transcript,
      confidence: confidence,
    );
  }

  /// Set error state
  void setError(String message) {
    state = state.copyWith(
      state: VoiceState.error,
      errorMessage: message,
    );
  }

  /// Reset to idle state
  void reset() {
    state = const VoiceServiceState();
  }
}

/// Provider for voice service
final voiceServiceProvider =
    StateNotifierProvider<VoiceService, VoiceServiceState>((ref) {
  return VoiceService();
});

/// Voice command patterns for tea cultivation assistant
class VoiceCommands {
  // Disease detection commands
  static const diseasePatterns = [
    r'scan.*leaf',
    r'check.*disease',
    r'detect.*disease',
    r'analyze.*leaf',
    r'what.*wrong.*leaf',
  ];

  // Weather/environment commands
  static const weatherPatterns = [
    r'weather',
    r'temperature',
    r'humidity',
    r'rain',
    r'forecast',
  ];

  // Treatment commands
  static const treatmentPatterns = [
    r'how.*treat',
    r'treatment',
    r'cure',
    r'fungicide',
    r'spray',
    r'organic.*solution',
  ];

  // General commands
  static const helpPatterns = [
    r'help',
    r'what.*can.*do',
    r'how.*use',
  ];

  /// Parse voice command and return intent
  static VoiceIntent parseCommand(String text) {
    final lowered = text.toLowerCase();

    // Check disease patterns
    for (final pattern in diseasePatterns) {
      if (RegExp(pattern).hasMatch(lowered)) {
        return VoiceIntent.diseaseDetection;
      }
    }

    // Check weather patterns
    for (final pattern in weatherPatterns) {
      if (RegExp(pattern).hasMatch(lowered)) {
        return VoiceIntent.weatherCheck;
      }
    }

    // Check treatment patterns
    for (final pattern in treatmentPatterns) {
      if (RegExp(pattern).hasMatch(lowered)) {
        return VoiceIntent.treatmentAdvice;
      }
    }

    // Check help patterns
    for (final pattern in helpPatterns) {
      if (RegExp(pattern).hasMatch(lowered)) {
        return VoiceIntent.help;
      }
    }

    return VoiceIntent.general;
  }
}

enum VoiceIntent {
  diseaseDetection,
  weatherCheck,
  treatmentAdvice,
  help,
  general,
}
