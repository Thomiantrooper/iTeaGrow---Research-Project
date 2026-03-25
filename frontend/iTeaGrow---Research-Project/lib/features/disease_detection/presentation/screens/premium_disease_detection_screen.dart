import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:iteagrow/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:printing/printing.dart';
import 'dart:typed_data';
import '../services/disease_report_service.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/providers/iot_live_provider.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../data/datasources/disease_detection_ml_service.dart';
import '../../data/datasources/disease_storage_service.dart';
import '../../domain/entities/disease_detection_result.dart';
import '../../domain/entities/disease_leaf_detection.dart';

/// Premium Disease Detection Screen - Modern clean UI
class PremiumDiseaseDetectionScreen extends ConsumerStatefulWidget {
  const PremiumDiseaseDetectionScreen({super.key});

  @override
  ConsumerState<PremiumDiseaseDetectionScreen> createState() =>
      _PremiumDiseaseDetectionScreenState();
}

class _PremiumDiseaseDetectionScreenState
    extends ConsumerState<PremiumDiseaseDetectionScreen> {
  final ImagePicker _picker = ImagePicker();
  final DiseaseDetectionMLService _mlService = DiseaseDetectionMLService();
  final DiseaseStorageService _storageService = DiseaseStorageService();

  XFile? _selectedImage;
  Uint8List? _imageBytes;
  DiseaseDetectionResult? _result;
  List<DiseaseLeafDetection>? _multiDetections; // non-null after multi-leaf scan
  bool _isProcessing = false;
  bool _isBackendConnected = false;
  bool _isCheckingConnection = true;
  bool _savedToDb = false;
  bool _isSavingToDb = false;
  String? _savedDetectionId;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    setState(() => _isCheckingConnection = true);
    await _mlService.initialize();
    if (mounted) {
      setState(() {
        _isBackendConnected = _mlService.isBackendAvailable;
        _isCheckingConnection = false;
      });
    }
  }

  Future<void> _refreshConnection() async {
    setState(() => _isCheckingConnection = true);
    final isConnected = await _mlService.checkBackendConnection();
    if (mounted) {
      setState(() {
        _isBackendConnected = isConnected;
        _isCheckingConnection = false;
      });
      if (isConnected) {
        TeaSnackbar.success(context, AppLocalizations.of(context)!.disease_connected_ml);
      } else {
        TeaSnackbar.warning(context, AppLocalizations.of(context)!.disease_backend_offline_local);
      }
    }
  }

  // ─── IoT Data Accessors ────────────────────────────────────────────────

  double get _liveTemp {
    final mqttState = ref.read(iotLiveProvider);
    final d =
        mqttState.deviceList.isNotEmpty ? mqttState.deviceList.first : null;
    return (d != null && d.hasData && d.temperature != null)
        ? d.temperature!
        : 26.5;
  }

  double get _liveHumidity {
    final mqttState = ref.read(iotLiveProvider);
    final d =
        mqttState.deviceList.isNotEmpty ? mqttState.deviceList.first : null;
    return (d != null && d.hasData && d.humidity != null) ? d.humidity! : 72.0;
  }

  double get _liveAirQuality {
    final mqttState = ref.read(iotLiveProvider);
    final d =
        mqttState.deviceList.isNotEmpty ? mqttState.deviceList.first : null;
    return (d != null && d.hasData && d.airQuality != null)
        ? d.airQuality!.toDouble()
        : 45.0;
  }

  // ─── Image Handling ────────────────────────────────────────────────────

  Future<void> _captureImage() async {
    try {
      final photo = await _picker.pickImage(
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
          _savedDetectionId = null;
        });
      }
    } catch (e) {
      if (mounted) TeaSnackbar.error(context, AppLocalizations.of(context)!.error_camera(e.toString()));
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final image = await _picker.pickImage(
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
          _savedDetectionId = null;
        });
      }
    } catch (e) {
      if (mounted) TeaSnackbar.error(context, AppLocalizations.of(context)!.error_gallery(e.toString()));
    }
  }

  // ─── Analysis ──────────────────────────────────────────────────────────

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    // File type validation
    final path = _selectedImage!.path.toLowerCase();
    final ext = path.contains('.') ? '.${path.split('.').last}' : '';
    if (ext.isNotEmpty &&
        !{'.jpg', '.jpeg', '.png', '.webp', '.bmp'}.contains(ext)) {
      if (mounted) {
        TeaSnackbar.error(
            context, AppLocalizations.of(context)!.disease_unsupported_file(ext));
      }
      return;
    }

    // File size validation
    if (_imageBytes != null) {
      if (_imageBytes!.length < 5 * 1024) {
        if (mounted) {
          TeaSnackbar.error(context,
              AppLocalizations.of(context)!.disease_image_too_small(
                (_imageBytes!.length / 1024).toStringAsFixed(1)));
        }
        return;
      }
      if (_imageBytes!.length > 20 * 1024 * 1024) {
        if (mounted) {
          TeaSnackbar.error(context, AppLocalizations.of(context)!.disease_image_too_large);
        }
        return;
      }
    }

    setState(() {
      _isProcessing = true;
      _savedToDb = false;
      _savedDetectionId = null;
    });

    try {
      final result = await _mlService.predict(
        _selectedImage!.path,
        liveTemperature: _liveTemp,
        liveHumidity: _liveHumidity,
        liveAirQuality: _liveAirQuality,
      );

      if (!mounted) return;

      setState(() {
        _result = result;
        _isProcessing = false;
        _isBackendConnected = _mlService.isBackendAvailable;
      });

      // Auto-save valid detections
      if (!result.isNotALeaf) {
        _saveToDatabase();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        TeaSnackbar.error(context, AppLocalizations.of(context)!.error_analysis_failed(e.toString()));
      }
    }
  }

  Future<void> _saveToDatabase() async {
    if (_result == null || _selectedImage == null || _savedToDb) return;

    setState(() => _isSavingToDb = true);

    try {
      final authState = ref.read(authStateProvider);
      final authToken = authState.accessToken;

      if (authToken == null || authToken.isEmpty) {
        setState(() => _isSavingToDb = false);
        return; // silently skip — user not logged in
      }

      final saved = await _storageService.saveDetectionWithImage(
        result: _result!.copyWith(userId: authState.user?.id),
        imagePath: _selectedImage!.path,
        authToken: authToken,
      );

      if (mounted) {
        if (saved != null) {
          setState(() {
            _savedToDb = true;
            _isSavingToDb = false;
            _savedDetectionId =
                saved['_id']?.toString() ?? saved['id']?.toString();
          });
          TeaSnackbar.success(context, 'Scan saved');
        } else {
          setState(() => _isSavingToDb = false);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isSavingToDb = false);
    }
  }

  Future<void> _generatePdfReport() async {
    if (_result == null || _imageBytes == null) return;
    try {
      final base64Image = base64Encode(_imageBytes!);
      String? base64Heatmap;
      if (_result!.heatmapPath != null) {
        try {
          final heatmapBytes = await File(_result!.heatmapPath!).readAsBytes();
          base64Heatmap = base64Encode(heatmapBytes);
        } catch (_) {}
      }
      final reportData = {
        'detection': {
          'disease_type': _result!.diseaseType,
          'confidence': _result!.confidence,
          'severity': _result!.severity,
          'recommendations': _result!.recommendations,
          'timestamp': _result!.timestamp.toIso8601String(),
          'temperature': _result!.temperature,
          'humidity': _result!.humidity,
          'air_quality': _result!.airQuality,
          'image_data': base64Image,
          if (base64Heatmap != null) 'heatmap_data': base64Heatmap,
          'detections': _result!.detections
              ?.map((d) => {
                    'class_name': d.className,
                    'confidence': d.confidence,
                    'area_percentage': d.areaPercentage,
                  })
              .toList(),
          'summary': _result!.summary?.toJson(),
        },
        'farmer': {'name': 'Current User', 'location': 'Tea Plantation'},
        'organization': {
          'name': 'iTeaGrow',
          'description': 'Tea Plantation Management System',
        },
        'report_id':
            'DD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        'generated_at': DateTime.now().toIso8601String(),
      };
      final pdfBytes = await DiseaseReportService().generateReport(reportData);
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'tea_disease_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${AppLocalizations.of(context)!.disease_generate_report_failed}: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // ─── Multi-leaf analysis (single photo, multiple leaves) ─────────────────

  Future<void> _analyzeMultiple() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _multiDetections = null;
      _result = null;
      _savedToDb = false;
      _savedDetectionId = null;
    });

    try {
      final detections = await _mlService.predictMultiple(
        _selectedImage!.path,
        liveTemperature: _liveTemp,
        liveHumidity: _liveHumidity,
        liveAirQuality: _liveAirQuality,
      );

      if (!mounted) return;
      setState(() {
        _multiDetections = detections;
        _isProcessing = false;
        _isBackendConnected = _mlService.isBackendAvailable;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        TeaSnackbar.error(context, 'Multi-leaf analysis failed: $e');
      }
    }
  }

  void _resetScan() {
    setState(() {
      _selectedImage = null;
      _imageBytes = null;
      _result = null;
      _multiDetections = null;
      _savedToDb = false;
      _savedDetectionId = null;
    });
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.watch(iotLiveProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F7),
      body: Stack(
        children: [
          // Soft background shapes
          _buildBackgroundShapes(),

          // Main content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),

                    // Live environment
                    _buildEnvironmentRow(),
                    const SizedBox(height: 24),

                    // Image area
                    if (_selectedImage == null)
                      _buildUploadArea()
                    else
                      _buildImagePreview(),

                    const SizedBox(height: 16),

                    // Action buttons
                    _buildActions(),

                    // Multi-leaf results
                    if (_multiDetections != null) ...[
                      const SizedBox(height: 24),
                      _buildMultiLeafSummary(_multiDetections!),
                    ],

                    // Single-leaf results (existing flow — untouched)
                    if (_result != null) ...[
                      const SizedBox(height: 24),
                      _buildResultCard(),
                      const SizedBox(height: 16),
                      _buildConfidenceDetails(),
                      const SizedBox(height: 16),
                      _buildRecommendations(),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _generatePdfReport,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: Text(AppLocalizations.of(context)!.common_generate_report),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TeaColors.freshLeaf,
                          side: const BorderSide(color: TeaColors.freshLeaf),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      if (_savedToDb && _savedDetectionId != null) ...[
                        const SizedBox(height: 16),
                        _buildPostScanActions(),
                      ],
                    ],

                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Background ────────────────────────────────────────────────────────

  Widget _buildBackgroundShapes() {
    return Stack(
      children: [
        Positioned(
          top: -60,
          right: -40,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                TeaColors.freshLeaf.withOpacity(0.06),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: 200,
          left: -60,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                TeaColors.goldenSunlight.withOpacity(0.05),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ],
    );
  }

  // ─── App Bar ───────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 60,
      floating: true,
      pinned: true,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.white.withOpacity(0.95),
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F9F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_rounded,
              color: TeaColors.nearBlack, size: 20),
        ),
      ),
      title: Text(
        AppLocalizations.of(context)!.disease_title,
        style: TeaTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
      ),
      actions: [
        if (_selectedImage != null)
          GestureDetector(
            onTap: _resetScan,
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F9F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: TeaColors.nearBlack, size: 20),
            ),
          ),
        const SizedBox(width: 8),
        // Connection Status
        GestureDetector(
          onTap: _refreshConnection,
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F9F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isCheckingConnection
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: TeaColors.nearBlack,
                    ),
                  )
                : Icon(
                    _isBackendConnected
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_off_rounded,
                    color: _isBackendConnected
                        ? TeaColors.healthyGreen
                        : TeaColors.warningAmber,
                    size: 20,
                  ),
          ),
        ),
        const SizedBox(width: 8),
        // History
        GestureDetector(
          onTap: () => context.push('/scan-history'),
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F9F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.history_rounded,
                color: TeaColors.nearBlack, size: 20),
          ),
        ),
      ],
    );
  }

  // ─── Environment Row ───────────────────────────────────────────────────

  Widget _buildEnvironmentRow() {
    final mqttState = ref.watch(iotLiveProvider);
    final d =
        mqttState.deviceList.isNotEmpty ? mqttState.deviceList.first : null;
    final hasData = d != null && d.hasData;

    final temp = hasData && d.temperature != null
        ? '${d.temperature!.toStringAsFixed(1)}°C'
        : '--';
    final humidity = hasData && d.humidity != null ? '${d.humidity}%' : '--';

    return Row(
      children: [
        Expanded(
          child: _buildEnvChip(Icons.thermostat_outlined, temp, AppLocalizations.of(context)!.disease_temp_label,
              const Color(0xFFFF8A65), const Color(0xFFFFF3E0)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildEnvChip(Icons.water_drop_outlined, humidity, AppLocalizations.of(context)!.sensor_humidity,
              const Color(0xFF42A5F5), const Color(0xFFE3F2FD)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: hasData
                  ? TeaColors.healthyGreen.withOpacity(0.08)
                  : Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        hasData ? TeaColors.healthyGreen : TeaColors.mediumGray,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  hasData ? AppLocalizations.of(context)!.disease_live_label : AppLocalizations.of(context)!.disease_default_label,
                  style: TeaTypography.labelSmall.copyWith(
                    color:
                        hasData ? TeaColors.healthyGreen : TeaColors.mediumGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
  }

  Widget _buildEnvChip(
      IconData icon, String value, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TeaTypography.titleSmall
                        .copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(label,
                    style: TeaTypography.labelSmall
                        .copyWith(color: TeaColors.darkGray, fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Upload Area ───────────────────────────────────────────────────────

  Widget _buildUploadArea() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: TeaColors.freshLeaf.withOpacity(0.2),
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  TeaColors.freshLeaf.withOpacity(0.1),
                  TeaColors.freshLeaf.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.document_scanner_outlined,
                size: 36, color: TeaColors.freshLeaf),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.disease_placeholder_title,
            style: TeaTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: TeaColors.matureLeaf,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              AppLocalizations.of(context)!.disease_scan_instructions,
              textAlign: TextAlign.center,
              style: TeaTypography.bodySmall.copyWith(
                color: TeaColors.darkGray,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(
        begin: const Offset(0.97, 0.97),
        end: const Offset(1, 1),
        duration: 400.ms);
  }

  // ─── Image Preview ─────────────────────────────────────────────────────

  Widget _buildImagePreview() {
    if (_imageBytes == null) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: TeaColors.freshLeaf),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.memory(
              _imageBytes!,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          // Processing overlay
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.disease_analyzing,
                      style: TeaTypography.titleSmall
                          .copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isBackendConnected
                          ? AppLocalizations.of(context)!.disease_sending_to_ai
                          : AppLocalizations.of(context)!.disease_running_local,
                      style: TeaTypography.labelSmall.copyWith(
                        color: Colors.white.withOpacity(0.6),
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

  // ─── Action Buttons ────────────────────────────────────────────────────

  Widget _buildActions() {
    if (_selectedImage == null) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildActionBtn(
                      AppLocalizations.of(context)!.common_camera,
                      Icons.camera_alt_rounded,
                      const [TeaColors.freshLeaf, TeaColors.matureLeaf],
                      _captureImage)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildActionBtn(AppLocalizations.of(context)!.common_gallery, Icons.photo_library_rounded,
                      [Colors.white, Colors.white], _pickFromGallery,
                      outlined: true)),
            ],
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 16),
          // Helper Tip
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TeaColors.infoSky.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TeaColors.infoSky.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: TeaColors.infoSky, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.disease_multi_tip,
                    style: TeaTypography.bodySmall.copyWith(color: TeaColors.darkGray, height: 1.4),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      );
    }

    if (_result == null) {
      return GestureDetector(
        onTap: _isProcessing ? null : _analyzeImage,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: _isProcessing
                ? LinearGradient(colors: [
                    TeaColors.mediumGray,
                    TeaColors.mediumGray.withOpacity(0.8)
                  ])
                : const LinearGradient(
                    colors: [TeaColors.freshLeaf, TeaColors.matureLeaf]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: _isProcessing
                ? []
                : [
                    BoxShadow(
                      color: TeaColors.freshLeaf.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isProcessing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              else
                const Icon(Icons.search_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                _isProcessing ? AppLocalizations.of(context)!.disease_scanning : AppLocalizations.of(context)!.disease_analyze_leaf,
                style: TeaTypography.buttonMedium
                    .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 100.ms);
    }

    if (_result == null && _multiDetections == null) {
      return Column(
        children: [
          // Single-leaf Analyze button
          GestureDetector(
            onTap: _isProcessing ? null : _analyzeImage,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: _isProcessing
                    ? LinearGradient(colors: [
                        TeaColors.mediumGray,
                        TeaColors.mediumGray.withOpacity(0.8)
                      ])
                    : const LinearGradient(
                        colors: [TeaColors.freshLeaf, TeaColors.matureLeaf]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: _isProcessing
                    ? []
                    : [
                        BoxShadow(
                          color: TeaColors.freshLeaf.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isProcessing)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.search_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    _isProcessing
                        ? AppLocalizations.of(context)!.disease_scanning
                        : AppLocalizations.of(context)!.disease_analyze_leaf,
                    style: TeaTypography.buttonMedium
                        .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Multi-leaf Analyze button
          GestureDetector(
            onTap: _isProcessing ? null : _analyzeMultiple,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: _isProcessing
                        ? TeaColors.mediumGray.withOpacity(0.3)
                        : TeaColors.freshLeaf.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.view_comfy_rounded,
                    color: _isProcessing
                        ? TeaColors.mediumGray
                        : TeaColors.freshLeaf,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.disease_scan_multiple,
                    style: TeaTypography.buttonMedium.copyWith(
                      color: _isProcessing
                          ? TeaColors.mediumGray
                          : TeaColors.freshLeaf,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ).animate().fadeIn(delay: 100.ms);
    }

    // After results — new scan
    return GestureDetector(
      onTap: _resetScan,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TeaColors.freshLeaf.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.refresh_rounded,
                color: TeaColors.freshLeaf, size: 20),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.disease_new_scan,
              style: TeaTypography.buttonMedium.copyWith(
                color: TeaColors.freshLeaf,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildActionBtn(
      String label, IconData icon, List<Color> colors, VoidCallback onTap,
      {bool outlined = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: outlined ? null : LinearGradient(colors: colors),
          color: outlined ? Colors.white : null,
          borderRadius: BorderRadius.circular(18),
          border: outlined
              ? Border.all(color: TeaColors.freshLeaf.withOpacity(0.3))
              : null,
          boxShadow: outlined
              ? []
              : [
                  BoxShadow(
                    color: colors.first.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: outlined ? TeaColors.freshLeaf : Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TeaTypography.buttonMedium.copyWith(
                color: outlined ? TeaColors.freshLeaf : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Result Card ───────────────────────────────────────────────────────

  String _getLocalizedReliabilityLabel(AppLocalizations l10n) {
    if (_result == null) return l10n.disease_reliability_moderate;
    final c = _result!.confidence;
    if (c >= 0.85) return l10n.disease_reliability_very_high;
    if (c >= 0.70) return l10n.disease_reliability_high;
    if (c >= 0.50) return l10n.disease_reliability_moderate;
    if (c >= 0.30) return l10n.disease_reliability_low_level;
    return l10n.disease_reliability_very_low;
  }

  String _getLocalizedSeverity(String severity, AppLocalizations l10n) {
    switch (severity) {
      case 'Low': return l10n.disease_low;
      case 'Medium': return l10n.disease_medium;
      case 'High': return l10n.disease_high;
      default: return severity;
    }
  }

  Widget _buildResultCard() {
    if (_result == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final isHealthy = _result!.isHealthy;
    final isNotALeaf = _result!.isNotALeaf;

    final Color statusColor;
    final IconData statusIcon;
    final String statusLabel;
    final String statusDesc;

    final isUnavailable = _result!.diseaseType == 'Unavailable';

    if (isUnavailable) {
      statusColor = TeaColors.mediumGray;
      statusIcon = Icons.cloud_off_rounded;
      statusLabel = l10n.disease_backend_offline;
      statusDesc = l10n.disease_backend_offline_desc;
    } else if (isNotALeaf) {
      statusColor = TeaColors.warningAmber;
      statusIcon = Icons.image_not_supported_rounded;
      statusLabel = l10n.disease_not_tea_leaf;
      statusDesc = _result!.validationMessage ?? l10n.disease_not_leaf_desc;
    } else if (isHealthy) {
      statusColor = TeaColors.healthyGreen;
      statusIcon = Icons.check_circle_rounded;
      statusLabel = l10n.disease_healthy_label;
      statusDesc = l10n.disease_no_diseases;
    } else {
      statusColor = TeaColors.alertRust;
      statusIcon = Icons.warning_rounded;
      statusLabel = _result!.diseaseType;
      statusDesc = l10n.disease_detected_with_confidence(_getLocalizedReliabilityLabel(l10n));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.08),
                  statusColor.withOpacity(0.03),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusLabel,
                        style: TeaTypography.headlineSmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusDesc,
                        style: TeaTypography.bodySmall.copyWith(
                          color: TeaColors.darkGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // False positive warning
          if (_result!.isPotentialFalsePositive && !isNotALeaf)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TeaColors.warningAmber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: TeaColors.warningAmber.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wb_sunny_outlined,
                      color: TeaColors.warningAmber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.disease_false_positive_warning,
                      style: TeaTypography.labelSmall.copyWith(
                        color: TeaColors.darkGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // DB save status
          if (_isSavingToDb || _savedToDb)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  if (_isSavingToDb)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: TeaColors.freshLeaf),
                    )
                  else
                    const Icon(Icons.cloud_done_rounded,
                        size: 16, color: TeaColors.healthyGreen),
                  const SizedBox(width: 8),
                  Text(
                    _isSavingToDb ? l10n.disease_saving : l10n.disease_saved,
                    style: TeaTypography.labelSmall.copyWith(
                      color: _isSavingToDb
                          ? TeaColors.freshLeaf
                          : TeaColors.healthyGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  // ─── Confidence Details ────────────────────────────────────────────────

  Widget _buildConfidenceDetails() {
    if (_result == null || _result!.isNotALeaf) return const SizedBox.shrink();

    final confidence = _result!.confidence;
    final pct = (confidence * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.disease_detection_metrics,
              style: TeaTypography.titleSmall
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),

          // Confidence bar
          Row(
            children: [
              Text(AppLocalizations.of(context)!.common_confidence, style: TeaTypography.bodySmall),
              const Spacer(),
              Text('$pct%',
                  style: TeaTypography.titleSmall
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: confidence,
              minHeight: 8,
              backgroundColor: Colors.grey.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(
                confidence >= 0.85
                    ? TeaColors.healthyGreen
                    : confidence >= 0.70
                        ? TeaColors.freshLeaf
                        : confidence >= 0.50
                            ? TeaColors.warningAmber
                            : TeaColors.alertRust,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.disease_reliability_display(_getLocalizedReliabilityLabel(AppLocalizations.of(context)!)),
            style: TeaTypography.labelSmall.copyWith(color: TeaColors.darkGray),
          ),

          const SizedBox(height: 16),

          // Detail chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDetailChip(
                  AppLocalizations.of(context)!.disease_severity,
                  _getLocalizedSeverity(_result!.severity, AppLocalizations.of(context)!),
                  _result!.severity == 'High'
                      ? TeaColors.alertRust
                      : _result!.severity == 'Medium'
                          ? TeaColors.warningAmber
                          : TeaColors.healthyGreen),
              if (_result!.processingTimeMs != null)
                _buildDetailChip(
                    AppLocalizations.of(context)!.disease_processing_label,
                    '${_result!.processingTimeMs!.toStringAsFixed(0)} ms',
                    TeaColors.infoSky),
              if (_result!.imageQualityScore != null)
                _buildDetailChip(
                    AppLocalizations.of(context)!.disease_image_quality_label,
                    '${(_result!.imageQualityScore! * 100).toStringAsFixed(0)}%',
                    TeaColors.freshLeaf),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  Widget _buildDetailChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style:
                  TeaTypography.labelSmall.copyWith(color: TeaColors.darkGray)),
          const SizedBox(width: 6),
          Text(value,
              style: TeaTypography.labelMedium
                  .copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ─── Recommendations ───────────────────────────────────────────────────

  Widget _buildRecommendations() {
    if (_result == null || _result!.recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: TeaColors.freshLeaf.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lightbulb_outline_rounded,
                    color: TeaColors.freshLeaf, size: 16),
              ),
              const SizedBox(width: 10),
              Text(AppLocalizations.of(context)!.disease_recommendations,
                  style: TeaTypography.titleSmall
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(_result!.recommendations.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: TeaColors.freshLeaf.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: TeaColors.freshLeaf,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _result!.recommendations[i],
                      style: TeaTypography.bodySmall.copyWith(
                        color: TeaColors.nearBlack,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  // ─── Multi-Leaf Summary ────────────────────────────────────────────────

  Widget _buildMultiLeafSummary(List<DiseaseLeafDetection> detections) {
    if (detections.isEmpty) return const SizedBox.shrink();

    int healthyCount = 0;
    int redRustCount = 0;
    int blisterBlightCount = 0;
    int otherCount = 0;

    for (final d in detections) {
      if (d.result.diseaseType == 'Healthy' || d.result.diseaseType == 'Not A Leaf') {
        healthyCount++;
      } else if (d.result.diseaseType == 'Red Rust') {
        redRustCount++;
      } else if (d.result.diseaseType == 'Blister Blight') {
        blisterBlightCount++;
      } else {
        otherCount++;
      }
    }

    final total = detections.length;
    final infectedCount = total - healthyCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: infectedCount > 0 ? TeaColors.criticalRed : TeaColors.healthyGreen,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                infectedCount > 0 ? Icons.warning_rounded : Icons.check_circle_rounded,
                color: infectedCount > 0 ? TeaColors.criticalRed : TeaColors.healthyGreen,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.disease_scanned_leaves(total.toString()),
                style: TeaTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (infectedCount == 0)
                Text(
                  AppLocalizations.of(context)!.disease_all_healthy,
                  style: TeaTypography.bodyMedium.copyWith(color: TeaColors.darkGray),
                )
              else
                Text(
                  AppLocalizations.of(context)!.disease_infected_healthy(infectedCount.toString(), healthyCount.toString()),
                  style: TeaTypography.bodyMedium.copyWith(color: TeaColors.criticalRed, fontWeight: FontWeight.w600),
                ),
              if (redRustCount > 0 || blisterBlightCount > 0 || otherCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (redRustCount > 0) _buildSummaryChip(AppLocalizations.of(context)!.disease_red_rust_count(redRustCount.toString()), TeaColors.warningAmber),
                      if (redRustCount > 0 && blisterBlightCount > 0) const SizedBox(width: 8),
                      if (blisterBlightCount > 0) _buildSummaryChip(AppLocalizations.of(context)!.disease_blight_count(blisterBlightCount.toString()), TeaColors.criticalRed),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Individual leaves expandable
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(AppLocalizations.of(context)!.disease_individual_details,
                style: TeaTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
            collapsedBackgroundColor: Colors.white,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            children: detections.map((det) {
              final isHealthy = det.result.diseaseType == 'Healthy' || det.result.diseaseType == 'Not A Leaf';
              final color = isHealthy ? TeaColors.healthyGreen : TeaColors.criticalRed;
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F9F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${det.index + 1}',
                            style: TextStyle(fontWeight: FontWeight.w700, color: color)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(det.result.diseaseType,
                              style: TeaTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                          Text(AppLocalizations.of(context)!.disease_confidence_percent((det.result.confidence * 100).toStringAsFixed(1)),
                              style: TeaTypography.labelSmall.copyWith(color: TeaColors.darkGray)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildSummaryChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  // ─── Post-Scan Actions ─────────────────────────────────────────────────

  Widget _buildPostScanActions() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/reports/preview/$_savedDetectionId'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TeaColors.freshLeaf.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.description_outlined,
                      color: TeaColors.freshLeaf, size: 18),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context)!.disease_view_report,
                      style: TeaTypography.labelMedium.copyWith(
                          color: TeaColors.freshLeaf,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/scan-history'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TeaColors.infoSky.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_rounded,
                      color: TeaColors.infoSky, size: 18),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context)!.common_history,
                      style: TeaTypography.labelMedium.copyWith(
                          color: TeaColors.infoSky,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms, delay: 300.ms);
  }
}
