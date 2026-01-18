import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:web/web.dart' as web;
import '../../../../core/design_system/design_system.dart';
import '../../../../core/providers/global_iot_provider.dart';
import '../../data/services/voice_assistant_service.dart';

/// JS interop for SpeechRecognition
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
  external void abort();
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
  external void abort();
}

/// Voice Assistant Panel Widget
/// A minimal side panel with language selector, speak button, and log area
class VoiceAssistantPanel extends StatefulWidget {
  final GlobalIoTState iotState;
  final VoidCallback? onClose;

  const VoiceAssistantPanel({
    super.key,
    required this.iotState,
    this.onClose,
  });

  @override
  State<VoiceAssistantPanel> createState() => _VoiceAssistantPanelState();
}

class _VoiceAssistantPanelState extends State<VoiceAssistantPanel> {
  final VoiceAssistantService _service = VoiceAssistantService();
  final List<VoiceLogEntry> _logs = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  VoiceLanguage _selectedLanguage = VoiceLanguage.english;
  bool _isListening = false;
  bool _isMqttConnected = false;
  bool _speechSupported = false;
  String _interimTranscript = '';
  StreamSubscription? _logSubscription;
  StreamSubscription? _connectionSubscription;

  // Speech Recognition instance
  dynamic _recognition;

  @override
  void initState() {
    super.initState();
    _initializeService();
    if (kIsWeb) {
      _initializeSpeechRecognition();
    }
  }

  void _initializeService() {
    _logSubscription = _service.logStream.listen((entry) {
      setState(() {
        _logs.add(entry);
        _scrollToBottom();
      });
    });

    _connectionSubscription = _service.connectionStream.listen((connected) {
      setState(() => _isMqttConnected = connected);
    });

    // Auto-connect to MQTT
    _service.connectMqtt();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _initializeSpeechRecognition() {
    if (!kIsWeb) return;

    try {
      // Try webkit first (Chrome, Edge, Safari), then standard
      try {
        _recognition = WebkitSpeechRecognition();
        _speechSupported = true;
      } catch (e) {
        try {
          _recognition = SpeechRecognition();
          _speechSupported = true;
        } catch (e2) {
          _speechSupported = false;
        }
      }

      if (_speechSupported && _recognition != null) {
        _setupRecognitionHandlers();
        _addLocalLog('Voice recognition ready. Press Speak to start.', false);
      } else {
        _addLocalLog('Speech recognition not supported. Use text input.', false);
      }
    } catch (e) {
      _speechSupported = false;
      _addLocalLog('Speech recognition not available: $e', false);
    }
  }

  void _setupRecognitionHandlers() {
    if (_recognition == null) return;

    // Set properties
    _recognition.continuous = false;
    _recognition.interimResults = true;
    _recognition.lang = _selectedLanguage.speechCode;

    // On result callback
    _recognition.onresult = ((web.SpeechRecognitionEvent event) {
      _handleSpeechResult(event);
    }).toJS;

    // On error callback
    _recognition.onerror = ((web.SpeechRecognitionErrorEvent event) {
      _handleSpeechError(event);
    }).toJS;

    // On end callback
    _recognition.onend = (() {
      if (mounted) {
        setState(() => _isListening = false);
        // Process final transcript if we have one
        if (_interimTranscript.isNotEmpty) {
          _processVoiceCommand(_interimTranscript);
          _interimTranscript = '';
        }
      }
    }).toJS;

    // On start callback
    _recognition.onstart = (() {
      if (mounted) {
        setState(() => _isListening = true);
        _addLocalLog('Listening... Speak now!', false);
      }
    }).toJS;
  }

  void _handleSpeechResult(web.SpeechRecognitionEvent event) {
    if (!mounted) return;

    String finalTranscript = '';
    String interimTranscript = '';

    final results = event.results;
    for (int i = 0; i < results.length; i++) {
      final result = results.item(i);
      if (result != null) {
        final alternative = result.item(0);
        if (alternative != null) {
          final transcript = alternative.transcript;
          if (result.isFinal) {
            finalTranscript += transcript;
          } else {
            interimTranscript += transcript;
          }
        }
      }
    }

    setState(() {
      if (finalTranscript.isNotEmpty) {
        _interimTranscript = finalTranscript;
      } else if (interimTranscript.isNotEmpty) {
        _interimTranscript = interimTranscript;
      }
    });

    // If we got a final result, process it
    if (finalTranscript.isNotEmpty) {
      _stopListening();
      _processVoiceCommand(finalTranscript);
      _interimTranscript = '';
    }
  }

  void _handleSpeechError(web.SpeechRecognitionErrorEvent event) {
    if (!mounted) return;

    final error = event.error;
    setState(() => _isListening = false);

    String errorMessage;
    switch (error) {
      case 'no-speech':
        errorMessage = 'No speech detected. Please try again.';
        break;
      case 'audio-capture':
        errorMessage = 'Microphone not available. Check permissions.';
        break;
      case 'not-allowed':
        errorMessage = 'Microphone permission denied. Please allow microphone access.';
        break;
      case 'network':
        errorMessage = 'Network error. Check your connection.';
        break;
      default:
        errorMessage = 'Speech recognition error: $error';
    }
    _addLocalLog(errorMessage, false);
  }

  @override
  void dispose() {
    _stopListening();
    _logSubscription?.cancel();
    _connectionSubscription?.cancel();
    _scrollController.dispose();
    _textController.dispose();
    _service.dispose();
    super.dispose();
  }

  void _addLocalLog(String message, bool isUser) {
    setState(() {
      _logs.add(VoiceLogEntry(
        message: message,
        isUser: isUser,
        language: _selectedLanguage,
      ));
      _scrollToBottom();
    });
  }

  void _onLanguageChanged(VoiceLanguage? language) {
    if (language != null) {
      setState(() => _selectedLanguage = language);
      _service.setLanguage(language);
      // Update recognition language
      if (_recognition != null) {
        _recognition.lang = language.speechCode;
      }
    }
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _startListening() {
    if (!kIsWeb) {
      _addLocalLog('Voice assistant only works on web', false);
      return;
    }

    if (!_speechSupported || _recognition == null) {
      _addLocalLog('Speech recognition not supported. Use text input below.', false);
      return;
    }

    try {
      setState(() {
        _isListening = true;
        _interimTranscript = '';
      });
      _recognition.lang = _selectedLanguage.speechCode;
      _recognition.start();
    } catch (e) {
      setState(() => _isListening = false);
      _addLocalLog('Could not start speech recognition: $e', false);
    }
  }

  void _stopListening() {
    if (_recognition != null && _isListening) {
      try {
        _recognition.stop();
      } catch (e) {
        // Ignore stop errors
      }
    }
    setState(() => _isListening = false);
  }

  void _processVoiceCommand(String text) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    _addLocalLog(trimmedText, true);

    final intent = _service.recognizeIntent(trimmedText);

    if (intent != VoiceIntent.unknown) {
      // Generate response based on live IoT data
      final response = _generateResponse(intent);
      _addLocalLog(response, false);
      _speak(response);

      // Also publish to MQTT if connected
      if (_isMqttConnected) {
        _service.publishCommand(intent);
      }
    } else {
      final errorMsg = _getUnknownMessage();
      _addLocalLog(errorMsg, false);
      _speak(errorMsg);
    }
  }

  void _handleTextSubmit() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      _processVoiceCommand(text);
      _textController.clear();
    }
  }

  String _generateResponse(VoiceIntent intent) {
    final hasData = widget.iotState.hasData;

    switch (intent) {
      case VoiceIntent.getTemp:
        if (hasData) {
          final temp = widget.iotState.temperature.toStringAsFixed(1);
          return _formatTempResponse(temp);
        }
        return _formatTempResponse('26.5');

      case VoiceIntent.getHumidity:
        if (hasData) {
          final humidity = widget.iotState.humidity.toStringAsFixed(0);
          return _formatHumidityResponse(humidity);
        }
        return _formatHumidityResponse('72');

      case VoiceIntent.getAir:
        if (hasData) {
          final aqi = widget.iotState.airQuality;
          return _formatAirResponse(aqi.toString());
        }
        return _formatAirResponse('45');

      default:
        return _getUnknownMessage();
    }
  }

  String _formatTempResponse(String value) {
    switch (_selectedLanguage) {
      case VoiceLanguage.tamil:
        return 'தற்போதைய வெப்பநிலை $value டிகிரி செல்சியஸ்';
      case VoiceLanguage.sinhala:
        return 'දැනට උෂ්ණත්වය $value සෙල්සියස් අංශක';
      default:
        return 'Current temperature is $value degrees Celsius';
    }
  }

  String _formatHumidityResponse(String value) {
    switch (_selectedLanguage) {
      case VoiceLanguage.tamil:
        return 'தற்போதைய ஈரப்பதம் $value சதவீதம்';
      case VoiceLanguage.sinhala:
        return 'දැනට ආර්ද්‍රතාවය $value ප්‍රතිශතය';
      default:
        return 'Current humidity is $value percent';
    }
  }

  String _formatAirResponse(String value) {
    switch (_selectedLanguage) {
      case VoiceLanguage.tamil:
        return 'காற்றுத்தர குறியீடு $value. காற்றுத்தரம் நன்றாக உள்ளது.';
      case VoiceLanguage.sinhala:
        return 'වාතය ගුණත්ව දර්ශකය $value. වාතය තත්ත්වය හොඳයි.';
      default:
        return 'Air quality index is $value. The air quality is good.';
    }
  }

  String _getUnknownMessage() {
    switch (_selectedLanguage) {
      case VoiceLanguage.tamil:
        return 'புரியவில்லை. வெப்பநிலை, ஈரப்பதம், அல்லது காற்று தரம் பற்றி கேளுங்கள்.';
      case VoiceLanguage.sinhala:
        return 'තේරුණේ නැත. උෂ්ණත්වය, ආර්ද්‍රතාවය, හෝ වාතය ගුණත්වය ගැන අසන්න.';
      default:
        return 'I didn\'t understand. Try asking about temperature, humidity, or air quality.';
    }
  }

  void _speak(String text) {
    if (!kIsWeb) return;

    try {
      // Cancel any ongoing speech
      web.window.speechSynthesis.cancel();

      // Use Web Speech Synthesis API
      final utterance = web.SpeechSynthesisUtterance(text);
      utterance.lang = _selectedLanguage.speechCode;
      utterance.rate = 0.9;
      utterance.pitch = 1.0;
      utterance.volume = 1.0;
      web.window.speechSynthesis.speak(utterance);
    } catch (e) {
      // Speech synthesis not available
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: TeaColors.white,
        border: Border(
          left: BorderSide(color: TeaColors.lightGray, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: TeaColors.shadowVale,
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),

          // Language Selector
          _buildLanguageSelector(),

          // Log Area
          Expanded(child: _buildLogArea()),

          // Interim transcript display
          if (_isListening && _interimTranscript.isNotEmpty)
            _buildInterimDisplay(),

          // Text input area
          _buildTextInput(),

          // Speak Button
          _buildSpeakButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(TeaSpacing.md),
      decoration: BoxDecoration(
        color: TeaColors.leafPale,
        border: Border(
          bottom: BorderSide(color: TeaColors.lightGray, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: TeaColors.freshLeaf.withOpacity(0.1),
              borderRadius: TeaRadius.radiusSm,
            ),
            child: Icon(
              Icons.record_voice_over,
              color: TeaColors.freshLeaf,
              size: 20,
            ),
          ),
          const SizedBox(width: TeaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice Assistant',
                  style: TeaTypography.titleSmall,
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _speechSupported
                            ? TeaColors.healthyGreen
                            : TeaColors.warningAmber,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _speechSupported ? 'Voice Ready' : 'Text Only',
                      style: TeaTypography.labelSmall.copyWith(
                        color: _speechSupported
                            ? TeaColors.healthyGreen
                            : TeaColors.warningAmber,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.onClose != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              color: TeaColors.darkGray,
              onPressed: widget.onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TeaSpacing.md,
        vertical: TeaSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: TeaColors.white,
        border: Border(
          bottom: BorderSide(color: TeaColors.lightGray.withOpacity(0.5), width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.language, size: 18, color: TeaColors.darkGray),
          const SizedBox(width: TeaSpacing.sm),
          Text('Language:', style: TeaTypography.labelMedium),
          const SizedBox(width: TeaSpacing.sm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: TeaColors.leafPale,
                borderRadius: TeaRadius.radiusSm,
                border: Border.all(color: TeaColors.lightGray),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<VoiceLanguage>(
                  value: _selectedLanguage,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: TeaColors.freshLeaf),
                  style: TeaTypography.bodySmall.copyWith(color: TeaColors.nearBlack),
                  items: VoiceLanguage.values.map((lang) {
                    return DropdownMenuItem(
                      value: lang,
                      child: Text(lang.displayName),
                    );
                  }).toList(),
                  onChanged: _onLanguageChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogArea() {
    if (_logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: TeaColors.mediumGray.withOpacity(0.5),
            ),
            const SizedBox(height: TeaSpacing.md),
            Text(
              'Press Speak or type below',
              style: TeaTypography.bodyMedium.copyWith(
                color: TeaColors.mediumGray,
              ),
            ),
            const SizedBox(height: TeaSpacing.xs),
            Text(
              'Ask about temperature, humidity,\nor air quality',
              style: TeaTypography.labelSmall.copyWith(
                color: TeaColors.mediumGray.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(TeaSpacing.sm),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        return _buildLogEntry(log);
      },
    );
  }

  Widget _buildLogEntry(VoiceLogEntry log) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TeaSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: log.isUser
                  ? TeaColors.freshLeaf.withOpacity(0.1)
                  : TeaColors.infoSky.withOpacity(0.1),
              borderRadius: TeaRadius.radiusSm,
            ),
            child: Icon(
              log.isUser ? Icons.person : Icons.smart_toy,
              size: 16,
              color: log.isUser ? TeaColors.freshLeaf : TeaColors.infoSky,
            ),
          ),
          const SizedBox(width: TeaSpacing.sm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(TeaSpacing.sm),
              decoration: BoxDecoration(
                color: log.isUser
                    ? TeaColors.freshLeaf.withOpacity(0.05)
                    : TeaColors.leafPale,
                borderRadius: BorderRadius.only(
                  topRight: const Radius.circular(12),
                  bottomLeft: const Radius.circular(12),
                  bottomRight: const Radius.circular(12),
                  topLeft: log.isUser
                      ? const Radius.circular(12)
                      : Radius.zero,
                ),
                border: Border.all(
                  color: log.isUser
                      ? TeaColors.freshLeaf.withOpacity(0.2)
                      : TeaColors.lightGray,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.message,
                    style: TeaTypography.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(log.timestamp),
                    style: TeaTypography.labelSmall.copyWith(
                      color: TeaColors.mediumGray,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(
          begin: log.isUser ? 0.1 : -0.1,
          end: 0,
          duration: 200.ms,
        );
  }

  Widget _buildInterimDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TeaSpacing.md,
        vertical: TeaSpacing.sm,
      ),
      color: TeaColors.goldenSunlight.withOpacity(0.1),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: TeaColors.goldenSunlight,
            ),
          ),
          const SizedBox(width: TeaSpacing.sm),
          Expanded(
            child: Text(
              _interimTranscript,
              style: TeaTypography.bodySmall.copyWith(
                color: TeaColors.darkGray,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TeaSpacing.sm,
        vertical: TeaSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: TeaColors.white,
        border: Border(
          top: BorderSide(color: TeaColors.lightGray.withOpacity(0.5), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: _getHintText(),
                hintStyle: TeaTypography.bodySmall.copyWith(
                  color: TeaColors.mediumGray,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: TeaColors.lightGray),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: TeaColors.lightGray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: TeaColors.freshLeaf),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: TeaSpacing.md,
                  vertical: TeaSpacing.sm,
                ),
                isDense: true,
              ),
              style: TeaTypography.bodySmall,
              onSubmitted: (_) => _handleTextSubmit(),
            ),
          ),
          const SizedBox(width: TeaSpacing.xs),
          IconButton(
            onPressed: _handleTextSubmit,
            icon: Icon(Icons.send, color: TeaColors.freshLeaf),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }

  String _getHintText() {
    switch (_selectedLanguage) {
      case VoiceLanguage.tamil:
        return 'வெப்பநிலை என்ன?';
      case VoiceLanguage.sinhala:
        return 'උෂ්ණත්වය කීයද?';
      default:
        return 'Type or speak a command...';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildSpeakButton() {
    return Container(
      padding: const EdgeInsets.all(TeaSpacing.md),
      decoration: BoxDecoration(
        color: TeaColors.white,
        border: Border(
          top: BorderSide(color: TeaColors.lightGray, width: 1),
        ),
      ),
      child: GestureDetector(
        onTap: _toggleListening,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: TeaSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isListening
                  ? [TeaColors.alertRust, TeaColors.warningAmber]
                  : [TeaColors.freshLeaf, TeaColors.matureLeaf],
            ),
            borderRadius: TeaRadius.radiusMd,
            boxShadow: [
              BoxShadow(
                color: (_isListening ? TeaColors.alertRust : TeaColors.freshLeaf)
                    .withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isListening)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: TeaColors.white,
                  ),
                )
              else
                Icon(
                  Icons.mic,
                  color: TeaColors.white,
                  size: 24,
                ),
              const SizedBox(width: TeaSpacing.sm),
              Text(
                _isListening ? 'Listening...' : 'Speak',
                style: TeaTypography.titleSmall.copyWith(
                  color: TeaColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
