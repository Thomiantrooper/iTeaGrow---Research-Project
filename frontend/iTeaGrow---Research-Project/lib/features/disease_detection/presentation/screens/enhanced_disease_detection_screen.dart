import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../../core/theme/jarvis_theme.dart';
import '../../../../core/widgets/hologram_card.dart';
import '../../../../core/widgets/floating_tea_leaf.dart';
import '../../../../core/widgets/jarvis_assistant.dart';
import '../../../../core/services/ai_assistant_service.dart';
import '../../../../core/services/voice_service.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../data/datasources/disease_detection_ml_service.dart';
import '../../data/datasources/disease_storage_service.dart';
import '../../domain/entities/disease_detection_result.dart';

class EnhancedDiseaseDetectionScreen extends ConsumerStatefulWidget {
  const EnhancedDiseaseDetectionScreen({super.key});

  @override
  ConsumerState<EnhancedDiseaseDetectionScreen> createState() =>
      _EnhancedDiseaseDetectionScreenState();
}

class _EnhancedDiseaseDetectionScreenState
    extends ConsumerState<EnhancedDiseaseDetectionScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final DiseaseDetectionMLService _mlService = DiseaseDetectionMLService();
  final DiseaseStorageService _storageService = DiseaseStorageService();

  XFile? _selectedImage;
  Uint8List? _imageBytes;
  DiseaseDetectionResult? _result;
  bool _isProcessing = false;
  bool _showGradCam = false;
  bool _isBackendConnected = false;
  bool _isCheckingConnection = true;
  bool _savedToDb = false;
  bool _isSavingToDb = false;

  // Live readings
  double _temp = 26.5;
  double _humidity = 72.0;

  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _startLiveUpdates();

    _scanController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeService() async {
    setState(() => _isCheckingConnection = true);
    await _mlService.initialize();
    setState(() {
      _isBackendConnected = _mlService.isBackendAvailable;
      _isCheckingConnection = false;
    });
  }

  void _startLiveUpdates() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _temp += (DateTime.now().millisecond % 10 - 5) * 0.05;
          _humidity += (DateTime.now().millisecond % 10 - 5) * 0.1;
        });
        _startLiveUpdates();
      }
    });
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _selectedImage = photo;
          _imageBytes = bytes;
          _result = null;
          _savedToDb = false;
        });
      }
    } catch (e) {
      _showError('Camera error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _imageBytes = bytes;
          _result = null;
          _savedToDb = false;
        });
      }
    } catch (e) {
      _showError('Gallery error: $e');
    }
  }

  Future<void> _analyzeImage() async {
    print('');
    print('************************************************************');
    print('******* ENHANCED SCREEN _analyzeImage() STARTED ***********');
    print('************************************************************');
    print('');

    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _savedToDb = false;
    });
    _scanController.repeat();

    try {
      print('>>> EnhancedScreen: Calling _mlService.predict() <<<');
      final result = await _mlService.predict(
        _selectedImage!.path,
        liveTemperature: _temp,
        liveHumidity: _humidity,
      );

      // IMMEDIATELY print after predict returns
      print('########## PREDICT RETURNED ##########');
      print('Disease: ${result.diseaseType}');
      print('Confidence: ${result.confidence}');
      print('######################################');

      setState(() {
        _result = result;
        _isProcessing = false;
        _isBackendConnected = _mlService.isBackendAvailable;
      });
      _scanController.stop();
      _scanController.reset();

      // Update AI assistant context
      ref.read(aiAssistantProvider.notifier).updateDiseaseContext(result.diseaseType);

      // Speak result if voice is enabled - SKIP for now to avoid issues
      // final voiceService = ref.read(voiceServiceProvider.notifier);
      // if (result.diseaseType != 'Healthy' && !result.isNotALeaf) {
      //   voiceService.speak(
      //     'I detected ${result.diseaseType} with ${(result.confidence * 100).toStringAsFixed(0)}% confidence. '
      //     'The severity is ${result.severity}. Would you like treatment recommendations?',
      //   );
      // }

      // Auto-save to database if connected and valid leaf
      print('########## CHECKING SAVE CONDITIONS ##########');
      print('_isBackendConnected: $_isBackendConnected');
      print('result.isNotALeaf: ${result.isNotALeaf}');
      print('##############################################');

      if (_isBackendConnected && !result.isNotALeaf) {
        print('########## CALLING SAVE ##########');
        _saveToDatabase();
      } else {
        print('########## NOT SAVING ##########');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _scanController.stop();
      _showError('Analysis error: $e');
    }
  }

  Future<void> _saveToDatabase() async {
    print('=== EnhancedScreen: SAVE TO DATABASE CALLED ===');
    if (_result == null || _selectedImage == null || _savedToDb) {
      print('!!! Early return - conditions not met');
      return;
    }

    setState(() => _isSavingToDb = true);

    try {
      // Get auth token from Riverpod state
      final authState = ref.read(authStateProvider);
      final authToken = authState.accessToken;
      print('Auth state: isAuthenticated=${authState.isAuthenticated}');
      print('Auth token present: ${authToken != null && authToken.isNotEmpty}');
      print('Image path: ${_selectedImage!.path}');

      if (authToken == null || authToken.isEmpty) {
        print('!!! No auth token - showing login message');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Please log in to save scans to database'),
                ],
              ),
              backgroundColor: JarvisTheme.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _isSavingToDb = false);
        return;
      }

      print('>>> Calling _storageService.saveDetectionWithImage() <<<');
      final savedResult = await _storageService.saveDetectionWithImage(
        result: _result!,
        imagePath: _selectedImage!.path,
        authToken: authToken,
      );

      if (savedResult != null) {
        print('>>> Detection saved successfully! <<<');
        setState(() {
          _savedToDb = true;
          _isSavingToDb = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Scan saved to database'),
                ],
              ),
              backgroundColor: JarvisTheme.healthy,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        print('!!! Failed to save detection');
        setState(() => _isSavingToDb = false);
      }
    } catch (e) {
      print('!!! Error saving to database: $e');
      setState(() => _isSavingToDb = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: JarvisTheme.critical,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JarvisTheme.mistWhite,
      body: Stack(
        children: [
          // Background decoration
          const FloatingLeavesBackground(leafCount: 3, showDiseased: true),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // App Bar
                _buildAppBar(),

                // Content
                SliverPadding(
                  padding: const EdgeInsets.all(JarvisTheme.spacingMd),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Live Environment Status
                      _buildEnvironmentCard(),
                      const SizedBox(height: JarvisTheme.spacingLg),

                      // Image Section
                      _buildImageSection(),
                      const SizedBox(height: JarvisTheme.spacingLg),

                      // Action Buttons
                      if (_selectedImage == null) _buildCaptureButtons(),
                      if (_selectedImage != null && _result == null)
                        _buildAnalyzeButton(),

                      // Results
                      if (_result != null) ...[
                        const SizedBox(height: JarvisTheme.spacingLg),
                        _buildResultCard(),
                        const SizedBox(height: JarvisTheme.spacingMd),
                        _buildRecommendationsCard(),
                      ],

                      const SizedBox(height: JarvisTheme.spacingXxl),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 70,
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [JarvisTheme.critical, JarvisTheme.critical.withOpacity(0.8)],
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(JarvisTheme.radiusXl),
            ),
          ),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bug_report, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'Disease Detection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Connection status
        IconButton(
          icon: _isCheckingConnection
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  _isBackendConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: _isBackendConnected ? JarvisTheme.healthy : Colors.orange,
                ),
          onPressed: _initializeService,
        ),
      ],
    );
  }

  Widget _buildEnvironmentCard() {
    return HologramCard(
      enableGlow: false,
      padding: const EdgeInsets.all(JarvisTheme.spacingMd),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.sensors, color: Colors.white, size: 20),
          ),
          const SizedBox(width: JarvisTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live Environment',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: JarvisTheme.textPrimary,
                  ),
                ),
                Text(
                  'Real-time sensor data',
                  style: TextStyle(
                    fontSize: 12,
                    color: JarvisTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          _buildMetricChip(Icons.thermostat, '${_temp.toStringAsFixed(1)}°C', Colors.deepOrange),
          const SizedBox(width: 8),
          _buildMetricChip(Icons.water_drop, '${_humidity.toStringAsFixed(0)}%', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    if (_selectedImage == null) {
      return _buildImagePlaceholder();
    }
    return _buildImagePreview();
  }

  Widget _buildImagePlaceholder() {
    return HologramCard(
      enableGlow: true,
      glowColor: JarvisTheme.teaGreen,
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              JarvisTheme.teaGreen.withOpacity(0.05),
              JarvisTheme.hologramGreen.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(JarvisTheme.radiusLg),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: JarvisTheme.teaGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: DiseaseIndicatorLeaf(
                diseaseType: 'None',
                severity: 0,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Capture Tea Leaf',
              style: TextStyle(
                color: JarvisTheme.teaGreen,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Take a photo or select from gallery to detect diseases',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: JarvisTheme.textMuted,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return HologramCard(
      enableGlow: _result != null,
      glowColor: _result != null
          ? (_result!.diseaseType == 'Healthy'
              ? JarvisTheme.healthy
              : JarvisTheme.critical)
          : JarvisTheme.teaGreen,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(JarvisTheme.radiusLg),
            child: Image.memory(
              _imageBytes!,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // Scanning overlay
          if (_isProcessing)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _scanAnimation,
                builder: (context, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(JarvisTheme.radiusLg),
                    child: CustomPaint(
                      painter: ScanLinePainter(
                        progress: _scanAnimation.value,
                        color: JarvisTheme.hologramGreen,
                      ),
                    ),
                  );
                },
              ),
            ),

          // Grad-CAM overlay
          if (_showGradCam && _result != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(JarvisTheme.radiusLg),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.8,
                      colors: [
                        JarvisTheme.critical.withOpacity(0.4),
                        JarvisTheme.warning.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Controls
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              children: [
                if (_result != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Grad-CAM',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Switch(
                          value: _showGradCam,
                          onChanged: (v) => setState(() => _showGradCam = v),
                          activeColor: JarvisTheme.hologramGreen,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedImage = null;
                    _imageBytes = null;
                    _result = null;
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButtons() {
    return Row(
      children: [
        Expanded(
          child: HologramCard(
            onTap: _captureImage,
            glowColor: JarvisTheme.teaGreen,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: JarvisTheme.teaGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: JarvisTheme.teaGreen,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Camera',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: JarvisTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: JarvisTheme.spacingMd),
        Expanded(
          child: HologramCard(
            onTap: _pickFromGallery,
            glowColor: JarvisTheme.softGold,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: JarvisTheme.softGold.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: JarvisTheme.softGold,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Gallery',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: JarvisTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    return HologramCard(
      onTap: _isProcessing ? null : _analyzeImage,
      enableGlow: !_isProcessing,
      glowColor: JarvisTheme.hologramGreen,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: JarvisTheme.primaryGradient,
          borderRadius: BorderRadius.circular(JarvisTheme.radiusMd),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isProcessing)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white.withOpacity(0.9),
                ),
              )
            else
              const Icon(Icons.search, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              _isProcessing ? 'Analyzing...' : 'Analyze Leaf',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final isHealthy = _result!.diseaseType == 'Healthy';
    final isNotALeaf = _result!.isNotALeaf;

    Color statusColor;
    IconData statusIcon;
    if (isNotALeaf) {
      statusColor = JarvisTheme.textMuted;
      statusIcon = Icons.error_outline;
    } else if (isHealthy) {
      statusColor = JarvisTheme.healthy;
      statusIcon = Icons.check_circle;
    } else {
      statusColor = JarvisTheme.critical;
      statusIcon = Icons.warning_rounded;
    }

    return HologramCard(
      enableGlow: true,
      glowColor: statusColor,
      child: Column(
        children: [
          // Status Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(statusIcon, color: statusColor, size: 30),
              ),
              const SizedBox(width: JarvisTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isNotALeaf ? 'Detection Result' : 'Disease Status',
                      style: TextStyle(
                        fontSize: 12,
                        color: JarvisTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isNotALeaf ? 'Invalid Image' : _result!.diseaseType,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Disease indicator leaf
              if (!isNotALeaf)
                DiseaseIndicatorLeaf(
                  diseaseType: _result!.diseaseType,
                  severity: _result!.severity == 'High'
                      ? 0.9
                      : _result!.severity == 'Medium'
                          ? 0.5
                          : 0.2,
                  size: 50,
                ),
            ],
          ),

          if (!isNotALeaf) ...[
            const SizedBox(height: JarvisTheme.spacingLg),

            // Confidence meter
            StatusRing(
              size: 100,
              progress: _result!.confidence,
              color: statusColor,
              strokeWidth: 10,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(_result!.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const Text(
                    'Confidence',
                    style: TextStyle(
                      fontSize: 10,
                      color: JarvisTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            if (!isHealthy) ...[
              const SizedBox(height: JarvisTheme.spacingMd),

              // Severity
              Container(
                padding: const EdgeInsets.all(JarvisTheme.spacingMd),
                decoration: BoxDecoration(
                  color: _getSeverityColor(_result!.severity).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(JarvisTheme.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Severity Level',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: JarvisTheme.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(_result!.severity),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _result!.severity,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          // Invalid image message
          if (isNotALeaf) ...[
            const SizedBox(height: JarvisTheme.spacingMd),
            Container(
              padding: const EdgeInsets.all(JarvisTheme.spacingMd),
              decoration: BoxDecoration(
                color: JarvisTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(JarvisTheme.radiusMd),
                border: Border.all(color: JarvisTheme.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: JarvisTheme.warning),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'This is not a valid tea leaf image. Please capture a clear image of a tea leaf.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: JarvisTheme.spacingMd),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() {
                  _selectedImage = null;
                  _imageBytes = null;
                  _result = null;
                }),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: JarvisTheme.teaGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    if (_result!.isNotALeaf) return const SizedBox.shrink();

    return HologramCard(
      enableGlow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: JarvisTheme.softGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.lightbulb,
                  color: JarvisTheme.softGold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: JarvisTheme.textPrimary,
                ),
              ),
              const Spacer(),
              // Voice button
              IconButton(
                icon: Icon(
                  Icons.volume_up,
                  color: JarvisTheme.teaGreen,
                ),
                onPressed: () {
                  final recommendations = _result!.recommendations.join('. ');
                  ref.read(voiceServiceProvider.notifier).speak(recommendations);
                },
              ),
            ],
          ),
          const SizedBox(height: JarvisTheme.spacingMd),
          ..._result!.recommendations.asMap().entries.map((entry) {
            final index = entry.key;
            final recommendation = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: JarvisTheme.goldGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: JarvisTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Action button
          const SizedBox(height: JarvisTheme.spacingSm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Navigate to detailed treatment guide
              },
              icon: const Icon(Icons.medical_services_outlined),
              label: const Text('View Full Treatment Guide'),
              style: OutlinedButton.styleFrom(
                foregroundColor: JarvisTheme.teaGreen,
                side: BorderSide(color: JarvisTheme.teaGreen),
                padding: const EdgeInsets.all(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Low':
        return JarvisTheme.healthy;
      case 'Medium':
        return JarvisTheme.warning;
      case 'High':
        return JarvisTheme.critical;
      default:
        return JarvisTheme.textMuted;
    }
  }
}

/// Custom painter for scanning effect
class ScanLinePainter extends CustomPainter {
  final double progress;
  final Color color;

  ScanLinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;

    // Scan line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);

    // Glow effect above line
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          color.withOpacity(0.3),
          color.withOpacity(0.1),
        ],
        stops: const [0.0, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(0, y - 100, size.width, 100));

    canvas.drawRect(Rect.fromLTWH(0, y - 100, size.width, 100), glowPaint);
  }

  @override
  bool shouldRepaint(covariant ScanLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
