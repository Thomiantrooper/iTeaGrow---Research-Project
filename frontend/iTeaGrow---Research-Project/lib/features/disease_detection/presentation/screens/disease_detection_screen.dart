import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../data/datasources/disease_detection_ml_service.dart';
import '../../data/datasources/disease_storage_service.dart';
import '../../domain/entities/disease_detection_result.dart';
import 'scan_history_screen.dart';

class DiseaseDetectionScreen extends ConsumerStatefulWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  ConsumerState<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends ConsumerState<DiseaseDetectionScreen>
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
  bool _isSavingToDb = false;
  bool _savedToDb = false;
  String? _savedDetectionId;

  // Animation controllers
  late AnimationController _scanAnimationController;
  late AnimationController _pulseController;
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;

  // Live readings state
  double _temp = 26.5;
  double _humidity = 72.0;
  double _airQuality = 45.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeService();
    _startLiveUpdates();
  }

  void _initializeAnimations() {
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanAnimationController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isConnected
              ? 'Connected to backend server'
              : 'Backend not available - using offline mode',),
          backgroundColor: isConnected ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  void _startLiveUpdates() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _temp += (DateTime.now().millisecond % 10 - 5) * 0.05;
          _humidity += (DateTime.now().millisecond % 10 - 5) * 0.1;
          _airQuality += (DateTime.now().millisecond % 10 - 5) * 0.2;
        });
        _startLiveUpdates();
      }
    });
  }

  Future<void> _captureImage() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 95,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _selectedImage = photo;
          _imageBytes = bytes;
          _result = null;
          _savedToDb = false;
          _savedDetectionId = null;
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
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 95,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _imageBytes = bytes;
          _result = null;
          _savedToDb = false;
          _savedDetectionId = null;
        });
      }
    } catch (e) {
      _showError('Gallery error: $e');
    }
  }

  Future<void> _analyzeImage() async {
    print('');
    print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@');
    print('@@@@@@@@ DISEASE_DETECTION_SCREEN _analyzeImage @@@@@@@@');
    print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@');
    print('');
    print('>>> _analyzeImage() CALLED <<<');
    if (_selectedImage == null) return;

    setState(() => _isProcessing = true);
    _scanAnimationController.repeat();
    _pulseController.repeat(reverse: true);

    try {
      print('>>> Calling _mlService.predict() <<<');
      final result = await _mlService.predict(
        _selectedImage!.path,
        liveTemperature: _temp,
        liveHumidity: _humidity,
        liveAirQuality: _airQuality,
      );
      print('>>> _mlService.predict() RETURNED <<<');
      print('>>> Result type: ${result.runtimeType}');

      _scanAnimationController.stop();
      _scanAnimationController.reset();
      _pulseController.stop();
      _pulseController.reset();

      print('>>> Calling setState <<<');
      setState(() {
        _result = result;
        _isProcessing = false;
        _isBackendConnected = _mlService.isBackendAvailable;
      });
      print('>>> setState DONE <<<');

      // Debug: Print result info
      print('=== SCAN RESULT ===');
      print('Disease Type: ${result.diseaseType}');
      print('Confidence: ${result.confidence}');
      print('Is Not A Leaf: ${result.isNotALeaf}');
      print('Backend Connected: $_isBackendConnected');
      print('Summary: ${result.summary}');
      print('===================');

      // Show result snackbar so user knows scan completed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Detected: ${result.diseaseType} (${(result.confidence * 100).toStringAsFixed(1)}%)'),
            backgroundColor: result.diseaseType == 'Healthy' ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Auto-save to database if connected and valid leaf
      print('>>> CHECKING IF SHOULD SAVE <<<');
      print('_isBackendConnected: $_isBackendConnected');
      print('result.isNotALeaf: ${result.isNotALeaf}');
      print('result.diseaseType: ${result.diseaseType}');

      if (_isBackendConnected && !result.isNotALeaf) {
        print('>>> CALLING _saveToDatabase() <<<');
        _saveToDatabase();
      } else {
        print('!!! NOT SAVING: backendConnected=$_isBackendConnected, isNotALeaf=${result.isNotALeaf}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Not saving: backend=$_isBackendConnected, notLeaf=${result.isNotALeaf}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      _scanAnimationController.stop();
      _scanAnimationController.reset();
      _pulseController.stop();
      _pulseController.reset();
      setState(() => _isProcessing = false);
      _showError('Analysis error: $e');
    }
  }

  Future<void> _saveToDatabase() async {
    print('=== SAVE TO DATABASE CALLED ===');
    print('_result: $_result');
    print('_selectedImage: $_selectedImage');
    print('_savedToDb: $_savedToDb');

    if (_result == null || _selectedImage == null || _savedToDb) {
      print('!!! Early return - conditions not met');
      return;
    }

    setState(() => _isSavingToDb = true);
    print('>>> Starting database save process <<<');

    try {
      // Get auth token from Riverpod state
      final authState = ref.read(authStateProvider);
      final authToken = authState.accessToken;
      print('Auth state: isAuthenticated=${authState.isAuthenticated}');
      print('Auth token present: ${authToken != null && authToken.isNotEmpty}');
      print('Image path: ${_selectedImage!.path}');

      // Check if user is logged in
      if (authToken == null || authToken.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Please log in to save scans to database'),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _isSavingToDb = false);
        return;
      }

      final response = await _storageService.saveDetectionWithImage(
        result: _result!,
        imagePath: _selectedImage!.path,
        authToken: authToken,
      );

      if (response != null) {
        setState(() {
          _savedToDb = true;
          _savedDetectionId = response['_id'] ?? response['id'];
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Scan saved to database'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Response was null - likely auth or server error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text('Could not save to database. Check connection or login status.')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSavingToDb = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _resetScan() {
    setState(() {
      _selectedImage = null;
      _imageBytes = null;
      _result = null;
      _savedToDb = false;
      _savedDetectionId = null;
    });
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ScanHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Disease Detection',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _openHistory,
            tooltip: 'Scan History',
          ),
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
                    color: _isBackendConnected ? Colors.white : Colors.orange.shade200,
                  ),
            onPressed: _refreshConnection,
            tooltip: _isBackendConnected
                ? 'Connected to server'
                : 'Offline mode - tap to reconnect',
          ),
          if (_selectedImage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetScan,
              tooltip: 'New Scan',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Display Section
            _buildImageSection(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Live Environmental Status
                  _buildLiveEnvironmentCard(),

                  const SizedBox(height: 20),

                  // Action Buttons
                  if (_selectedImage == null) ...[
                    _buildCaptureButtons(),
                  ] else if (_result == null) ...[
                    _buildAnalyzeButton(),
                  ],

                  // Results Section
                  if (_result != null) ...[
                    const SizedBox(height: 20),
                    _buildResultsCard(),
                    const SizedBox(height: 16),
                    // Always show chart for valid leaf detections
                    if (!_result!.isNotALeaf) ...[
                      // Chart Section Header
                      Row(
                        children: [
                          const Icon(Icons.analytics, color: AppTheme.primaryGreen, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Detection Analysis',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildConfidenceChart(),
                      const SizedBox(height: 16),
                    ],
                    _buildRecommendationsCard(),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                    const SizedBox(height: 20), // Bottom padding
                  ],
                ],
              ),
            ),
          ],
        ),
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
    return Container(
      height: 300,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen.withOpacity(0.05),
            AppTheme.primaryGreenLight.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.3),
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco_outlined,
              size: 64,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Scan Tea Leaf',
            style: TextStyle(
              color: AppTheme.primaryGreen,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Capture or upload an image of a tea leaf to detect diseases',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_imageBytes == null) {
      return Container(
        height: 350,
        color: Colors.grey.shade200,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      children: [
        // Full width image - show complete image without cropping
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              _imageBytes!,
              fit: BoxFit.contain,  // Show full image without cropping
              width: double.infinity,
            ),
          ),
        ),

        // Scanning overlay animation
        if (_isProcessing)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: ScanLinePainter(
                    progress: _scanAnimation.value,
                    color: AppTheme.primaryGreen,
                  ),
                );
              },
            ),
          ),

        // Processing overlay
        if (_isProcessing)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Analyzing Leaf...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Detecting diseases',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

        // Grad-CAM overlay
        if (_showGradCam && _result != null && !_isProcessing)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    Colors.red.withOpacity(0.5),
                    Colors.yellow.withOpacity(0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

        // Controls overlay
        if (_result != null && !_isProcessing)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Grad-CAM toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.visibility, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      const Text('Heatmap', style: TextStyle(color: Colors.white, fontSize: 12)),
                      const SizedBox(width: 8),
                      Switch(
                        value: _showGradCam,
                        onChanged: (value) => setState(() => _showGradCam = value),
                        activeThumbColor: AppTheme.accentAmber,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),

                // Database status
                if (_savedToDb)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_done, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('Saved', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                else if (_isSavingToDb)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text('Saving...', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLiveEnvironmentCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.blue.withOpacity(0.03)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.sensors, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Environment Monitor',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Real-time conditions',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const Spacer(),
                _buildLiveIndicator(),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLiveReadingItem(
                    Icons.thermostat,
                    '${_temp.toStringAsFixed(1)}°C',
                    'Temperature',
                    Colors.deepOrange,
                  ),
                  Container(width: 1, height: 50, color: Colors.grey.shade300),
                  _buildLiveReadingItem(
                    Icons.water_drop,
                    '${_humidity.toStringAsFixed(1)}%',
                    'Humidity',
                    Colors.blue,
                  ),
                  Container(width: 1, height: 50, color: Colors.grey.shade300),
                  _buildLiveReadingItem(
                    Icons.air,
                    _airQuality.toStringAsFixed(0),
                    'AQI',
                    _getAirQualityColor(_airQuality),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.statusGood.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.statusGood,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.statusGood.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'LIVE',
            style: TextStyle(
              color: AppTheme.statusGood,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveReadingItem(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _captureImage,
            icon: const Icon(Icons.camera_alt, size: 24),
            label: const Text('Camera', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pickFromGallery,
            icon: const Icon(Icons.photo_library, size: 24),
            label: const Text('Gallery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
              side: const BorderSide(color: AppTheme.primaryGreen, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    return ElevatedButton.icon(
      onPressed: _isProcessing ? null : _analyzeImage,
      icon: _isProcessing
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.search, size: 26),
      label: Text(
        _isProcessing ? 'Scanning...' : 'Start Scan',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        disabledBackgroundColor: AppTheme.primaryGreen.withOpacity(0.6),
      ),
    );
  }

  Widget _buildResultsCard() {
    final isHealthy = _result!.diseaseType == 'Healthy';
    final isNotALeaf = _result!.isNotALeaf;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isNotALeaf) {
      statusColor = Colors.grey;
      statusIcon = Icons.error_outline;
      statusText = 'Invalid Image';
    } else if (isHealthy) {
      statusColor = AppTheme.statusGood;
      statusIcon = Icons.check_circle;
      statusText = 'Healthy Leaf';
    } else {
      statusColor = AppTheme.statusCritical;
      statusIcon = Icons.warning_amber_rounded;
      statusText = 'Disease Detected';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isNotALeaf ? 'Not a Tea Leaf' : _result!.diseaseType,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (isNotALeaf) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please capture a clear image of a tea leaf for accurate disease detection.',
                        style: TextStyle(fontSize: 14, color: Colors.orange.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 20),

              // Confidence bar
              _buildConfidenceBar(),

              if (!isHealthy) ...[
                const SizedBox(height: 16),
                _buildSeverityBadge(),
              ],

              // Environmental data at detection
              if (_result!.temperature != null) ...[
                const SizedBox(height: 16),
                _buildEnvironmentAtDetection(),
              ],
            ],

            // Processing info
            if (_result!.processingTimeMs != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Processed in ${_result!.processingTimeMs!.toStringAsFixed(0)}ms',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  Text(
                    'Analyzed at ${_formatTime(_result!.timestamp)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceBar() {
    final confidence = _result!.confidence;
    final isHealthy = _result!.diseaseType == 'Healthy';
    final barColor = isHealthy ? AppTheme.statusGood : AppTheme.statusCritical;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Detection Confidence',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              '${(confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            FractionallySizedBox(
              widthFactor: confidence,
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [barColor.withOpacity(0.7), barColor],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: barColor.withOpacity(0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeverityBadge() {
    final severity = _result!.severity;
    final severityColor = _getSeverityColor(severity);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Severity Level', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [severityColor.withOpacity(0.8), severityColor],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: severityColor.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            severity.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnvironmentAtDetection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (_result!.temperature != null)
            _buildMiniReading(Icons.thermostat, '${_result!.temperature!.toStringAsFixed(1)}°C', Colors.orange),
          if (_result!.humidity != null)
            _buildMiniReading(Icons.water_drop, '${_result!.humidity!.toStringAsFixed(1)}%', Colors.blue),
          if (_result!.airQuality != null)
            _buildMiniReading(Icons.air, 'AQI ${_result!.airQuality!.toStringAsFixed(0)}', _getAirQualityColor(_result!.airQuality!)),
        ],
      ),
    );
  }

  Widget _buildMiniReading(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  Widget _buildConfidenceChart() {
    final isHealthy = _result!.diseaseType == 'Healthy';
    final confidence = _result!.confidence;

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart, color: AppTheme.primaryGreen),
              SizedBox(width: 8),
              Text(
                'Detection Analysis',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                // Pie Chart
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 35,
                      sections: [
                        PieChartSectionData(
                          value: confidence * 100,
                          color: isHealthy ? AppTheme.statusGood : AppTheme.statusCritical,
                          title: '${(confidence * 100).toStringAsFixed(0)}%',
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          radius: 50,
                        ),
                        PieChartSectionData(
                          value: (1 - confidence) * 100,
                          color: Colors.grey.shade300,
                          title: '',
                          radius: 40,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Legend
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChartLegendItem(
                        _result!.diseaseType,
                        isHealthy ? AppTheme.statusGood : AppTheme.statusCritical,
                        '${(confidence * 100).toStringAsFixed(1)}%',
                      ),
                      const SizedBox(height: 12),
                      _buildChartLegendItem(
                        'Uncertainty',
                        Colors.grey.shade400,
                        '${((1 - confidence) * 100).toStringAsFixed(1)}%',
                      ),
                      if (_result!.summary != null) ...[
                        const Divider(height: 24),
                        Text(
                          'Health Score: ${_result!.summary!.overallHealthScore.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegendItem(String label, Color color, String value) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsCard() {
    final isNotALeaf = _result!.isNotALeaf;
    final cardColor = isNotALeaf ? Colors.orange : AppTheme.accentAmber;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardColor.withOpacity(0.08),
            cardColor.withOpacity(0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardColor.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isNotALeaf ? Icons.tips_and_updates : Icons.lightbulb,
                    color: cardColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isNotALeaf ? 'What to Do' : 'Recommendations',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._result!.recommendations.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cardColor.withOpacity(0.8), cardColor],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: cardColor.withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _resetScan,
            icon: const Icon(Icons.refresh),
            label: const Text('New Scan'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
              side: const BorderSide(color: AppTheme.primaryGreen, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (!_result!.isNotALeaf && !_savedToDb && _isBackendConnected) ...[
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isSavingToDb ? null : _saveToDatabase,
              icon: _isSavingToDb
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(_isSavingToDb ? 'Saving...' : 'Save Result'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Low':
        return AppTheme.statusGood;
      case 'Medium':
        return AppTheme.statusWarning;
      case 'High':
        return AppTheme.statusCritical;
      default:
        return Colors.grey;
    }
  }

  Color _getAirQualityColor(double aqi) {
    if (aqi < 50) return AppTheme.statusGood;
    if (aqi < 100) return AppTheme.accentAmber;
    if (aqi < 150) return AppTheme.statusWarning;
    return AppTheme.statusCritical;
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// Custom painter for scan line animation
class ScanLinePainter extends CustomPainter {
  final double progress;
  final Color color;

  ScanLinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          color.withOpacity(0.5),
          color.withOpacity(0.8),
          color.withOpacity(0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 60));

    final y = size.height * progress;

    canvas.drawRect(
      Rect.fromLTWH(0, y - 30, size.width, 60),
      paint,
    );

    // Draw scan line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(ScanLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
