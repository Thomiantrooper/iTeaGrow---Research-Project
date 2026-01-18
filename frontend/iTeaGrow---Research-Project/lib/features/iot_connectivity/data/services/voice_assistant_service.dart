import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

/// Supported languages for voice assistant
enum VoiceLanguage {
  english('en', 'English', 'en-US'),
  tamil('ta', 'Tamil', 'ta-IN'),
  sinhala('si', 'Sinhala', 'si-LK');

  const VoiceLanguage(this.code, this.displayName, this.speechCode);
  final String code;
  final String displayName;
  final String speechCode;
}

/// Voice command intents
enum VoiceIntent {
  getTemp('GET_TEMP'),
  getHumidity('GET_HUMIDITY'),
  getAir('GET_AIR'),
  unknown('UNKNOWN');

  const VoiceIntent(this.value);
  final String value;
}

/// Voice command message structure
class VoiceCommand {
  final String type = 'voice_command';
  final VoiceIntent intent;
  final VoiceLanguage language;
  final DateTime timestamp;

  VoiceCommand({
    required this.intent,
    required this.language,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'type': type,
        'intent': intent.value,
        'language': language.code,
        'timestamp': timestamp.toIso8601String(),
      };

  String toJsonString() => jsonEncode(toJson());
}

/// Voice assistant log entry
class VoiceLogEntry {
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final VoiceLanguage? language;

  VoiceLogEntry({
    required this.message,
    required this.isUser,
    DateTime? timestamp,
    this.language,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Voice Assistant Service
/// Handles Web Speech API for STT/TTS and MQTT for messaging
class VoiceAssistantService {
  static const String mqttTopic = 'auralink/device01/messages';
  static const String defaultBrokerUrl = 'ws://localhost:9001';

  MqttBrowserClient? _mqttClient;
  bool _isMqttConnected = false;
  VoiceLanguage _currentLanguage = VoiceLanguage.english;

  // Stream controllers
  final _logController = StreamController<VoiceLogEntry>.broadcast();
  final _listeningController = StreamController<bool>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<VoiceLogEntry> get logStream => _logController.stream;
  Stream<bool> get listeningStream => _listeningController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isMqttConnected => _isMqttConnected;
  VoiceLanguage get currentLanguage => _currentLanguage;

  /// Phrase patterns for intent recognition in different languages
  static final Map<VoiceLanguage, Map<VoiceIntent, List<String>>> _intentPatterns = {
    VoiceLanguage.english: {
      VoiceIntent.getTemp: [
        'temperature',
        'temp',
        'how hot',
        'how cold',
        'degrees',
        'what is the temperature',
        'get temperature',
        'tell me temperature',
      ],
      VoiceIntent.getHumidity: [
        'humidity',
        'humid',
        'moisture',
        'how humid',
        'what is the humidity',
        'get humidity',
        'tell me humidity',
      ],
      VoiceIntent.getAir: [
        'air quality',
        'air',
        'aqi',
        'pollution',
        'what is the air',
        'get air',
        'tell me air quality',
      ],
    },
    VoiceLanguage.tamil: {
      VoiceIntent.getTemp: [
        'வெப்பநிலை',
        'சூடு',
        'குளிர்',
        'டிகிரி',
      ],
      VoiceIntent.getHumidity: [
        'ஈரப்பதம்',
        'ஈரம்',
        'ஈர்ப்பு',
      ],
      VoiceIntent.getAir: [
        'காற்று தரம்',
        'காற்று',
        'மாசு',
      ],
    },
    VoiceLanguage.sinhala: {
      VoiceIntent.getTemp: [
        'උෂ්ණත්වය',
        'සීතල',
        'උණුසුම',
      ],
      VoiceIntent.getHumidity: [
        'ආර්ද්‍රතාවය',
        'තෙත',
      ],
      VoiceIntent.getAir: [
        'වාතය ගුණත්වය',
        'වාතය',
        'දූෂණය',
      ],
    },
  };

  /// Set current language
  void setLanguage(VoiceLanguage language) {
    _currentLanguage = language;
    _addLog('Language changed to ${language.displayName}', isUser: false);
  }

  /// Connect to MQTT broker over WebSockets
  Future<bool> connectMqtt({String? brokerUrl}) async {
    if (!kIsWeb) {
      _addLog('Voice assistant is only supported on web', isUser: false);
      return false;
    }

    try {
      final url = brokerUrl ?? defaultBrokerUrl;
      _mqttClient = MqttBrowserClient(url, 'iteagrow_voice_${DateTime.now().millisecondsSinceEpoch}');
      _mqttClient!.port = 9001;
      _mqttClient!.keepAlivePeriod = 30;
      _mqttClient!.logging(on: false);
      _mqttClient!.autoReconnect = true;
      _mqttClient!.onConnected = _onMqttConnected;
      _mqttClient!.onDisconnected = _onMqttDisconnected;
      _mqttClient!.onSubscribed = _onMqttSubscribed;

      final connMessage = MqttConnectMessage()
          .withClientIdentifier('iteagrow_voice_${DateTime.now().millisecondsSinceEpoch}')
          .startClean()
          .withWillQos(MqttQos.atMostOnce);
      _mqttClient!.connectionMessage = connMessage;

      await _mqttClient!.connect();

      if (_mqttClient!.connectionStatus?.state == MqttConnectionState.connected) {
        _isMqttConnected = true;
        _connectionController.add(true);
        _subscribeToTopic();
        _addLog('Connected to MQTT broker', isUser: false);
        return true;
      }
    } catch (e) {
      _addLog('MQTT connection failed: $e', isUser: false);
    }

    _isMqttConnected = false;
    _connectionController.add(false);
    return false;
  }

  void _onMqttConnected() {
    _isMqttConnected = true;
    _connectionController.add(true);
  }

  void _onMqttDisconnected() {
    _isMqttConnected = false;
    _connectionController.add(false);
    _addLog('Disconnected from MQTT broker', isUser: false);
  }

  void _onMqttSubscribed(String topic) {
    _addLog('Subscribed to $topic', isUser: false);
  }

  void _subscribeToTopic() {
    if (_mqttClient == null) return;
    _mqttClient!.subscribe(mqttTopic, MqttQos.atMostOnce);

    _mqttClient!.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (var message in messages) {
        final payload = message.payload as MqttPublishMessage;
        final text = MqttPublishPayload.bytesToStringAsString(payload.payload.message);
        _handleMqttMessage(text);
      }
    });
  }

  void _handleMqttMessage(String message) {
    try {
      final json = jsonDecode(message);
      if (json['type'] == 'voice_response') {
        final responseText = json['text'] as String? ?? 'No response';
        _addLog(responseText, isUser: false, language: _currentLanguage);
        _speak(responseText);
      }
    } catch (e) {
      // Not a JSON response, just log it
      _addLog(message, isUser: false);
    }
  }

  /// Disconnect from MQTT
  void disconnectMqtt() {
    _mqttClient?.disconnect();
    _isMqttConnected = false;
    _connectionController.add(false);
  }

  /// Recognize intent from spoken text
  VoiceIntent recognizeIntent(String text) {
    final lowerText = text.toLowerCase();
    final patterns = _intentPatterns[_currentLanguage] ?? _intentPatterns[VoiceLanguage.english]!;

    for (var entry in patterns.entries) {
      for (var pattern in entry.value) {
        if (lowerText.contains(pattern.toLowerCase())) {
          return entry.key;
        }
      }
    }

    return VoiceIntent.unknown;
  }

  /// Publish voice command to MQTT
  void publishCommand(VoiceIntent intent) {
    if (!_isMqttConnected || _mqttClient == null) {
      _addLog('Not connected to MQTT', isUser: false);
      return;
    }

    final command = VoiceCommand(intent: intent, language: _currentLanguage);
    final builder = MqttClientPayloadBuilder();
    builder.addString(command.toJsonString());

    _mqttClient!.publishMessage(
      mqttTopic,
      MqttQos.atMostOnce,
      builder.payload!,
    );

    _addLog('Sent: ${intent.value}', isUser: true, language: _currentLanguage);
  }

  /// Process speech result
  void processSpeechResult(String text) {
    _addLog(text, isUser: true, language: _currentLanguage);

    final intent = recognizeIntent(text);
    if (intent != VoiceIntent.unknown) {
      publishCommand(intent);
    } else {
      final unknownMsg = _getUnknownCommandMessage();
      _addLog(unknownMsg, isUser: false, language: _currentLanguage);
      _speak(unknownMsg);
    }
  }

  String _getUnknownCommandMessage() {
    switch (_currentLanguage) {
      case VoiceLanguage.tamil:
        return 'புரியவில்லை. வெப்பநிலை, ஈரப்பதம், அல்லது காற்று தரம் என்று கேளுங்கள்.';
      case VoiceLanguage.sinhala:
        return 'තේරුණේ නැත. උෂ්ණත්වය, ආර්ද්‍රතාවය, හෝ වාතය ගුණත්වය ගැන අසන්න.';
      default:
        return 'Command not recognized. Try asking about temperature, humidity, or air quality.';
    }
  }

  /// Text-to-speech (Web Speech API)
  void _speak(String text) {
    // This will be handled by the widget using JS interop
    // The widget will call the browser's speechSynthesis API
  }

  void _addLog(String message, {required bool isUser, VoiceLanguage? language}) {
    _logController.add(VoiceLogEntry(
      message: message,
      isUser: isUser,
      language: language ?? _currentLanguage,
    ));
  }

  /// Clean up resources
  void dispose() {
    disconnectMqtt();
    _logController.close();
    _listeningController.close();
    _connectionController.close();
  }
}
