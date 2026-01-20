import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/animations/tea_animations.dart';
import '../../../../core/providers/global_iot_provider.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../data/datasources/disease_detection_ml_service.dart';
import '../../data/datasources/disease_storage_service.dart';
import '../../domain/entities/disease_detection_result.dart';

/// Premium Disease Detection Screen with modern UI
class PremiumDiseaseDetectionScreen extends ConsumerStatefulWidget {
  const PremiumDiseaseDetectionScreen({super.key});

  @override
  ConsumerState<PremiumDiseaseDetectionScreen> createState() =>
      _PremiumDiseaseDetectionScreenState();
}

class _PremiumDiseaseDetectionScreenState
    extends ConsumerState<PremiumDiseaseDetectionScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final DiseaseDetectionMLService _mlService = DiseaseDetectionMLService();
  final DiseaseStorageService _storageService = DiseaseStorageService();

  XFile? _selectedImage;
  Uint8List? _imageBytes;
  DiseaseDetectionResult? _result;
  FieldAnalysisResult? _fieldResult; // For cumulative/batch analysis
  bool _isProcessing = false;
  bool _showGradCam = false;
  bool _isBackendConnected = false;
  bool _isCheckingConnection = true;
  bool _savedToDb = false;
  bool _isSavingToDb = false;

  // Detection mode: 'single' for single leaf, 'field' for field/batch analysis
  String _detectionMode = 'single';

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _initializeService();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeService() async {
    setState(() => _isCheckingConnection = true);
    await _mlService.initialize();
    setState(() {
      _isBackendConnected = _mlService.isBackendAvailable;
      _isCheckingConnection = false;
    });
  }

  Future<void> _refreshConnection() async {
    setState(() => _isCheckingConnection = true);
    final isConnected = await _mlService.checkBackendConnection();
    setState(() {
      _isBackendConnected = isConnected;
      _isCheckingConnection = false;
    });
    if (mounted) {
      if (isConnected) {
        TeaSnackbar.success(context, 'Connected to ML backend server');
      } else {
        TeaSnackbar.warning(context, 'Backend not available - using offline mode');
      }
    }
  }

  // Get live sensor values from global IoT provider
  double get _liveTemp {
    final iotState = ref.read(globalIoTProvider);
    return iotState.hasData ? iotState.temperature : 26.5;
  }

  double get _liveHumidity {
    final iotState = ref.read(globalIoTProvider);
    return iotState.hasData ? iotState.humidity : 72.0;
  }

  double get _liveAirQuality {
    final iotState = ref.read(globalIoTProvider);
    return iotState.hasData ? iotState.airQuality.toDouble() : 45.0;
  }

  bool get _hasLiveIoTData {
    final iotState = ref.read(globalIoTProvider);
    return iotState.hasData && iotState.isConnected;
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
        });
      }
    } catch (e) {
      TeaSnackbar.error(context, 'Camera error: $e');
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
        });
      }
    } catch (e) {
      TeaSnackbar.error(context, 'Gallery error: $e');
    }
  }

  Future<void> _analyzeImage() async {
    print('');
    print('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
    print('%%%%%%%% PREMIUM_DISEASE_SCREEN _analyzeImage %%%%%%%%%%');
    print('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
    print('');

    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _savedToDb = false;
    });

    try {
      if (_detectionMode == 'field') {
        // Field/Cumulative analysis - detect multiple leaves in one image
        final fieldResult = await _mlService.analyzeField(
          _selectedImage!.path,
          liveTemperature: _liveTemp,
          liveHumidity: _liveHumidity,
          liveAirQuality: _liveAirQuality,
        );

        print('>>> PREMIUM: Field analysis returned <<<');
        print('Detected leaves: ${fieldResult.detectedLeafCount}');
        print('Healthy: ${fieldResult.healthyCount}, Infected: ${fieldResult.infectedCount}');
        print('Health %: ${fieldResult.healthPercentage}');

        setState(() {
          _fieldResult = fieldResult;
          _result = null;
          _isProcessing = false;
          _isBackendConnected = _mlService.isBackendAvailable;
        });

        // Auto-save field analysis to database
        if (_isBackendConnected) {
          print('>>> PREMIUM: CALLING _saveFieldAnalysisToDatabase() <<<');
          _saveFieldAnalysisToDatabase();
        }
      } else {
        // Single leaf detection
        final result = await _mlService.predict(
          _selectedImage!.path,
          liveTemperature: _liveTemp,
          liveHumidity: _liveHumidity,
          liveAirQuality: _liveAirQuality,
        );

        print('>>> PREMIUM: predict() returned <<<');
        print('Disease: ${result.diseaseType}');
        print('Confidence: ${result.confidence}');

        setState(() {
          _result = result;
          _fieldResult = null;
          _isProcessing = false;
          _isBackendConnected = _mlService.isBackendAvailable;
        });

        // Auto-save to database if backend connected and valid leaf
        print('>>> PREMIUM: Checking save conditions <<<');
        print('_isBackendConnected: $_isBackendConnected');
        print('result.isNotALeaf: ${result.isNotALeaf}');

        if (_isBackendConnected && !result.isNotALeaf) {
          print('>>> PREMIUM: CALLING _saveToDatabase() <<<');
          _saveToDatabase();
        } else {
          print('>>> PREMIUM: NOT saving to database');
        }
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      TeaSnackbar.error(context, 'Analysis error: $e');
    }
  }

  Future<void> _saveToDatabase() async {
    print('=== PREMIUM: SAVE TO DATABASE CALLED ===');
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
          TeaSnackbar.warning(context, 'Please log in to save scans to database');
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
        print('Saved ID: ${savedResult['_id'] ?? savedResult['id']}');
        setState(() {
          _savedToDb = true;
          _isSavingToDb = false;
        });
        if (mounted) {
          TeaSnackbar.success(context, 'Scan saved to database');
        }
      } else {
        print('!!! Failed to save detection');
        setState(() => _isSavingToDb = false);
        if (mounted) {
          TeaSnackbar.error(context, 'Failed to save scan to database');
        }
      }
    } catch (e) {
      print('!!! Error saving to database: $e');
      setState(() => _isSavingToDb = false);
      if (mounted) {
        TeaSnackbar.error(context, 'Error saving: $e');
      }
    }
  }

  Future<void> _saveFieldAnalysisToDatabase() async {
    print('=== PREMIUM: SAVE FIELD ANALYSIS TO DATABASE ===');
    if (_fieldResult == null || _selectedImage == null || _savedToDb) {
      print('!!! Early return - conditions not met');
      return;
    }

    setState(() => _isSavingToDb = true);

    try {
      final authState = ref.read(authStateProvider);
      final authToken = authState.accessToken;
      print('Auth state: isAuthenticated=${authState.isAuthenticated}');

      if (authToken == null || authToken.isEmpty) {
        print('!!! No auth token');
        if (mounted) {
          TeaSnackbar.warning(context, 'Please log in to save field analysis');
        }
        setState(() => _isSavingToDb = false);
        return;
      }

      print('>>> Calling _storageService.saveFieldAnalysisWithImage() <<<');
      final savedResult = await _storageService.saveFieldAnalysisWithImage(
        result: _fieldResult!,
        imagePath: _selectedImage!.path,
        authToken: authToken,
      );

      if (savedResult != null) {
        print('>>> Field analysis saved successfully! <<<');
        setState(() {
          _savedToDb = true;
          _isSavingToDb = false;
        });
        if (mounted) {
          TeaSnackbar.success(context, 'Field analysis saved (${_fieldResult!.detectedLeafCount} leaves)');
        }
      } else {
        print('!!! Failed to save field analysis');
        setState(() => _isSavingToDb = false);
        if (mounted) {
          TeaSnackbar.error(context, 'Failed to save field analysis');
        }
      }
    } catch (e) {
      print('!!! Error saving field analysis: $e');
      setState(() => _isSavingToDb = false);
      if (mounted) {
        TeaSnackbar.error(context, 'Error saving: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch global IoT state for live updates
    final iotState = ref.watch(globalIoTProvider);

    return Scaffold(
      backgroundColor: TeaColors.mistGreen,
      body: Stack(
        children: [
          // Background decoration
          const FloatingLeavesBackground(
            leafCount: 4,
            opacity: 0.06,
            child: SizedBox.expand(),
          ),

          // Main content
          CustomScrollView(
            slivers: [
              // App Bar
              _buildAppBar(),

              // Content
              SliverPadding(
                padding: TeaSpacing.screenPaddingHorizontal,
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: TeaSpacing.md),

                    // Detection Mode Toggle
                    _buildModeToggle(),

                    const SizedBox(height: TeaSpacing.md),

                    // Live Environment Card (with real IoT data)
                    _buildLiveEnvironmentCard(iotState),

                    const SizedBox(height: TeaSpacing.lg),

                    // Image Section
                    if (_selectedImage == null)
                      _buildImageCapturePlaceholder()
                    else
                      _buildImagePreview(),

                    const SizedBox(height: TeaSpacing.lg),

                    // Action Buttons
                    _buildActionButtons(),

                    // Results (single leaf or field analysis)
                    if (_result != null) ...[
                      const SizedBox(height: TeaSpacing.lg),
                      _buildResultsCard(),
                      const SizedBox(height: TeaSpacing.md),
                      _buildRecommendationsCard(),
                    ],

                    // Field/Cumulative Results
                    if (_fieldResult != null) ...[
                      const SizedBox(height: TeaSpacing.lg),
                      _buildFieldResultsCard(),
                      const SizedBox(height: TeaSpacing.md),
                      _buildFieldRecommendationsCard(),
                    ],

                    const SizedBox(height: TeaSpacing.xxl),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return TeaCard.elevated(
      padding: const EdgeInsets.all(TeaSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: _buildModeButton(
              'Single Leaf',
              Icons.eco,
              'single',
              'Analyze one leaf',
            ),
          ),
          const SizedBox(width: TeaSpacing.sm),
          Expanded(
            child: _buildModeButton(
              'Field View',
              Icons.grid_view,
              'field',
              'Multiple leaves - Cumulative',
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildModeButton(String label, IconData icon, String mode, String description) {
    final isSelected = _detectionMode == mode;

    return GestureDetector(
      onTap: () {
        setState(() {
          _detectionMode = mode;
          _result = null;
          _fieldResult = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: TeaSpacing.smd,
          horizontal: TeaSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? TeaColors.freshLeaf.withOpacity(0.15)
              : TeaColors.white,
          borderRadius: TeaRadius.radiusMd,
          border: Border.all(
            color: isSelected ? TeaColors.freshLeaf : TeaColors.lightGray,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? TeaColors.freshLeaf : TeaColors.darkGray,
              size: 24,
            ),
            const SizedBox(height: TeaSpacing.xs),
            Text(
              label,
              style: TeaTypography.labelMedium.copyWith(
                color: isSelected ? TeaColors.freshLeaf : TeaColors.nearBlack,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            Text(
              description,
              style: TeaTypography.labelSmall.copyWith(
                color: TeaColors.mediumGray,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: true,
      pinned: true,
      backgroundColor: TeaColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: TeaColors.nearBlack),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Disease Detection',
        style: TeaTypography.titleLarge.copyWith(color: TeaColors.nearBlack),
      ),
      actions: [
        // Connection status indicator
        _buildConnectionIndicator(),
        if (_selectedImage != null)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: TeaColors.alertRust),
            onPressed: () => setState(() {
              _selectedImage = null;
              _imageBytes = null;
              _result = null;
            }),
            tooltip: 'Clear image',
          ),
        const SizedBox(width: TeaSpacing.sm),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                TeaColors.white,
                TeaColors.mistGreen.withOpacity(0.3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionIndicator() {
    return Padding(
      padding: const EdgeInsets.only(right: TeaSpacing.xs),
      child: InkWell(
        onTap: _refreshConnection,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TeaSpacing.sm,
            vertical: TeaSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: _isCheckingConnection
                ? TeaColors.mediumGray.withOpacity(0.1)
                : (_isBackendConnected
                    ? TeaColors.healthyGreen.withOpacity(0.1)
                    : TeaColors.warningAmber.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isCheckingConnection)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: TeaColors.mediumGray,
                  ),
                )
              else
                Icon(
                  _isBackendConnected ? Icons.cloud_done : Icons.cloud_off,
                  size: 16,
                  color: _isBackendConnected
                      ? TeaColors.healthyGreen
                      : TeaColors.warningAmber,
                ),
              const SizedBox(width: 4),
              Text(
                _isCheckingConnection
                    ? 'Checking...'
                    : (_isBackendConnected ? 'Online' : 'Offline'),
                style: TeaTypography.labelSmall.copyWith(
                  color: _isCheckingConnection
                      ? TeaColors.mediumGray
                      : (_isBackendConnected
                          ? TeaColors.healthyGreen
                          : TeaColors.warningAmber),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveEnvironmentCard(GlobalIoTState iotState) {
    final hasIoTData = iotState.hasData && iotState.isConnected;
    final temp = hasIoTData ? iotState.temperature : 26.5;
    final humidity = hasIoTData ? iotState.humidity : 72.0;
    final airQuality = hasIoTData ? iotState.airQuality.toDouble() : 45.0;

    return TeaCard.elevated(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(TeaSpacing.sm),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: hasIoTData
                        ? [TeaColors.freshLeaf, TeaColors.healthyGreen]
                        : [TeaColors.mediumGray, TeaColors.darkGray],
                  ),
                  borderRadius: TeaRadius.radiusSm,
                ),
                child: Icon(
                  hasIoTData ? Icons.sensors : Icons.sensors_off,
                  color: TeaColors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: TeaSpacing.smd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Live Environment', style: TeaTypography.titleSmall),
                    Text(
                      hasIoTData ? 'Real-time IoT sensor data' : 'IoT not connected - using defaults',
                      style: TeaTypography.labelSmall.copyWith(
                        color: hasIoTData ? TeaColors.freshLeaf : TeaColors.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasIoTData)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TeaSpacing.sm,
                        vertical: TeaSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: TeaColors.healthyGreen
                            .withOpacity(0.1 + _pulseController.value * 0.1),
                        borderRadius: TeaRadius.radiusRound,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: TeaColors.healthyGreen,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: TeaColors.healthyGreen
                                      .withOpacity(0.3 + _pulseController.value * 0.3),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TeaTypography.labelSmall.copyWith(
                              color: TeaColors.healthyGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TeaSpacing.sm,
                    vertical: TeaSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: TeaColors.warningAmber.withOpacity(0.1),
                    borderRadius: TeaRadius.radiusRound,
                  ),
                  child: Text(
                    'DEFAULT',
                    style: TeaTypography.labelSmall.copyWith(
                      color: TeaColors.warningAmber,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: TeaSpacing.md),
          Container(
            padding: const EdgeInsets.all(TeaSpacing.smd),
            decoration: BoxDecoration(
              color: TeaColors.leafPale,
              borderRadius: TeaRadius.radiusMd,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildEnvReading(
                    Icons.thermostat,
                    '${temp.toStringAsFixed(1)}°C',
                    'Temperature',
                    TeaColors.warningAmber,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: TeaColors.mediumGray.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildEnvReading(
                    Icons.water_drop,
                    '${humidity.toStringAsFixed(0)}%',
                    'Humidity',
                    TeaColors.infoSky,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: TeaColors.mediumGray.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildEnvReading(
                    Icons.air,
                    '${airQuality.toStringAsFixed(0)}',
                    'AQI',
                    _getAirQualityColor(airQuality),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildEnvReading(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: TeaSpacing.xs),
        Text(
          value,
          style: TeaTypography.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TeaTypography.labelSmall.copyWith(
            color: TeaColors.darkGray,
          ),
        ),
      ],
    );
  }

  Widget _buildImageCapturePlaceholder() {
    return TeaCard.elevated(
      padding: EdgeInsets.zero,
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              TeaColors.leafPale,
              TeaColors.freshLeaf.withOpacity(0.08),
            ],
          ),
          borderRadius: TeaRadius.radiusLg,
          border: Border.all(
            color: TeaColors.freshLeaf.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BreathingAnimation(
              child: Container(
                padding: const EdgeInsets.all(TeaSpacing.lg),
                decoration: BoxDecoration(
                  color: TeaColors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: TeaShadows.glowPrimary,
                ),
                child: Icon(
                  Icons.eco,
                  size: 56,
                  color: TeaColors.freshLeaf,
                ),
              ),
            ),
            const SizedBox(height: TeaSpacing.lg),
            Text(
              'Capture Tea Leaf',
              style: TeaTypography.titleMedium.copyWith(
                color: TeaColors.freshLeaf,
              ),
            ),
            const SizedBox(height: TeaSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TeaSpacing.xl),
              child: Text(
                'Take a photo or select from gallery to detect diseases',
                textAlign: TextAlign.center,
                style: TeaTypography.bodySmall.copyWith(
                  color: TeaColors.darkGray,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildImagePreview() {
    if (_imageBytes == null) {
      return TeaCard.elevated(
        child: SizedBox(
          height: 300,
          child: Center(
            child: CircularProgressIndicator(color: TeaColors.freshLeaf),
          ),
        ),
      );
    }

    return TeaCard.elevated(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: TeaRadius.radiusLg,
            child: Image.memory(
              _imageBytes!,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          if (_showGradCam && _result != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: TeaRadius.radiusLg,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.8,
                      colors: [
                        TeaColors.alertRust.withOpacity(0.4),
                        TeaColors.warningAmber.withOpacity(0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          // GradCAM toggle
          if (_result != null)
            Positioned(
              bottom: TeaSpacing.sm,
              right: TeaSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TeaSpacing.sm,
                  vertical: TeaSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: TeaColors.nearBlack.withOpacity(0.7),
                  borderRadius: TeaRadius.radiusRound,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Grad-CAM',
                      style: TeaTypography.labelSmall.copyWith(
                        color: TeaColors.white,
                      ),
                    ),
                    const SizedBox(width: TeaSpacing.xs),
                    SizedBox(
                      height: 20,
                      child: Switch(
                        value: _showGradCam,
                        onChanged: (value) => setState(() => _showGradCam = value),
                        activeColor: TeaColors.goldenSunlight,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Processing overlay
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: TeaColors.nearBlack.withOpacity(0.6),
                  borderRadius: TeaRadius.radiusLg,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        color: TeaColors.white,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: TeaSpacing.md),
                    Text(
                      'Analyzing leaf...',
                      style: TeaTypography.titleSmall.copyWith(
                        color: TeaColors.white,
                      ),
                    ),
                    const SizedBox(height: TeaSpacing.xs),
                    Text(
                      'Using AI to detect diseases',
                      style: TeaTypography.labelSmall.copyWith(
                        color: TeaColors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildActionButtons() {
    if (_selectedImage == null) {
      return Row(
        children: [
          Expanded(
            child: TeaButton.primary(
              label: 'Camera',
              icon: Icons.camera_alt,
              onPressed: _captureImage,
            ),
          ),
          const SizedBox(width: TeaSpacing.smd),
          Expanded(
            child: TeaButton.outlined(
              label: 'Gallery',
              icon: Icons.photo_library,
              onPressed: _pickFromGallery,
            ),
          ),
        ],
      ).animate().fadeIn(delay: 200.ms);
    } else if (_result == null) {
      return TeaButton.primary(
        label: _isProcessing ? 'Analyzing...' : 'Analyze Leaf',
        icon: _isProcessing ? null : Icons.search,
        isLoading: _isProcessing,
        onPressed: _isProcessing ? null : _analyzeImage,
        isFullWidth: true,
      ).animate().fadeIn(delay: 100.ms);
    }

    // After result, show new scan button
    return TeaButton.outlined(
      label: 'New Scan',
      icon: Icons.refresh,
      onPressed: () => setState(() {
        _selectedImage = null;
        _imageBytes = null;
        _result = null;
        _fieldResult = null;
      }),
      isFullWidth: true,
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildResultsCard() {
    if (_result == null) return const SizedBox.shrink();

    final isHealthy = _result!.diseaseType == 'Healthy';
    final isNotALeaf = _result!.isNotALeaf;

    Color statusColor;
    IconData statusIcon;
    String statusTitle;

    if (isNotALeaf) {
      statusColor = TeaColors.mediumGray;
      statusIcon = Icons.error_outline;
      statusTitle = 'Invalid Image';
    } else if (isHealthy) {
      statusColor = TeaColors.healthyGreen;
      statusIcon = Icons.check_circle;
      statusTitle = 'Healthy';
    } else {
      statusColor = TeaColors.alertRust;
      statusIcon = Icons.warning_rounded;
      statusTitle = _result!.diseaseType;
    }

    return TeaCard.elevated(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(TeaSpacing.smd),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: TeaRadius.radiusMd,
                ),
                child: Icon(statusIcon, color: statusColor, size: 28),
              ),
              const SizedBox(width: TeaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isNotALeaf ? 'Detection Result' : 'Disease Status',
                      style: TeaTypography.labelSmall.copyWith(
                        color: TeaColors.darkGray,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusTitle,
                      style: TeaTypography.headlineSmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Invalid image message
          if (isNotALeaf) ...[
            const SizedBox(height: TeaSpacing.md),
            Container(
              padding: const EdgeInsets.all(TeaSpacing.md),
              decoration: BoxDecoration(
                color: TeaColors.warningAmber.withOpacity(0.1),
                borderRadius: TeaRadius.radiusMd,
                border: Border.all(
                  color: TeaColors.warningAmber.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: TeaColors.warningAmber, size: 22),
                  const SizedBox(width: TeaSpacing.smd),
                  Expanded(
                    child: Text(
                      'This is not a valid tea leaf image. Please submit a clear image of a tea leaf for disease detection.',
                      style: TeaTypography.bodySmall.copyWith(
                        color: TeaColors.warningAmber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: TeaSpacing.md),
            const Divider(),
            const SizedBox(height: TeaSpacing.md),

            // Confidence meter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Confidence', style: TeaTypography.titleSmall),
                Text(
                  '${(_result!.confidence * 100).toStringAsFixed(1)}%',
                  style: TeaTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TeaSpacing.sm),
            ClipRRect(
              borderRadius: TeaRadius.radiusSm,
              child: LinearProgressIndicator(
                value: _result!.confidence,
                backgroundColor: TeaColors.lightGray,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 8,
              ),
            ),

            // Severity (if not healthy)
            if (!isHealthy) ...[
              const SizedBox(height: TeaSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Severity Level', style: TeaTypography.titleSmall),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TeaSpacing.smd,
                      vertical: TeaSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(_result!.severity).withOpacity(0.1),
                      borderRadius: TeaRadius.radiusSm,
                      border: Border.all(
                        color: _getSeverityColor(_result!.severity).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _result!.severity,
                      style: TeaTypography.labelMedium.copyWith(
                        color: _getSeverityColor(_result!.severity),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Environmental factors
            if (_result!.temperature != null || _result!.humidity != null) ...[
              const SizedBox(height: TeaSpacing.lg),
              Row(
                children: [
                  Icon(Icons.eco, color: TeaColors.freshLeaf, size: 18),
                  const SizedBox(width: TeaSpacing.xs),
                  Text(
                    'Environmental Factors at Analysis',
                    style: TeaTypography.titleSmall,
                  ),
                ],
              ),
              const SizedBox(height: TeaSpacing.smd),
              Wrap(
                spacing: TeaSpacing.sm,
                runSpacing: TeaSpacing.sm,
                children: [
                  if (_result!.temperature != null)
                    _buildFactorChip(
                      Icons.thermostat,
                      '${_result!.temperature!.toStringAsFixed(1)}°C',
                      TeaColors.warningAmber,
                    ),
                  if (_result!.humidity != null)
                    _buildFactorChip(
                      Icons.water_drop,
                      '${_result!.humidity!.toStringAsFixed(0)}%',
                      TeaColors.infoSky,
                    ),
                  if (_result!.airQuality != null)
                    _buildFactorChip(
                      Icons.air,
                      'AQI ${_result!.airQuality!.toStringAsFixed(0)}',
                      TeaColors.freshLeaf,
                    ),
                ],
              ),
            ],

            const SizedBox(height: TeaSpacing.md),
            Text(
              'Analyzed at: ${_formatTime(_result!.timestamp)}',
              style: TeaTypography.labelSmall.copyWith(
                color: TeaColors.mediumGray,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildFactorChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TeaSpacing.smd,
        vertical: TeaSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: TeaRadius.radiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TeaTypography.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    if (_result == null) return const SizedBox.shrink();

    final isNotALeaf = _result!.isNotALeaf;
    final cardColor = isNotALeaf ? TeaColors.warningAmber : TeaColors.goldenSunlight;

    return TeaCard.elevated(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardColor.withOpacity(0.05),
              cardColor.withOpacity(0.12),
            ],
          ),
          borderRadius: TeaRadius.radiusLg,
          border: Border.all(
            color: cardColor.withOpacity(0.2),
          ),
        ),
        padding: TeaSpacing.cardPaddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(TeaSpacing.sm),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.2),
                    borderRadius: TeaRadius.radiusSm,
                  ),
                  child: Icon(
                    isNotALeaf ? Icons.tips_and_updates : Icons.lightbulb,
                    color: cardColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: TeaSpacing.smd),
                Text(
                  isNotALeaf ? 'What to Do' : 'Recommendations',
                  style: TeaTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TeaSpacing.md),
            ..._result!.recommendations.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: TeaSpacing.smd),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [cardColor.withOpacity(0.8), cardColor],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: TeaTypography.labelSmall.copyWith(
                              color: TeaColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: TeaSpacing.smd),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TeaTypography.bodyMedium.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  /// Field/Cumulative Results Card for batch analysis
  Widget _buildFieldResultsCard() {
    if (_fieldResult == null) return const SizedBox.shrink();

    final healthPercentage = _fieldResult!.healthPercentage;
    final isHealthyField = healthPercentage >= 70;
    final statusColor = isHealthyField
        ? TeaColors.healthyGreen
        : (healthPercentage >= 40 ? TeaColors.warningAmber : TeaColors.alertRust);

    return TeaCard.elevated(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(TeaSpacing.smd),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: TeaRadius.radiusMd,
                ),
                child: Icon(Icons.grid_view, color: statusColor, size: 28),
              ),
              const SizedBox(width: TeaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Field Analysis',
                      style: TeaTypography.labelSmall.copyWith(
                        color: TeaColors.darkGray,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _fieldResult!.overallStatus,
                      style: TeaTypography.headlineSmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: TeaSpacing.md),
          const Divider(),
          const SizedBox(height: TeaSpacing.md),

          // Leaf counts
          Row(
            children: [
              Expanded(
                child: _buildCountCard(
                  'Total Leaves',
                  '${_fieldResult!.detectedLeafCount}',
                  Icons.eco,
                  TeaColors.freshLeaf,
                ),
              ),
              const SizedBox(width: TeaSpacing.sm),
              Expanded(
                child: _buildCountCard(
                  'Healthy',
                  '${_fieldResult!.healthyCount}',
                  Icons.check_circle,
                  TeaColors.healthyGreen,
                ),
              ),
              const SizedBox(width: TeaSpacing.sm),
              Expanded(
                child: _buildCountCard(
                  'Infected',
                  '${_fieldResult!.infectedCount}',
                  Icons.warning,
                  TeaColors.alertRust,
                ),
              ),
            ],
          ),

          const SizedBox(height: TeaSpacing.lg),

          // Health percentage meter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Health Score', style: TeaTypography.titleSmall),
              Text(
                '${healthPercentage.toStringAsFixed(1)}%',
                style: TeaTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: TeaSpacing.sm),
          ClipRRect(
            borderRadius: TeaRadius.radiusSm,
            child: LinearProgressIndicator(
              value: healthPercentage / 100,
              backgroundColor: TeaColors.lightGray,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 10,
            ),
          ),

          // Disease breakdown
          if (_fieldResult!.diseaseCounts.isNotEmpty) ...[
            const SizedBox(height: TeaSpacing.lg),
            Text('Disease Breakdown', style: TeaTypography.titleSmall),
            const SizedBox(height: TeaSpacing.smd),
            ..._fieldResult!.diseaseCounts.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: TeaSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: TeaColors.alertRust,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: TeaSpacing.sm),
                          Text(entry.key, style: TeaTypography.bodyMedium),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TeaSpacing.sm,
                          vertical: TeaSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: TeaColors.alertRust.withOpacity(0.1),
                          borderRadius: TeaRadius.radiusSm,
                        ),
                        child: Text(
                          '${entry.value} leaves',
                          style: TeaTypography.labelSmall.copyWith(
                            color: TeaColors.alertRust,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          const SizedBox(height: TeaSpacing.md),
          Text(
            'Analyzed at: ${_formatTime(_fieldResult!.timestamp)}',
            style: TeaTypography.labelSmall.copyWith(
              color: TeaColors.mediumGray,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildCountCard(String label, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(TeaSpacing.smd),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: TeaRadius.radiusMd,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: TeaSpacing.xs),
          Text(
            count,
            style: TeaTypography.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TeaTypography.labelSmall.copyWith(
              color: TeaColors.darkGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRecommendationsCard() {
    if (_fieldResult == null) return const SizedBox.shrink();

    final cardColor = _fieldResult!.healthPercentage >= 70
        ? TeaColors.freshLeaf
        : (_fieldResult!.healthPercentage >= 40
            ? TeaColors.warningAmber
            : TeaColors.alertRust);

    return TeaCard.elevated(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardColor.withOpacity(0.05),
              cardColor.withOpacity(0.12),
            ],
          ),
          borderRadius: TeaRadius.radiusLg,
          border: Border.all(
            color: cardColor.withOpacity(0.2),
          ),
        ),
        padding: TeaSpacing.cardPaddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(TeaSpacing.sm),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.2),
                    borderRadius: TeaRadius.radiusSm,
                  ),
                  child: Icon(
                    Icons.recommend,
                    color: cardColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: TeaSpacing.smd),
                Text(
                  'Field Recommendations',
                  style: TeaTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TeaSpacing.md),
            ..._fieldResult!.recommendations.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: TeaSpacing.smd),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [cardColor.withOpacity(0.8), cardColor],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: TeaTypography.labelSmall.copyWith(
                              color: TeaColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: TeaSpacing.smd),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TeaTypography.bodyMedium.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return TeaColors.healthyGreen;
      case 'medium':
        return TeaColors.warningAmber;
      case 'high':
        return TeaColors.alertRust;
      default:
        return TeaColors.mediumGray;
    }
  }

  Color _getAirQualityColor(double aqi) {
    if (aqi < 50) return TeaColors.healthyGreen;
    if (aqi < 100) return TeaColors.warningAmber;
    if (aqi < 150) return TeaColors.alertRust;
    return TeaColors.criticalRed;
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
