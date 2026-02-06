import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/jarvis_assistant.dart';

/// Chatbot Screen - AI Tea Assistant
class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      text: "Hello! I'm your Tea Garden Assistant. How can I help you today?\n\nYou can ask me about:\n- Disease detection and treatment\n- Plant care and growth stages\n- Weather and soil conditions\n- Harvest recommendations\n- IoT sensor management",
      isFromUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeaColors.mistGreen,
      appBar: AppBar(
        backgroundColor: TeaColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TeaColors.nearBlack),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            JarvisAssistant(
              size: 32,
              isListening: _isListening,
              isSpeaking: _isTyping,
            ),
            const SizedBox(width: TeaSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tea Assistant',
                  style: TeaTypography.titleMedium.copyWith(color: TeaColors.nearBlack),
                ),
                Text(
                  _isTyping ? 'Typing...' : 'Online',
                  style: TeaTypography.labelSmall.copyWith(
                    color: _isTyping ? TeaColors.warningAmber : TeaColors.healthyGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: TeaColors.nearBlack),
            onPressed: () => _showChatOptions(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: TeaSpacing.screenPadding,
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index], index);
              },
            ),
          ),

          // Quick Suggestions
          if (_messages.length <= 2)
            Container(
              padding: const EdgeInsets.symmetric(vertical: TeaSpacing.sm),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: TeaSpacing.screenPaddingHorizontal,
                child: Row(
                  children: [
                    _buildSuggestionChip('How to detect leaf disease?'),
                    _buildSuggestionChip('When should I harvest?'),
                    _buildSuggestionChip('Optimal soil conditions'),
                    _buildSuggestionChip('IoT sensor setup'),
                  ],
                ),
              ),
            ),

          // Input Area
          Container(
            color: TeaColors.white,
            padding: const EdgeInsets.all(TeaSpacing.md),
            child: SafeArea(
              child: Row(
                children: [
                  // Voice Input Button
                  GestureDetector(
                    onLongPressStart: (_) => setState(() => _isListening = true),
                    onLongPressEnd: (_) {
                      setState(() => _isListening = false);
                      _simulateVoiceInput();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(TeaSpacing.sm),
                      decoration: BoxDecoration(
                        color: _isListening
                            ? TeaColors.freshLeaf.withOpacity(0.2)
                            : TeaColors.mistGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? TeaColors.freshLeaf : TeaColors.darkGray,
                      ),
                    ),
                  ),
                  const SizedBox(width: TeaSpacing.sm),

                  // Text Input
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: TeaColors.mistGreen,
                        border: OutlineInputBorder(
                          borderRadius: TeaRadius.radiusRound,
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: TeaSpacing.md,
                          vertical: TeaSpacing.sm,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: TeaSpacing.sm),

                  // Send Button
                  Container(
                    decoration: BoxDecoration(
                      color: TeaColors.freshLeaf,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    return Align(
      alignment: message.isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: TeaSpacing.sm,
          left: message.isFromUser ? 48 : 0,
          right: message.isFromUser ? 0 : 48,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: TeaSpacing.md,
          vertical: TeaSpacing.smd,
        ),
        decoration: BoxDecoration(
          color: message.isFromUser ? TeaColors.freshLeaf : TeaColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isFromUser ? 16 : 4),
            bottomRight: Radius.circular(message.isFromUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: TeaColors.shadowVale,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TeaTypography.bodyMedium.copyWith(
                color: message.isFromUser ? Colors.white : TeaColors.nearBlack,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TeaTypography.labelSmall.copyWith(
                color: message.isFromUser
                    ? Colors.white.withOpacity(0.7)
                    : TeaColors.mediumGray,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: TeaSpacing.sm, right: 48),
        padding: const EdgeInsets.all(TeaSpacing.md),
        decoration: BoxDecoration(
          color: TeaColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: _BouncingDot(delay: index * 200),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: TeaSpacing.sm),
      child: ActionChip(
        label: Text(
          text,
          style: TeaTypography.labelSmall.copyWith(
            color: TeaColors.freshLeaf,
          ),
        ),
        backgroundColor: TeaColors.white,
        side: BorderSide(color: TeaColors.freshLeaf.withOpacity(0.3)),
        onPressed: () {
          _messageController.text = text;
          _sendMessage();
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isFromUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(seconds: 1, milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: _generateResponse(text),
            isFromUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    });
  }

  void _simulateVoiceInput() {
    _messageController.text = "Check my plant health status";
    _sendMessage();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _generateResponse(String query) {
    final lowerQuery = query.toLowerCase();

    if (lowerQuery.contains('disease') || lowerQuery.contains('detect')) {
      return "To detect leaf diseases, you can use our AI-powered scanner:\n\n1. Go to Disease Detection from the dashboard\n2. Take a clear photo of the affected leaf\n3. Wait for AI analysis\n\nCommon diseases I can identify include Blister Blight, Brown Blight, and Algal Leaf Spot. Would you like me to navigate you to the scanner?";
    }

    if (lowerQuery.contains('harvest') || lowerQuery.contains('when')) {
      return "Based on your plantation data, here are the harvest recommendations:\n\n- Block B2: Ready now (P+2 stage)\n- Block A1: Ready in 2-3 days\n- Block C3: Ready in 5-7 days\n\nThe optimal harvest time is early morning when moisture content is ideal. Would you like detailed timing for a specific block?";
    }

    if (lowerQuery.contains('soil') || lowerQuery.contains('condition')) {
      return "For optimal tea growth, maintain these soil conditions:\n\n- pH Level: 4.5 - 5.5 (acidic)\n- Organic matter: > 2%\n- Drainage: Well-drained\n- Temperature: 20-30°C\n\nYour current readings show optimal conditions in most blocks. Block D1 needs attention - nitrogen levels are slightly low.";
    }

    if (lowerQuery.contains('iot') || lowerQuery.contains('sensor')) {
      return "Your IoT system status:\n\n- 3 sensors online\n- Last sync: 5 minutes ago\n- Battery levels: Good\n\nTo add a new sensor:\n1. Go to IoT Devices\n2. Tap 'Add Device'\n3. Follow pairing instructions\n\nNeed help with a specific sensor?";
    }

    if (lowerQuery.contains('health') || lowerQuery.contains('status')) {
      return "Your plantation health overview:\n\n- Overall health score: 87%\n- Healthy plants: 94%\n- Disease detected: 2 blocks (A3, C1)\n- Harvest ready: 3 blocks\n\nI recommend checking Block A3 for blister blight symptoms. Would you like me to schedule a detailed scan?";
    }

    return "I understand you're asking about \"$query\". Here's what I can help with:\n\n- Disease detection and treatment plans\n- Plant growth monitoring\n- Harvest scheduling\n- Soil and weather analysis\n- IoT device management\n\nCould you please provide more details about what you need?";
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: TeaColors.white,
          borderRadius: TeaRadius.topXxl,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: TeaSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: TeaColors.mediumGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: TeaSpacing.lg),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Clear chat history'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _messages.clear();
                    _addWelcomeMessage();
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.volume_up_outlined),
                title: const Text('Enable voice responses'),
                trailing: Switch(
                  value: false,
                  onChanged: (value) {},
                  activeColor: TeaColors.freshLeaf,
                ),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & FAQ'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/help-center');
                },
              ),
              const SizedBox(height: TeaSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isFromUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isFromUser,
    required this.timestamp,
  });
}

class _BouncingDot extends StatefulWidget {
  final int delay;

  const _BouncingDot({required this.delay});

  @override
  State<_BouncingDot> createState() => _BouncingDotState();
}

class _BouncingDotState extends State<_BouncingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: TeaColors.freshLeaf,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
