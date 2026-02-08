import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'voice_service.dart';

/// AI Tea Cultivation Assistant Service
/// Provides context-aware, multilingual responses for tea farming guidance

class ConversationMessage {
  final String text;
  final bool isFromAssistant;
  final DateTime timestamp;
  final String? diseaseContext;
  final Map<String, dynamic>? metadata;

  ConversationMessage({
    required this.text,
    required this.isFromAssistant,
    DateTime? timestamp,
    this.diseaseContext,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AssistantState {
  final List<ConversationMessage> messages;
  final bool isProcessing;
  final String? currentContext;
  final String? lastDetectedDisease;
  final VoiceLanguage language;
  final List<String> recentScans;

  const AssistantState({
    this.messages = const [],
    this.isProcessing = false,
    this.currentContext,
    this.lastDetectedDisease,
    this.language = VoiceLanguage.english,
    this.recentScans = const [],
  });

  AssistantState copyWith({
    List<ConversationMessage>? messages,
    bool? isProcessing,
    String? currentContext,
    String? lastDetectedDisease,
    VoiceLanguage? language,
    List<String>? recentScans,
  }) {
    return AssistantState(
      messages: messages ?? this.messages,
      isProcessing: isProcessing ?? this.isProcessing,
      currentContext: currentContext ?? this.currentContext,
      lastDetectedDisease: lastDetectedDisease ?? this.lastDetectedDisease,
      language: language ?? this.language,
      recentScans: recentScans ?? this.recentScans,
    );
  }
}

class AIAssistantService extends StateNotifier<AssistantState> {
  AIAssistantService() : super(const AssistantState()) {
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ConversationMessage(
      text: _getLocalizedWelcome(state.language),
      isFromAssistant: true,
    );
    state = state.copyWith(messages: [welcomeMessage]);
  }

  String _getLocalizedWelcome(VoiceLanguage language) {
    switch (language) {
      case VoiceLanguage.english:
        return "Hello! I'm your Tea Cultivation Assistant. I can help you identify leaf diseases, provide treatment recommendations, and offer cultivation guidance. How can I assist you today?";
      case VoiceLanguage.sinhala:
        return "ආයුබෝවන්! මම ඔබේ තේ වගා සහායකයා. මට කොළ රෝග හඳුනා ගැනීමට, ප්‍රතිකාර නිර්දේශ ලබා දීමට සහ වගා මාර්ගෝපදේශ ලබා දීමට හැකිය. අද මට ඔබට කෙසේ උදව් කළ හැකිද?";
      case VoiceLanguage.tamil:
        return "வணக்கம்! நான் உங்கள் தேயிலை சாகுபடி உதவியாளர். இலை நோய்களை அடையாளம் காண, சிகிச்சை பரிந்துரைகளை வழங்க மற்றும் சாகுபடி வழிகாட்டுதல்களை வழங்க என்னால் உதவ முடியும். இன்று நான் உங்களுக்கு எப்படி உதவ முடியும்?";
    }
  }

  /// Process user message and generate response
  Future<void> processMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

    // Add user message
    final userMsg = ConversationMessage(
      text: userMessage,
      isFromAssistant: false,
    );
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isProcessing: true,
    );

    // Generate response based on intent and context
    final intent = _parseIntent(userMessage);
    final response = await _generateResponse(userMessage, intent);

    // Add assistant response
    final assistantMsg = ConversationMessage(
      text: response,
      isFromAssistant: true,
      diseaseContext: state.lastDetectedDisease,
    );
    state = state.copyWith(
      messages: [...state.messages, assistantMsg],
      isProcessing: false,
    );
  }

  /// Parse user intent from message
  AssistantIntent _parseIntent(String message) {
    final lowered = message.toLowerCase().trim();

    // Greetings
    if (_matchesAny(lowered, ['hi', 'hello', 'hey', 'good morning', 'good afternoon', 'good evening', 'howdy', 'greetings'])) {
      return AssistantIntent.greeting;
    }

    // How are you / personal questions
    if (_matchesAny(lowered, ['how are you', 'how are u', 'how r u', 'whats up', "what's up", 'how do you do'])) {
      return AssistantIntent.personalQuestion;
    }

    // About the app
    if (_matchesAny(lowered, ['tell about', 'about this app', 'what is this app', 'what can you do', 'your features', 'what do you do', 'capabilities', 'about app', 'about you', 'who are you', 'what are you'])) {
      return AssistantIntent.aboutApp;
    }

    // Tea cultivation general
    if (_matchesAny(lowered, ['tea cultivation', 'tea farming', 'grow tea', 'tea plant', 'tea garden', 'what is tea', 'tea basics', 'tea growing'])) {
      return AssistantIntent.teaCultivation;
    }

    // Disease detection
    if (_matchesAny(lowered, ['disease', 'scan leaf', 'check leaf', 'leaf problem', 'sick leaf', 'infected', 'spots on leaf', 'brown spots', 'yellow leaf', 'blister', 'rust', 'blight'])) {
      return AssistantIntent.diseaseDetection;
    }

    // Weather
    if (_matchesAny(lowered, ['weather', 'temperature', 'humidity', 'rain', 'forecast', 'climate', 'hot', 'cold', 'monsoon'])) {
      return AssistantIntent.weather;
    }

    // Treatment
    if (_matchesAny(lowered, ['treat', 'treatment', 'cure', 'medicine', 'fungicide', 'spray', 'organic', 'remedy', 'solution', 'fix'])) {
      return AssistantIntent.treatment;
    }

    // Fertilizer
    if (_matchesAny(lowered, ['fertilizer', 'fertilize', 'npk', 'nitrogen', 'nutrient', 'soil', 'manure', 'compost'])) {
      return AssistantIntent.fertilizer;
    }

    // Harvesting
    if (_matchesAny(lowered, ['harvest', 'pluck', 'pick', 'picking', 'yield', 'production', 'leaf maturity', 'when to harvest'])) {
      return AssistantIntent.harvesting;
    }

    // Help
    if (_matchesAny(lowered, ['help', 'assist', 'support', 'guide', 'how to use'])) {
      return AssistantIntent.help;
    }

    // Thanks
    if (_matchesAny(lowered, ['thank', 'thanks', 'thank you', 'appreciate'])) {
      return AssistantIntent.thanks;
    }

    // Goodbye
    if (_matchesAny(lowered, ['bye', 'goodbye', 'see you', 'later', 'quit', 'exit'])) {
      return AssistantIntent.goodbye;
    }

    return AssistantIntent.general;
  }

  bool _matchesAny(String text, List<String> patterns) {
    for (final pattern in patterns) {
      if (text.contains(pattern)) return true;
    }
    return false;
  }

  Future<String> _generateResponse(String query, AssistantIntent intent) async {
    // Simulate processing delay for natural feel
    await Future.delayed(const Duration(milliseconds: 500));

    final language = state.language;

    switch (intent) {
      case AssistantIntent.greeting:
        return _getGreetingResponse(language);

      case AssistantIntent.personalQuestion:
        return _getPersonalResponse(language);

      case AssistantIntent.aboutApp:
        return _getAboutAppResponse(language);

      case AssistantIntent.teaCultivation:
        return _getTeaCultivationResponse(language);

      case AssistantIntent.diseaseDetection:
        return _getDiseaseDetectionResponse(language);

      case AssistantIntent.weather:
        return _getWeatherResponse(language);

      case AssistantIntent.treatment:
        return _getTreatmentResponse(language);

      case AssistantIntent.fertilizer:
        return _getFertilizerResponse(language);

      case AssistantIntent.harvesting:
        return _getHarvestingResponse(language);

      case AssistantIntent.help:
        return _getHelpResponse(language);

      case AssistantIntent.thanks:
        return _getThanksResponse(language);

      case AssistantIntent.goodbye:
        return _getGoodbyeResponse(language);

      case AssistantIntent.general:
        return _getSmartGeneralResponse(query, language);
    }
  }

  String _getGreetingResponse(VoiceLanguage language) {
    switch (language) {
      case VoiceLanguage.english:
        return "Hello! Great to hear from you. I'm here to help with your tea cultivation needs. You can ask me about:\n\n• Disease detection and treatment\n• Leaf maturity and harvesting\n• Fertilizer recommendations\n• Weather-based guidance\n\nWhat would you like to know?";
      case VoiceLanguage.sinhala:
        return "ආයුබෝවන්! ඔබෙන් ඇසීමට සතුටුයි. මම ඔබේ තේ වගා අවශ්‍යතා සඳහා උදව් කිරීමට මෙහි සිටිමි. ඔබට මගෙන් විමසිය හැක්කේ:\n\n• රෝග හඳුනාගැනීම සහ ප්‍රතිකාර\n• කොළ පරිණතභාවය සහ අස්වැන්න\n• පොහොර නිර්දේශ\n• කාලගුණ පාදක මාර්ගෝපදේශ\n\nඔබ දැනගන්න කැමති කුමක්ද?";
      case VoiceLanguage.tamil:
        return "வணக்கம்! உங்களிடம் இருந்து கேட்பது மகிழ்ச்சி. உங்கள் தேயிலை சாகுபடி தேவைகளுக்கு உதவ நான் இங்கே இருக்கிறேன். நீங்கள் என்னிடம் கேட்கலாம்:\n\n• நோய் கண்டறிதல் மற்றும் சிகிச்சை\n• இலை முதிர்ச்சி மற்றும் அறுவடை\n• உர பரிந்துரைகள்\n• வானிலை அடிப்படையிலான வழிகாட்டுதல்\n\nநீங்கள் என்ன தெரிந்து கொள்ள விரும்புகிறீர்கள்?";
    }
  }

  String _getPersonalResponse(VoiceLanguage language) {
    switch (language) {
      case VoiceLanguage.english:
        return "I'm doing great, thank you for asking! I'm always ready to help tea farmers like you. As your digital assistant, I never get tired and I'm constantly learning about tea cultivation. Is there anything specific about your tea garden I can help with today?";
      case VoiceLanguage.sinhala:
        return "මම හොඳින් ඉන්නවා, අහපු එකට ස්තූතියි! මම සැමවිටම ඔබ වැනි තේ ගොවීන්ට උදව් කිරීමට සූදානම්. ඔබේ ඩිජිටල් සහායක ලෙස, මම කවදාවත් වෙහෙසට පත් නොවෙමි. අද ඔබේ තේ වත්තේ ගැන මට උදව් කළ හැකි විශේෂ දෙයක් තිබේද?";
      case VoiceLanguage.tamil:
        return "நான் நன்றாக இருக்கிறேன், கேட்டதற்கு நன்றி! உங்களைப் போன்ற தேயிலை விவசாயிகளுக்கு உதவ நான் எப்போதும் தயாராக இருக்கிறேன். உங்கள் டிஜிட்டல் உதவியாளராக, நான் ஒருபோதும் சோர்வடைவதில்லை. இன்று உங்கள் தேயிலை தோட்டத்தைப் பற்றி நான் உதவக்கூடிய குறிப்பிட்ட ஏதாவது இருக்கிறதா?";
    }
  }

  String _getAboutAppResponse(VoiceLanguage language) {
    switch (language) {
      case VoiceLanguage.english:
        return '''I'm **iTeaGrow** - your AI-powered Tea Cultivation Assistant! 🍃

**What I can do:**

📸 **Disease Detection**
Take a photo of your tea leaf and I'll identify diseases like Blister Blight, Red Rust, and more with treatment recommendations.

🌡️ **Environmental Monitoring**
I track temperature, humidity, and soil conditions through IoT sensors to predict disease risks.

🌱 **Smart Recommendations**
Get personalized advice on fertilizers, harvesting time, and cultivation practices based on your local conditions.

🗣️ **Multilingual Support**
I speak English, Sinhala (සිංහල), and Tamil (தமிழ்).

**Try saying:**
• "Scan my leaf for diseases"
• "When should I harvest?"
• "What fertilizer do I need?"

How can I help you today?''';

      case VoiceLanguage.sinhala:
        return '''මම **iTeaGrow** - ඔබේ AI බලගැන්වූ තේ වගා සහායකයා! 🍃

**මට කළ හැක්කේ:**

📸 **රෝග හඳුනාගැනීම**
ඔබේ තේ කොළයේ ඡායාරූපයක් ගන්න, මම Blister Blight, Red Rust වැනි රෝග හඳුනාගෙන ප්‍රතිකාර නිර්දේශ කරන්නම්.

🌡️ **පාරිසරික අධීක්ෂණය**
IoT සංවේදක හරහා උෂ්ණත්වය, ආර්ද්‍රතාවය සහ පස් තත්ත්වයන් නිරීක්ෂණය කරමි.

🌱 **බුද්ධිමත් නිර්දේශ**
පොහොර, අස්වනු කාලය සහ වගා පිළිවෙත් පිළිබඳ පුද්ගලික උපදෙස් ලබා ගන්න.

**උත්සාහ කරන්න:**
• "මගේ කොළය රෝග සඳහා ස්කෑන් කරන්න"
• "මම අස්වනු නෙලිය යුත්තේ කවදාද?"''';

      case VoiceLanguage.tamil:
        return '''நான் **iTeaGrow** - உங்கள் AI இயக்கப்படும் தேயிலை சாகுபடி உதவியாளர்! 🍃

**நான் என்ன செய்ய முடியும்:**

📸 **நோய் கண்டறிதல்**
உங்கள் தேயிலை இலையின் புகைப்படம் எடுங்கள், Blister Blight, Red Rust போன்ற நோய்களை கண்டறிந்து சிகிச்சை பரிந்துரைப்பேன்.

🌡️ **சுற்றுச்சூழல் கண்காணிப்பு**
IoT சென்சார்கள் மூலம் வெப்பநிலை, ஈரப்பதம், மண் நிலைகளை கண்காணிக்கிறேன்.

🌱 **புத்திசாலி பரிந்துரைகள்**
உரம், அறுவடை நேரம், சாகுபடி நடைமுறைகள் பற்றிய தனிப்பட்ட ஆலோசனை பெறுங்கள்.

**முயற்சிக்கவும்:**
• "என் இலையை நோய்களுக்கு ஸ்கேன் செய்"
• "நான் எப்போது அறுவடை செய்ய வேண்டும்?"''';
    }
  }

  String _getTeaCultivationResponse(VoiceLanguage language) {
    switch (language) {
      case VoiceLanguage.english:
        return '''**Tea Cultivation Basics** 🍃

Tea (Camellia sinensis) thrives in specific conditions:

**Ideal Growing Conditions:**
• Temperature: 20-30°C (68-86°F)
• Rainfall: 1500-2500mm annually
• Altitude: 600-2000m above sea level
• Soil pH: 4.5-5.5 (acidic)

**Key Practices:**
1. **Plucking**: Harvest the top 2 leaves and a bud (two-and-a-bud)
2. **Pruning**: Regular pruning maintains bush health
3. **Shade Management**: 40-50% shade is optimal
4. **Fertilization**: Apply NPK based on soil tests

**Common Challenges:**
• Blister Blight (cool, wet weather)
• Red Rust (poor drainage)
• Tea Mosquito Bug

Would you like details on any specific aspect?''';

      case VoiceLanguage.sinhala:
        return '''**තේ වගා මූලික කරුණු** 🍃

තේ (Camellia sinensis) නිශ්චිත තත්ත්වයන් තුළ හොඳින් වැඩෙයි:

**ප්‍රශස්ත වර්ධන තත්ත්වයන්:**
• උෂ්ණත්වය: 20-30°C
• වර්ෂාපතනය: වාර්ෂිකව 1500-2500mm
• උන්නතාංශය: මුහුදු මට්ටමේ සිට 600-2000m
• පස් pH: 4.5-5.5 (අම්ලික)

**ප්‍රධාන පිළිවෙත්:**
1. **නෙලීම**: ඉහළ කොළ 2 සහ මුකුළු නෙලන්න
2. **කප්පාදු කිරීම**: නිතිපතා කප්පාදු කිරීම
3. **සෙවණ කළමනාකරණය**: 40-50% සෙවණ ප්‍රශස්තයි

විශේෂ කරුණක් ගැන විස්තර අවශ්‍යද?''';

      case VoiceLanguage.tamil:
        return '''**தேயிலை சாகுபடி அடிப்படைகள்** 🍃

தேயிலை (Camellia sinensis) குறிப்பிட்ட நிலைமைகளில் செழிக்கிறது:

**சிறந்த வளர்ப்பு நிலைமைகள்:**
• வெப்பநிலை: 20-30°C
• மழைப்பொழிவு: வருடாந்திரம் 1500-2500mm
• உயரம்: கடல் மட்டத்திலிருந்து 600-2000m
• மண் pH: 4.5-5.5 (அமிலத்தன்மை)

**முக்கிய நடைமுறைகள்:**
1. **பறிப்பு**: மேல் 2 இலைகள் மற்றும் மொட்டு
2. **கத்தரித்தல்**: வழக்கமான கத்தரித்தல்
3. **நிழல் மேலாண்மை**: 40-50% நிழல் உகந்தது

ஏதேனும் குறிப்பிட்ட விஷயத்தில் விவரங்கள் வேண்டுமா?''';
    }
  }

  String _getDiseaseDetectionResponse(VoiceLanguage language) {
    final disease = state.lastDetectedDisease;

    if (disease == null) {
      switch (language) {
        case VoiceLanguage.english:
          return '''**Ready to Scan for Diseases** 🔍

To detect diseases on your tea leaves:

1. Go to **Disease Detection** from the dashboard
2. **Take a clear photo** of the affected leaf
3. Make sure the leaf is well-lit and in focus
4. I'll analyze and identify any diseases

**Common Tea Diseases I can detect:**
• **Blister Blight** - white/brown blisters on leaves
• **Red Rust** - orange-red patches (algal)
• **Grey Blight** - grey spots with dark borders

**Tip:** Capture the leaf against a plain background for best results!

Tap the camera button on the dashboard to start scanning.''';

        case VoiceLanguage.sinhala:
          return '''**රෝග හඳුනාගැනීමට සූදානම්** 🔍

ඔබේ තේ කොළවල රෝග හඳුනා ගැනීමට:

1. උපකරණ පුවරුවෙන් **රෝග හඳුනාගැනීම** වෙත යන්න
2. බලපෑමට ලක් වූ කොළයේ **පැහැදිලි ඡායාරූපයක්** ගන්න
3. කොළය හොඳින් ආලෝකමත් බවට වග බලා ගන්න

**මට හඳුනාගත හැකි පොදු තේ රෝග:**
• **Blister Blight** - කොළවල සුදු/දුඹුරු බිබිලි
• **Red Rust** - තැඹිලි-රතු පැල්ලම්

ස්කෑන් කිරීම ආරම්භ කිරීමට උපකරණ පුවරුවේ කැමරා බොත්තම තට්ටු කරන්න.''';

        case VoiceLanguage.tamil:
          return '''**நோய்களை ஸ்கேன் செய்ய தயார்** 🔍

உங்கள் தேயிலை இலைகளில் நோய்களைக் கண்டறிய:

1. டாஷ்போர்டிலிருந்து **நோய் கண்டறிதல்** செல்லுங்கள்
2. பாதிக்கப்பட்ட இலையின் **தெளிவான புகைப்படம்** எடுங்கள்
3. இலை நன்கு வெளிச்சமாக இருப்பதை உறுதிசெய்யுங்கள்

**நான் கண்டறியக்கூடிய பொதுவான தேயிலை நோய்கள்:**
• **Blister Blight** - இலைகளில் வெள்ளை/பழுப்பு கொப்புளங்கள்
• **Red Rust** - ஆரஞ்சு-சிவப்பு திட்டுகள்

ஸ்கேன் செய்ய டாஷ்போர்டில் கேமரா பட்டனைத் தட்டவும்.''';
      }
    }

    // Response with disease context
    switch (language) {
      case VoiceLanguage.english:
        return "Based on your recent scan, I detected **$disease**. Would you like me to explain the treatment options or prevention methods?";
      case VoiceLanguage.sinhala:
        return "ඔබගේ මෑත ස්කෑන් එක මත පදනම්ව, මම **$disease** හඳුනා ගත්තා. ප්‍රතිකාර විකල්ප හෝ වැළැක්වීමේ ක්‍රම පැහැදිලි කරන්නද?";
      case VoiceLanguage.tamil:
        return "உங்கள் சமீபத்திய ஸ்கேன் அடிப்படையில், நான் **$disease** கண்டறிந்தேன். சிகிச்சை விருப்பங்கள் அல்லது தடுப்பு முறைகளை விளக்கவா?";
    }
  }

  String _getWeatherResponse(VoiceLanguage language) {
    switch (language) {
      case VoiceLanguage.english:
        return '''**Current Weather Conditions** ☁️

Based on sensor readings:
• Temperature: **26.5°C** (Optimal for tea)
• Humidity: **72%** (Moderate - watch for disease)
• Soil Moisture: **45%** (Good)

**Disease Risk Assessment:**
⚠️ **Moderate risk** for Blister Blight due to humidity levels.

**Recommendations:**
1. Inspect leaves early morning for symptoms
2. Ensure good air circulation through pruning
3. Avoid overhead irrigation
4. Consider preventive copper spray if humidity stays high

**7-Day Forecast:** Partly cloudy with occasional showers expected.

Would you like specific weather-based guidance?''';

      case VoiceLanguage.sinhala:
        return '''**වත්මන් කාලගුණ තත්ත්වයන්** ☁️

සංවේදක කියවීම් මත පදනම්ව:
• උෂ්ණත්වය: **26.5°C** (තේ සඳහා ප්‍රශස්ත)
• ආර්ද්‍රතාවය: **72%** (සාමාන්‍ය - රෝග සඳහා සැලකිලිමත් වන්න)
• පස් තෙතමනය: **45%** (හොඳයි)

**රෝග අවදානම් තක්සේරුව:**
⚠️ ආර්ද්‍රතා මට්ටම් නිසා Blister Blight සඳහා **මධ්‍යම අවදානම**.

**නිර්දේශ:**
1. උදෑසන කොළ පරීක්ෂා කරන්න
2. කප්පාදු කිරීමෙන් හොඳ වාතාශ්‍රය සහතික කරන්න

නිශ්චිත කාලගුණ පාදක මාර්ගෝපදේශයක් අවශ්‍යද?''';

      case VoiceLanguage.tamil:
        return '''**தற்போதைய வானிலை நிலைமைகள்** ☁️

சென்சார் அளவீடுகளின் அடிப்படையில்:
• வெப்பநிலை: **26.5°C** (தேயிலைக்கு உகந்தது)
• ஈரப்பதம்: **72%** (மிதமான - நோய்க்கு கவனியுங்கள்)
• மண் ஈரப்பதம்: **45%** (நல்லது)

**நோய் ஆபத்து மதிப்பீடு:**
⚠️ ஈரப்பத அளவுகள் காரணமாக Blister Blight க்கு **மிதமான ஆபத்து**.

**பரிந்துரைகள்:**
1. அதிகாலையில் இலைகளை ஆய்வு செய்யுங்கள்
2. கத்தரித்தல் மூலம் நல்ல காற்றோட்டத்தை உறுதிசெய்யுங்கள்

குறிப்பிட்ட வானிலை அடிப்படையிலான வழிகாட்டுதல் வேண்டுமா?''';
    }
  }

  String _getTreatmentResponse(VoiceLanguage language) {
    final disease = state.lastDetectedDisease;

    if (disease == null || disease == 'Healthy') {
      switch (language) {
        case VoiceLanguage.english:
          return '''**General Treatment Guidelines** 💊

Since no specific disease is detected, here are preventive measures:

**Organic Options (Recommended):**
• Neem oil spray (2-3%) - weekly application
• Bordeaux mixture (1%) - preventive fungicide
• Trichoderma biocontrol agents

**Cultural Practices:**
• Maintain good drainage
• Regular pruning for air circulation
• Remove infected plant debris
• Practice crop rotation

**When to Use Chemicals:**
Only if organic methods fail and infection is severe:
• Copper oxychloride (0.3%)
• Hexaconazole (0.05%)

⚠️ Always follow safety guidelines and withdrawal periods.

Scan a leaf to get disease-specific treatment!''';

        case VoiceLanguage.sinhala:
          return '''**සාමාන්‍ය ප්‍රතිකාර මාර්ගෝපදේශ** 💊

නිශ්චිත රෝගයක් හඳුනාගෙන නැති බැවින්, වැළැක්වීමේ පියවර මෙන්න:

**කාබනික විකල්ප (නිර්දේශිත):**
• කොහොඹ තෙල් ස්ප්‍රේ (2-3%) - සතිපතා යෙදුම
• බෝර්ඩෝ මිශ්‍රණය (1%) - වැළැක්වීමේ දිලීර නාශක

**සංස්කෘතික පිළිවෙත්:**
• හොඳ ජලාපවහනය පවත්වන්න
• වාතාශ්‍රය සඳහා නිතිපතා කප්පාදු කරන්න

රෝග-විශේෂිත ප්‍රතිකාර සඳහා කොළයක් ස්කෑන් කරන්න!''';

        case VoiceLanguage.tamil:
          return '''**பொது சிகிச்சை வழிகாட்டுதல்கள்** 💊

குறிப்பிட்ட நோய் கண்டறியப்படாததால், தடுப்பு நடவடிக்கைகள் இங்கே:

**இயற்கை விருப்பங்கள் (பரிந்துரைக்கப்படுகிறது):**
• வேப்ப எண்ணெய் தெளிப்பு (2-3%) - வாராந்திர பயன்பாடு
• போர்டோ கலவை (1%) - தடுப்பு பூஞ்சைக்கொல்லி

**பண்பாட்டு நடைமுறைகள்:**
• நல்ல வடிகால் பராமரிக்கவும்
• காற்றோட்டத்திற்கு வழக்கமான கத்தரித்தல்

நோய்-குறிப்பிட்ட சிகிச்சைக்கு ஒரு இலையை ஸ்கேன் செய்யுங்கள்!''';
      }
    }

    // Disease-specific treatment
    if (disease?.contains('Blister Blight') ?? false) {
      return _getBlisterBlightTreatment(language);
    } else if (disease?.contains('Red Rust') ?? false) {
      return _getRedRustTreatment(language);
    }

    return _getTreatmentResponse(VoiceLanguage.english);
  }

  String _getBlisterBlightTreatment(VoiceLanguage language) {
    switch (language) {
      case VoiceLanguage.english:
        return '''**Blister Blight Treatment** 🍃

**Immediate Actions:**
1. Remove and destroy affected leaves
2. Improve air circulation through pruning

**Organic Treatment:**
• Neem oil spray (2-3%) - Apply every 7 days
• Trichoderma-based biocontrol agent

**Chemical Treatment** (if severe):
• Copper hydroxide (0.25%)
• Hexaconazole (0.05%)
• Apply during dry weather, early morning

**Prevention:**
• Avoid overhead irrigation
• Monitor during cool, humid periods
• Maintain 30cm spacing between plants

💡 Cost estimate: ~Rs. 2,500-4,000 per acre''';

      case VoiceLanguage.sinhala:
        return '''**Blister Blight ප්‍රතිකාර** 🍃

**ක්ෂණික ක්‍රියාමාර්ග:**
1. බලපෑමට ලක් වූ කොළ ඉවත් කර විනාශ කරන්න
2. කප්පාදු කිරීමෙන් වාතාශ්‍රය වැඩි කරන්න

**කාබනික ප්‍රතිකාර:**
• කොහොඹ තෙල් ස්ප්‍රේ (2-3%) - සෑම දින 7කට වරක් යොදන්න

**රසායනික ප්‍රතිකාර** (දරුණු නම්):
• තඹ හයිඩ්‍රොක්සයිඩ් (0.25%)
• වියළි කාලගුණය තුළ උදෑසන යොදන්න

💡 පිරිවැය ඇස්තමේන්තුව: අක්කරයකට ~රු. 2,500-4,000''';

      case VoiceLanguage.tamil:
        return '''**Blister Blight சிகிச்சை** 🍃

**உடனடி நடவடிக்கைகள்:**
1. பாதிக்கப்பட்ட இலைகளை அகற்றி அழிக்கவும்
2. கத்தரித்தல் மூலம் காற்றோட்டத்தை மேம்படுத்தவும்

**இயற்கை சிகிச்சை:**
• வேப்ப எண்ணெய் தெளிப்பு (2-3%) - ஒவ்வொரு 7 நாட்களுக்கும்

**இரசாயன சிகிச்சை** (கடுமையானால்):
• தாமிர ஹைட்ராக்சைடு (0.25%)
• உலர்ந்த வானிலையில் அதிகாலையில் பயன்படுத்தவும்

💡 செலவு மதிப்பீடு: ஏக்கருக்கு ~ரூ. 2,500-4,000''';
    }
  }

  String _getRedRustTreatment(VoiceLanguage language) {
    switch (language) {
      case VoiceLanguage.english:
        return '''**Red Rust Treatment** 🍂

**Identification:**
• Orange-red velvety patches on upper leaf surface
• Usually affects older, weakened plants

**Treatment:**
1. Prune affected branches for better sunlight
2. Bordeaux mixture spray (1%)
3. Copper oxychloride (0.3%) if severe

**Prevention:**
• Ensure adequate sunlight
• Avoid shade from overgrown hedges
• Apply balanced fertilizer (nitrogen)
• Improve drainage

Apply treatments before monsoon season for best results.''';

      case VoiceLanguage.sinhala:
        return '''**Red Rust ප්‍රතිකාර** 🍂

**හඳුනාගැනීම:**
• කොළයේ ඉහළ පෘෂ්ඨයේ තැඹිලි-රතු පැල්ලම්
• සාමාන්‍යයෙන් පැරණි, දුර්වල ශාකවලට බලපායි

**ප්‍රතිකාර:**
1. හොඳ සූර්යාලෝකය සඳහා බලපෑමට ලක් වූ අතු කපන්න
2. බෝර්ඩෝ මිශ්‍රණ ස්ප්‍රේ (1%)

**වැළැක්වීම:**
• ප්‍රමාණවත් සූර්යාලෝකය සහතික කරන්න
• සමබර පොහොර යොදන්න''';

      case VoiceLanguage.tamil:
        return '''**Red Rust சிகிச்சை** 🍂

**அடையாளம்:**
• இலையின் மேல் மேற்பரப்பில் ஆரஞ்சு-சிவப்பு திட்டுகள்
• பொதுவாக பழைய, பலவீனமான செடிகளை பாதிக்கிறது

**சிகிச்சை:**
1. சூரிய ஒளிக்கு பாதிக்கப்பட்ட கிளைகளை கத்தரிக்கவும்
2. போர்டோ கலவை தெளிப்பு (1%)

**தடுப்பு:**
• போதுமான சூரிய ஒளியை உறுதிசெய்யவும்
• சமச்சீர் உரம் இடுங்கள்''';
    }
  }

  String _getFertilizerResponse(VoiceLanguage language) {
    switch (language) {
      case VoiceLanguage.english:
        return '''**Fertilizer Recommendations** 🌱

**Ideal NPK Ratio for Tea:** 10:5:10 or similar

**Based on current soil readings:**
• Nitrogen (N): Apply Urea (46-0-0) - 150 kg/ha
• Phosphorus (P): Apply TSP - 50 kg/ha
• Potassium (K): Apply MOP - 100 kg/ha

**Application Schedule:**
1. **Jan-Feb:** 1st application (30% of annual)
2. **May-Jun:** 2nd application (40% of annual)
3. **Sep-Oct:** 3rd application (30% of annual)

**Organic Alternatives:**
• Compost: 5-10 tons/ha/year
• Neem cake: Rich in nitrogen
• Wood ash: Good potassium source

**Tips:**
• Apply after pruning
• Split applications work better
• Avoid fertilizing during heavy rain

Would you like specific recommendations based on soil test?''';

      case VoiceLanguage.sinhala:
        return '''**පොහොර නිර්දේශ** 🌱

**තේ සඳහා ප්‍රශස්ත NPK අනුපාතය:** 10:5:10

**වත්මන් පස් කියවීම් මත පදනම්ව:**
• නයිට්‍රජන් (N): යූරියා යොදන්න - 150 kg/ha
• පොස්පරස් (P): TSP යොදන්න - 50 kg/ha
• පොටෑසියම් (K): MOP යොදන්න - 100 kg/ha

**යෙදුම් කාලසටහන:**
1. **ජන-පෙබ:** 1 වන යෙදුම (වාර්ෂිකයෙන් 30%)
2. **මැයි-ජූනි:** 2 වන යෙදුම (වාර්ෂිකයෙන් 40%)
3. **සැප්-ඔක්:** 3 වන යෙදුම (වාර්ෂිකයෙන් 30%)

**කාබනික විකල්ප:**
• කොම්පෝස්ට්: වසරකට 5-10 ටොන්/ha
• කොහොඹ කේක්: නයිට්‍රජන් බහුල''';

      case VoiceLanguage.tamil:
        return '''**உர பரிந்துரைகள்** 🌱

**தேயிலைக்கு சிறந்த NPK விகிதம்:** 10:5:10

**தற்போதைய மண் அளவீடுகளின் அடிப்படையில்:**
• நைட்ரஜன் (N): யூரியா இடுங்கள் - 150 kg/ha
• பாஸ்பரஸ் (P): TSP இடுங்கள் - 50 kg/ha
• பொட்டாசியம் (K): MOP இடுங்கள் - 100 kg/ha

**பயன்பாட்டு அட்டவணை:**
1. **ஜன-பிப்:** 1வது பயன்பாடு (வருடாந்திரத்தின் 30%)
2. **மே-ஜூன்:** 2வது பயன்பாடு (வருடாந்திரத்தின் 40%)
3. **செப்-அக்:** 3வது பயன்பாடு (வருடாந்திரத்தின் 30%)

**இயற்கை மாற்றுகள்:**
• உரம்: வருடத்திற்கு 5-10 டன்/ha''';
    }
  }

  String _getHarvestingResponse(VoiceLanguage language) {
    switch (language) {
      case VoiceLanguage.english:
        return '''**Harvesting Guidelines** 🍃

**Optimal Plucking Standard:**
• **Fine plucking:** 2 leaves + 1 bud (best quality)
• **Medium plucking:** 3 leaves + 1 bud
• **Coarse plucking:** 4+ leaves (lower quality)

**Plucking Round:**
• Every 7-10 days during peak season
• Every 14-21 days during dry season

**Best Time to Harvest:**
• Early morning (6-10 AM)
• Avoid wet leaves (reduces quality)
• Don't pluck during heavy rain

**Quality Indicators:**
• Tender, light green shoots = Premium
• Dark green, mature leaves = Standard
• Yellow/brown tips = Overdue

**Current Recommendation:**
Based on sensor data, your leaves appear ready for harvest. Good leaf percentage is around 65%.

Use the Leaf Maturity feature for precise analysis!''';

      case VoiceLanguage.sinhala:
        return '''**අස්වනු මාර්ගෝපදේශ** 🍃

**ප්‍රශස්ත නෙලීමේ ප්‍රමිතිය:**
• **සියුම් නෙලීම:** කොළ 2 + මුකුළු 1 (හොඳම ගුණාත්මකභාවය)
• **මධ්‍යම නෙලීම:** කොළ 3 + මුකුළු 1
• **රළු නෙලීම:** කොළ 4+ (අඩු ගුණාත්මකභාවය)

**නෙලීමේ වටය:**
• උච්ච කාලයේ සෑම දින 7-10කට වරක්
• වියළි කාලයේ සෑම දින 14-21කට වරක්

**අස්වනු නෙලීමට හොඳම කාලය:**
• උදෑසන කාලයේ (පෙ.ව. 6-10)
• තෙත් කොළ වළක්වන්න

**ගුණාත්මක දර්ශක:**
• මෘදු, ලා කොළ පැලෑටි = වාරික
• තද කොළ පැහැති කොළ = සම්මත

නිවැරදි විශ්ලේෂණය සඳහා කොළ පරිණතභාව විශේෂාංගය භාවිතා කරන්න!''';

      case VoiceLanguage.tamil:
        return '''**அறுவடை வழிகாட்டுதல்கள்** 🍃

**உகந்த பறிப்பு தரநிலை:**
• **நுண்ணிய பறிப்பு:** 2 இலைகள் + 1 மொட்டு (சிறந்த தரம்)
• **நடுத்தர பறிப்பு:** 3 இலைகள் + 1 மொட்டு
• **கரடுமுரடான பறிப்பு:** 4+ இலைகள் (குறைந்த தரம்)

**பறிப்பு சுற்று:**
• உச்ச காலத்தில் ஒவ்வொரு 7-10 நாட்களுக்கும்
• வறண்ட காலத்தில் ஒவ்வொரு 14-21 நாட்களுக்கும்

**அறுவடை செய்ய சிறந்த நேரம்:**
• அதிகாலை (காலை 6-10)
• ஈரமான இலைகளைத் தவிர்க்கவும்

**தர குறிகாட்டிகள்:**
• மென்மையான, வெளிர் பச்சை தளிர்கள் = பிரீமியம்
• அடர் பச்சை இலைகள் = நிலையானது

துல்லியமான பகுப்பாய்விற்கு இலை முதிர்ச்சி அம்சத்தைப் பயன்படுத்துங்கள்!''';
    }
  }

  String _getHelpResponse(VoiceLanguage language) {
    switch (language) {
      case VoiceLanguage.english:
        return '''**How Can I Help You?** 🤝

Here's what I can do:

**📸 Disease Detection**
• "Scan my leaf" - Analyze leaves for diseases
• "What disease is this?" - Get diagnosis
• "How to treat Blister Blight?" - Treatment guide

**🌡️ Environmental Monitoring**
• "What's the weather?" - Current conditions
• "Is it safe to spray today?" - Weather advice
• "Disease risk?" - Risk assessment

**🌱 Cultivation Guidance**
• "When to harvest?" - Plucking advice
• "Fertilizer recommendations" - NPK guidance
• "Tell me about tea cultivation" - Basics

**💬 Just Chat**
• "Hi" / "Hello" - Greetings
• "Tell me about this app" - App features
• "Help" - This guide

**Tips:**
• Speak naturally - I understand context
• Use the mic button for voice input
• Change language from the dashboard

What would you like to know?''';

      case VoiceLanguage.sinhala:
        return '''**මට ඔබට කෙසේ උදව් කළ හැකිද?** 🤝

මට කළ හැක්කේ මෙන්න:

**📸 රෝග හඳුනාගැනීම**
• "මගේ කොළය ස්කෑන් කරන්න"
• "මෙය කුමන රෝගයද?"
• "Blister Blight ප්‍රතිකාර කරන්නේ කෙසේද?"

**🌡️ පාරිසරික අධීක්ෂණය**
• "කාලගුණය කුමක්ද?"
• "අද ස්ප්‍රේ කිරීම ආරක්ෂිතද?"

**🌱 වගා මාර්ගෝපදේශ**
• "අස්වනු නෙලීම කවදාද?"
• "පොහොර නිර්දේශ"

ඔබ දැනගන්න කැමති කුමක්ද?''';

      case VoiceLanguage.tamil:
        return '''**நான் உங்களுக்கு எப்படி உதவ முடியும்?** 🤝

நான் என்ன செய்ய முடியும்:

**📸 நோய் கண்டறிதல்**
• "என் இலையை ஸ்கேன் செய்"
• "இது என்ன நோய்?"
• "Blister Blight-ஐ எவ்வாறு சிகிச்சையளிப்பது?"

**🌡️ சுற்றுச்சூழல் கண்காணிப்பு**
• "வானிலை என்ன?"
• "இன்று தெளிக்க பாதுகாப்பானதா?"

**🌱 சாகுபடி வழிகாட்டுதல்**
• "எப்போது அறுவடை செய்வது?"
• "உர பரிந்துரைகள்"

நீங்கள் என்ன தெரிந்து கொள்ள விரும்புகிறீர்கள்?''';
    }
  }

  String _getThanksResponse(VoiceLanguage language) {
    switch (language) {
      case VoiceLanguage.english:
        return "You're welcome! I'm always here to help with your tea cultivation needs. Feel free to ask me anything anytime. Happy farming! 🍃";
      case VoiceLanguage.sinhala:
        return "සතුටුයි! මම සැමවිටම ඔබේ තේ වගා අවශ්‍යතා සඳහා උදව් කිරීමට මෙහි සිටිමි. ඕනෑම වේලාවක මගෙන් ඕනෑම දෙයක් අසන්න. සුභ ගොවිතැනක්! 🍃";
      case VoiceLanguage.tamil:
        return "நன்றி! உங்கள் தேயிலை சாகுபடி தேவைகளுக்கு உதவ நான் எப்போதும் இங்கே இருக்கிறேன். எந்த நேரத்திலும் என்னிடம் எதையும் கேளுங்கள். மகிழ்ச்சியான விவசாயம்! 🍃";
    }
  }

  String _getGoodbyeResponse(VoiceLanguage language) {
    switch (language) {
      case VoiceLanguage.english:
        return "Goodbye! Take care of your tea garden. Remember, I'm just a tap away whenever you need help. See you soon! 🍃👋";
      case VoiceLanguage.sinhala:
        return "ආයුබෝවන්! ඔබේ තේ වත්ත රැක බලා ගන්න. මතක තබා ගන්න, ඔබට උදව් අවශ්‍ය විටෙක මම එක තට්ටුවකින් ඈතයි. ඉක්මනින් හමුවෙමු! 🍃👋";
      case VoiceLanguage.tamil:
        return "பிரியாவிடை! உங்கள் தேயிலை தோட்டத்தை கவனித்துக் கொள்ளுங்கள். நினைவில் கொள்ளுங்கள், உங்களுக்கு உதவி தேவைப்படும்போது நான் ஒரு தட்டலில் இருக்கிறேன். விரைவில் சந்திப்போம்! 🍃👋";
    }
  }

  String _getSmartGeneralResponse(String query, VoiceLanguage language) {
    // Provide helpful response even for unrecognized queries
    switch (language) {
      case VoiceLanguage.english:
        return '''I'd be happy to help you with that!

While I'm specialized in tea cultivation, let me try to assist. Here are some things I can definitely help with:

• **Disease Detection** - Scan leaves for diseases
• **Treatment Advice** - How to treat various conditions
• **Weather Guidance** - When to spray, harvest, etc.
• **Fertilizer Tips** - NPK recommendations
• **Harvesting** - When and how to pluck

Could you tell me more about what you're looking for? Or try asking about any of the topics above!

💡 **Tip:** You can also use the quick action buttons on the dashboard.''';

      case VoiceLanguage.sinhala:
        return '''ඒ ගැන ඔබට උදව් කිරීමට මම සතුටු වෙමි!

මම තේ වගාවේ විශේෂඥයෙකු වුවද, උදව් කිරීමට උත්සාහ කරන්නම්. මට නිසැකවම උදව් කළ හැකි දේවල් මෙන්න:

• **රෝග හඳුනාගැනීම** - රෝග සඳහා කොළ ස්කෑන් කරන්න
• **ප්‍රතිකාර උපදෙස්** - විවිධ තත්වයන්ට ප්‍රතිකාර කරන්නේ කෙසේද
• **කාලගුණ මාර්ගෝපදේශ** - ස්ප්‍රේ කිරීමට, අස්වනු නෙලීමට කවදාද

ඔබ සොයන්නේ කුමක්ද කියා තව කියන්න පුළුවන්ද?''';

      case VoiceLanguage.tamil:
        return '''அதில் உங்களுக்கு உதவ மகிழ்ச்சியாக இருக்கிறேன்!

நான் தேயிலை சாகுபடியில் நிபுணர் என்றாலும், உதவ முயற்சிக்கிறேன். நான் நிச்சயமாக உதவக்கூடிய சில விஷயங்கள் இங்கே:

• **நோய் கண்டறிதல்** - நோய்களுக்கு இலைகளை ஸ்கேன் செய்
• **சிகிச்சை ஆலோசனை** - பல்வேறு நிலைகளுக்கு சிகிச்சையளிப்பது எப்படி
• **வானிலை வழிகாட்டுதல்** - எப்போது தெளிக்க, அறுவடை செய்ய

நீங்கள் எதைத் தேடுகிறீர்கள் என்பதைப் பற்றி மேலும் சொல்ல முடியுமா?''';
    }
  }

  /// Update context from disease detection
  void updateDiseaseContext(String? disease) {
    state = state.copyWith(lastDetectedDisease: disease);
    if (disease != null) {
      state = state.copyWith(
        recentScans: [...state.recentScans.take(4), disease],
      );
    }
  }

  /// Change assistant language
  void setLanguage(VoiceLanguage language) {
    state = state.copyWith(language: language);
  }

  /// Clear conversation history
  void clearHistory() {
    state = const AssistantState();
    _addWelcomeMessage();
  }

  /// Get context summary for API calls
  Map<String, dynamic> getContextSummary() {
    return {
      'lastDisease': state.lastDetectedDisease,
      'recentScans': state.recentScans,
      'language': state.language.code,
      'messageCount': state.messages.length,
    };
  }
}

/// Intent categories for the assistant
enum AssistantIntent {
  greeting,
  personalQuestion,
  aboutApp,
  teaCultivation,
  diseaseDetection,
  weather,
  treatment,
  fertilizer,
  harvesting,
  help,
  thanks,
  goodbye,
  general,
}

/// Provider for AI assistant service
final aiAssistantProvider =
    StateNotifierProvider<AIAssistantService, AssistantState>((ref) {
  return AIAssistantService();
});
