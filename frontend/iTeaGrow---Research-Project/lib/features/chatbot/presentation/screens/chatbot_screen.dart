import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import '../../../../core/api/api_config.dart';
import '../../../../core/design_system/design_system.dart';

// ─── Domain ───────────────────────────────────────────────────────────────────

enum _Domain {
  general(
    'General',
    Icons.chat_bubble_outline_rounded,
    null,
    null,
  ),
  soil(
    'Soil',
    Icons.eco_outlined,
    'soil',
    'pH • Nutrients • Moisture • Amendments',
  ),
  leaf(
    'Leaf',
    Icons.document_scanner_outlined,
    'leaf',
    'Disease Detection • Treatment • Harvest Readiness',
  ),
  climate(
    'Climate',
    Icons.cloud_outlined,
    'climate',
    'Temperature • Humidity • Rainfall • Risk Forecast',
  ),
  yield(
    'Yield',
    Icons.bar_chart_rounded,
    'yield',
    'Block Readiness • Flush Cycles • Forecasts',
  ),
  powder(
    'Powder',
    Icons.coffee_outlined,
    'powder',
    'Grading • Quality • Factory Standards',
  );

  final String label;
  final IconData icon;
  final String? contextType;
  final String? description;

  const _Domain(this.label, this.icon, this.contextType, this.description);
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<_ChatMessage> _messages = [];

  bool _isTyping = false;
  _Domain _activeDomain = _Domain.general;
  List<String> _suggestions = [];
  String? _streamingBuffer;
  http.Client? _streamClient;
  bool _showScrollFab = false;
  bool _sendPressed = false;

  static const _domainColors = {
    _Domain.general: Color(0xFF4CAF50),
    _Domain.soil: Color(0xFF795548),
    _Domain.leaf: Color(0xFF2E7D32),
    _Domain.climate: Color(0xFF1565C0),
    _Domain.yield: Color(0xFFE65100),
    _Domain.powder: Color(0xFF6D4C41),
  };

  static const _defaultSuggestions = {
    _Domain.general: [
      ('What is Red Rust disease?', Icons.pest_control_outlined),
      ('When should I harvest?', Icons.grass_outlined),
      ('Optimal soil conditions', Icons.science_outlined),
      ('IoT sensor setup', Icons.sensors_rounded),
    ],
    _Domain.soil: [
      ('My soil pH reading', Icons.water_drop_outlined),
      ('Improve nitrogen levels', Icons.eco_outlined),
      ('Best organic fertilizers', Icons.compost_outlined),
      ('Soil moisture too high?', Icons.opacity_outlined),
    ],
    _Domain.leaf: [
      ('Signs of Blister Blight?', Icons.pest_control_outlined),
      ('Treat Red Rust disease', Icons.healing_outlined),
      ('Harvest-ready leaf check', Icons.check_circle_outline),
      ('Fungicide schedule', Icons.science_outlined),
    ],
    _Domain.climate: [
      ('Disease risk from humidity', Icons.cloud_outlined),
      ('Protect from frost', Icons.ac_unit_outlined),
      ('Drought stress signs', Icons.wb_sunny_outlined),
      ('Rainfall and harvest timing', Icons.water_outlined),
    ],
    _Domain.yield: [
      ('Which blocks are ready?', Icons.location_on_outlined),
      ('Improve kg per hectare', Icons.trending_up_rounded),
      ('Flush cycle length', Icons.loop_rounded),
      ('Harvest labour planning', Icons.people_outline_rounded),
    ],
    _Domain.powder: [
      ('What makes BOPF grade?', Icons.coffee_outlined),
      ('Why is powder too dusty?', Icons.blur_on_outlined),
      ('Improve colour & brightness', Icons.palette_outlined),
      ('Field disease → factory grade', Icons.factory_outlined),
    ],
  };

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
    _fetchTeaFact();
    _loadSuggestions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _streamClient?.close();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final atBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 80;
    if (_showScrollFab == atBottom) {
      setState(() => _showScrollFab = !atBottom);
    }
  }

  void _addWelcomeMessage() {
    _messages.add(
      _ChatMessage(
        text: "Hello! I'm **iTeaBot** — your intelligent tea plantation assistant.\n\n"
            '🌱 **Soil** — pH, nutrients & moisture\n'
            '📸 **Leaf** — disease detection & treatment\n'
            '🌧️ **Climate** — weather & growth conditions\n'
            '📊 **Yield** — harvest planning & prediction\n'
            '☕ **Powder** — grading & quality standards\n\n'
            'Select a domain above or just ask me anything!',
        isFromUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _fetchTeaFact() async {
    try {
      final res = await http
          .get(Uri.parse(ApiConfig.chatbotFact))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final fact = (jsonDecode(res.body)['fact'] as String?) ?? '';
        if (mounted && fact.isNotEmpty) {
          setState(() {
            _messages.add(
              _ChatMessage(
                text: fact,
                isFromUser: false,
                timestamp: DateTime.now(),
                isFactCard: true,
              ),
            );
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadSuggestions() async {
    try {
      final url = Uri.parse(
        '${ApiConfig.chatbotSuggestions}?context_type=${_activeDomain.contextType ?? ""}',
      );
      final response =
          await http.post(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['suggestions'] as List?)?.cast<String>() ?? [];
        if (mounted) setState(() => _suggestions = list);
      }
    } catch (_) {}
  }

  void _switchDomain(_Domain domain) {
    if (_activeDomain == domain) return;
    setState(() {
      _activeDomain = domain;
      _suggestions = [];
    });
    _loadSuggestions();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0F5F1), Color(0xFFEBF2EC), Color(0xFFF6F9F7)],
          ),
        ),
        child: Column(
          children: [
            _buildAppBar(),
            _buildDomainTabs(),
            _buildDomainBanner(),
            Expanded(
              child: Stack(
                children: [
                  // Ambient background orb
                  Positioned(
                    top: -60,
                    right: -40,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _domainColor.withOpacity(0.07),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: -60,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _domainColor.withOpacity(0.04),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Message list
                  ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _messages.length +
                        (_isTyping ? 1 : 0) +
                        (_streamingBuffer != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isTyping && index == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      final streamIdx =
                          _messages.length + (_isTyping ? 1 : 0);
                      if (_streamingBuffer != null && index == streamIdx) {
                        return _buildStreamingBubble(_streamingBuffer!);
                      }
                      final msg = _messages[index];
                      return msg.isFactCard
                          ? _buildFactCard(msg)
                          : _buildMessageBubble(msg);
                    },
                  ),
                  // Scroll-to-bottom FAB
                  if (_showScrollFab)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: _scrollToBottom,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _domainColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _domainColor.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      )
                          .animate()
                          .scale(duration: 180.ms, curve: Curves.elasticOut),
                    ),
                ],
              ),
            ),
            if (_messages.length <= 3) _buildSuggestions(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Color get _domainColor =>
      _domainColors[_activeDomain] ?? TeaColors.freshLeaf;

  // ─── App Bar ───────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F9F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: TeaColors.nearBlack,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_domainColor, _domainColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _domainColor.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(_activeDomain.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'iTeaBot',
                        style: TeaTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _domainColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _activeDomain.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _domainColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _PulsingDot(
                        color: _isTyping
                            ? TeaColors.warningAmber
                            : TeaColors.healthyGreen,
                        pulse: _isTyping,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isTyping ? 'Thinking...' : 'Online',
                        style: TeaTypography.labelSmall.copyWith(
                          color: _isTyping
                              ? TeaColors.warningAmber
                              : TeaColors.healthyGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _showChatOptions,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F9F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.more_vert_rounded,
                  color: TeaColors.nearBlack,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Domain Tabs ───────────────────────────────────────────────────────────

  Widget _buildDomainTabs() {
    return Container(
      color: Colors.white.withOpacity(0.92),
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: _Domain.values.map((domain) {
            final isActive = domain == _activeDomain;
            final color = _domainColors[domain] ?? TeaColors.freshLeaf;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _switchDomain(domain),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? color : color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        domain.icon,
                        size: 14,
                        color: isActive ? Colors.white : color,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        domain.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  // ─── Domain Banner ─────────────────────────────────────────────────────────

  Widget _buildDomainBanner() {
    final desc = _activeDomain.description;
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: desc == null
          ? const SizedBox(width: double.infinity)
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Container(
                key: ValueKey(_activeDomain),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _domainColor.withOpacity(0.07),
                  border: Border(
                    bottom: BorderSide(
                      color: _domainColor.withOpacity(0.12),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(_activeDomain.icon, size: 13, color: _domainColor),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        desc,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _domainColor,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── Tea Fact Card ─────────────────────────────────────────────────────────

  Widget _buildFactCard(_ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2E7D32).withOpacity(0.92),
              const Color(0xFF4A7C59).withOpacity(0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circle
            Positioned(
              top: -18,
              right: -18,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Did you know? ☕',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.75),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message.text,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 200.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms, delay: 200.ms);
  }

  // ─── Message Bubble ────────────────────────────────────────────────────────

  Widget _buildMessageBubble(_ChatMessage message) {
    final isUser = message.isFromUser;
    final color = _domainColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(_activeDomain.icon, color: Colors.white, size: 14),
            ),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: isUser
                  ? null
                  : () => _copyMessage(message.text),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? color : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 6),
                    bottomRight: Radius.circular(isUser ? 6 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isUser
                          ? color.withOpacity(0.2)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MessageText(
                      text: message.text,
                      color: isUser ? Colors.white : TeaColors.nearBlack,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!isUser)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.copy_outlined,
                              size: 9,
                              color: TeaColors.mediumGray.withOpacity(0.5),
                            ),
                          ),
                        const Expanded(child: SizedBox()),
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: isUser
                                ? Colors.white.withOpacity(0.6)
                                : TeaColors.mediumGray,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.08, end: 0);
  }

  void _copyMessage(String text) {
    // Strip markdown bold markers for clipboard
    final plain = text.replaceAll('**', '');
    Clipboard.setData(ClipboardData(text: plain));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: _domainColor, size: 16),
            const SizedBox(width: 8),
            const Text('Copied to clipboard'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
        elevation: 4,
      ),
    );
  }

  // ─── Streaming Bubble ──────────────────────────────────────────────────────

  Widget _buildStreamingBubble(String text) {
    final color = _domainColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8, bottom: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(_activeDomain.icon, color: Colors.white, size: 14),
          ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: text.isEmpty
                  ? _buildShimmerPlaceholder()
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: _MessageText(
                            text: text,
                            color: TeaColors.nearBlack,
                          ),
                        ),
                        const SizedBox(width: 3),
                        _BlinkingCursor(color: color),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 11,
            width: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 11,
            width: 130,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Typing Indicator ──────────────────────────────────────────────────────

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_domainColor, _domainColor.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_activeDomain.icon, color: Colors.white, size: 14),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (index) => _BouncingDot(delay: index * 200, color: _domainColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Suggestions ───────────────────────────────────────────────────────────

  Widget _buildSuggestions() {
    final apiSuggestions = _suggestions;
    final defaultList =
        _defaultSuggestions[_activeDomain] ?? _defaultSuggestions[_Domain.general]!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: apiSuggestions.isNotEmpty
              ? apiSuggestions
                  .take(5)
                  .map(
                    (s) => _buildSuggestionChip(s, Icons.help_outline_rounded),
                  )
                  .toList()
              : defaultList
                  .map((s) => _buildSuggestionChip(s.$1, s.$2))
                  .toList(),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 200.ms);
  }

  Widget _buildSuggestionChip(String text, IconData icon) {
    final color = _domainColor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          _messageController.text = text;
          _sendMessage();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                text,
                style: TeaTypography.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Input Area ────────────────────────────────────────────────────────────

  Widget _buildInputArea() {
    final color = _domainColor;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F5F1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: color.withOpacity(0.12),
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    style: TeaTypography.bodyMedium,
                    decoration: InputDecoration(
                      hintText:
                          'Ask iTeaBot about ${_activeDomain.label.toLowerCase()}...',
                      hintStyle: TeaTypography.bodyMedium
                          .copyWith(color: TeaColors.mediumGray),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Animated send button
              GestureDetector(
                onTapDown: (_) => setState(() => _sendPressed = true),
                onTapUp: (_) {
                  setState(() => _sendPressed = false);
                  _sendMessage();
                },
                onTapCancel: () => setState(() => _sendPressed = false),
                child: AnimatedScale(
                  scale: _sendPressed ? 0.88 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color, color.withOpacity(0.75)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(_sendPressed ? 0.15 : 0.35),
                          blurRadius: _sendPressed ? 4 : 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Logic ─────────────────────────────────────────────────────────────────

  String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final history = _messages
        .where((m) => !m.isFactCard)
        .map(
          (m) => {
            'role': m.isFromUser ? 'user' : 'assistant',
            'content': m.text,
          },
        )
        .toList();

    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          isFromUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _messageController.clear();
      _isTyping = true;
      _streamingBuffer = null;
    });

    _scrollToBottom();
    _fetchBotResponseStream(text, history);
  }

  Future<void> _fetchBotResponseStream(
    String userMessage,
    List<Map<String, String>> history,
  ) async {
    _streamClient?.close();
    _streamClient = http.Client();

    try {
      final request = http.Request(
        'POST',
        Uri.parse(ApiConfig.chatbotChatStream),
      );
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'text/event-stream';
      request.body = jsonEncode({
        'message': userMessage,
        'conversation_history': history,
        'context_type': _activeDomain.contextType,
      });

      final streamed = await _streamClient!
          .send(request)
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        _addLocalResponse(userMessage);
        return;
      }

      setState(() {
        _isTyping = false;
        _streamingBuffer = '';
      });

      final buffer = StringBuffer();
      await streamed.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .forEach((line) {
        if (!line.startsWith('data: ')) return;
        final payload = line.substring(6).trim();
        if (payload.isEmpty) return;
        try {
          final chunk = jsonDecode(payload) as Map<String, dynamic>;
          if (chunk['done'] == true) return;
          final token = (chunk['token'] as String?) ?? '';
          if (token.isNotEmpty) {
            buffer.write(token);
            if (mounted) {
              setState(() => _streamingBuffer = buffer.toString());
              _scrollToBottom();
            }
          }
        } catch (_) {}
      });

      if (!mounted) return;
      setState(() {
        _streamingBuffer = null;
        _messages.add(
          _ChatMessage(
            text: buffer.toString(),
            isFromUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    } catch (_) {
      if (mounted) _addLocalResponse(userMessage);
    } finally {
      _streamClient = null;
      _scrollToBottom();
    }
  }

  void _addLocalResponse(String query) {
    setState(() {
      _isTyping = false;
      _messages.add(
        _ChatMessage(
          text: _localFallback(query),
          isFromUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
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

  String _localFallback(String query) {
    switch (_activeDomain) {
      case _Domain.soil:
        return 'For healthy tea soil:\n\n• pH: 4.5–5.5 (acidic)\n• Moisture: 40–70%\n• Apply compost every 3 months\n• Test N, P, K levels seasonally\n\nConnect your IoT sensors for live readings!';
      case _Domain.leaf:
        return 'Common tea diseases:\n\n🔴 **Red Rust** — copper fungicide, improve airflow\n🟤 **Blister Blight** — spray every 7–10 days in wet season\n\nUse the Disease Scanner for real-time AI analysis!';
      case _Domain.climate:
        return 'Ideal tea climate:\n\n• Temperature: 20–30°C\n• Humidity: 50–70%\n• Rainfall: 1,500–2,500mm/year\n\nHigh humidity (>80%) raises Blister Blight risk.';
      case _Domain.yield:
        return 'Harvest planning tips:\n\n• Harvest at P+2 stage (two leaves + bud)\n• Flush cycle: every 7–10 days during season\n• Early morning plucking keeps quality high';
      case _Domain.powder:
        return 'Tea powder grades:\n\n• **BOPF** — most common export grade\n• **BOP** — broken orange pekoe\n• **Dust 1** — finest, used in tea bags\n\nField disease below 5% is key to maintaining grade.';
      default:
        return 'I can help with disease detection, soil health, climate insights, yield planning, and powder grading.\n\nSelect a domain above or describe your question in more detail!';
    }
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: TeaColors.alertRust.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: TeaColors.alertRust,
                    size: 18,
                  ),
                ),
                title: const Text('Clear chat history'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _messages.clear();
                    _addWelcomeMessage();
                    _fetchTeaFact();
                  });
                },
              ),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: TeaColors.infoSky.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.help_outline_rounded,
                    color: TeaColors.infoSky,
                    size: 18,
                  ),
                ),
                title: const Text('Help & FAQ'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/help-center');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Message Text ─────────────────────────────────────────────────────────────

class _MessageText extends StatelessWidget {
  final String text;
  final Color color;

  const _MessageText({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
            fontWeight: i.isOdd ? FontWeight.w700 : FontWeight.normal,
            color: color,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      );
    }
    return RichText(
      text: TextSpan(children: spans),
    );
  }
}

// ─── Data Model ───────────────────────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isFromUser;
  final DateTime timestamp;
  final bool isFactCard;

  _ChatMessage({
    required this.text,
    required this.isFromUser,
    required this.timestamp,
    this.isFactCard = false,
  });
}

// ─── Pulsing Status Dot ───────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  final Color color;
  final bool pulse;

  const _PulsingDot({required this.color, required this.pulse});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _anim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.pulse) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulsingDot old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.pulse) {
      _ctrl.stop();
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(_anim.value),
        ),
      ),
    );
  }
}

// ─── Blinking Cursor ─────────────────────────────────────────────────────────

class _BlinkingCursor extends StatefulWidget {
  final Color color;

  const _BlinkingCursor({required this.color});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 2,
        height: 14,
        margin: const EdgeInsets.only(bottom: 1),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

// ─── Bouncing Dot ─────────────────────────────────────────────────────────────

class _BouncingDot extends StatefulWidget {
  final int delay;
  final Color color;

  const _BouncingDot({required this.delay, required this.color});

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
    _animation = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
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
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _animation.value),
        child: Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
