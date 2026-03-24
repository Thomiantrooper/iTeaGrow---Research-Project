import 'package:flutter/material.dart';
import 'package:iteagrow/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:printing/printing.dart';
import 'dart:typed_data';
import '../services/disease_report_service.dart';
import '../../../../core/theme/jarvis_theme.dart';
import '../../../../core/widgets/hologram_card.dart';
import '../../../../core/widgets/floating_tea_leaf.dart';
import '../../../../core/services/ai_assistant_service.dart';
import '../../../../core/services/voice_service.dart';
import '../../../../core/providers/iot_live_provider.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../data/datasources/disease_detection_ml_service.dart';
import '../../data/datasources/disease_storage_service.dart';
import '../../data/datasources/leaf_validation_service.dart';
import '../../data/datasources/multi_leaf_scan_service.dart';
import '../../domain/entities/disease_detection_result.dart';
import '../../domain/entities/disease_leaf_detection.dart';

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
  final LeafValidationService _validationService = LeafValidationService();
  final MultiLeafScanService _multiLeafService = MultiLeafScanService();

  XFile? _selectedImage;
  Uint8List? _imageBytes;
  DiseaseDetectionResult? _result;
  List<DiseaseLeafDetection>? _multiDetections;
  bool _isProcessing = false;
  bool _isValidating = false;
  bool _isBackendConnected = false;
  bool _isCheckingConnection = true;
  bool _savedToDb = false;
  bool _isSavingToDb = false;

  // Multi-leaf session state
  bool _isMultiLeafMode = false;
  bool _showSessionSummary = false;
  MultiLeafSummary? _sessionSummary;

  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _initializeService();

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

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Image capture & validation
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _captureImage() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (photo != null) await _onImageSelected(photo);
    } catch (e) {
      _showError(AppLocalizations.of(context)!.error_camera(e.toString()));
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
      if (image != null) await _onImageSelected(image);
    } catch (e) {
      _showError(AppLocalizations.of(context)!.error_gallery(e.toString()));
    }
  }

  /// Common handler after image is picked. Runs pre-scan validation.
  Future<void> _onImageSelected(XFile file) async {
    final bytes = await file.readAsBytes();

    setState(() {
      _selectedImage = file;
      _imageBytes = bytes;
      _result = null;
      _savedToDb = false;
      _isValidating = true;
    });

    // Pre-scan validation
    final validation = await _validationService.validate(bytes);

    if (!mounted) return;

    setState(() => _isValidating = false);

    if (!validation.isValid) {
      _showRescanDialog(validation.message);
      setState(() {
        _selectedImage = null;
        _imageBytes = null;
      });
    }
  }

  /// Show a dialog prompting the user to rescan with a clearer leaf image.
  void _showRescanDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.image_not_supported_outlined,
            color: JarvisTheme.warning, size: 48),
        title: Text(AppLocalizations.of(context)!.disease_please_rescan),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _captureImage();
            },
            icon: const Icon(Icons.camera_alt),
            label: Text(AppLocalizations.of(context)!.disease_retake_photo),
            style: FilledButton.styleFrom(
              backgroundColor: JarvisTheme.teaGreen,
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _pickFromGallery();
            },
            icon: const Icon(Icons.photo_library),
            label: Text(AppLocalizations.of(context)!.common_gallery),
            style: OutlinedButton.styleFrom(
              foregroundColor: JarvisTheme.teaGreen,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Analysis
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _savedToDb = false;
    });
    _scanController.repeat();

    try {
      // Get live IoT data
      final iotState = ref.read(iotLiveProvider);
      final temp = (iotState.devices.isNotEmpty &&
              iotState.devices.values.first.temperature != null)
          ? iotState.devices.values.first.temperature!
          : 26.5;
      final humidity = (iotState.devices.isNotEmpty &&
              iotState.devices.values.first.humidity != null)
          ? iotState.devices.values.first.humidity!
          : 72.0;

      final result = await _mlService.predict(
        _selectedImage!.path,
        liveTemperature: temp,
        liveHumidity: humidity,
      );

      setState(() {
        _result = result;
        _isProcessing = false;
        _isBackendConnected = _mlService.isBackendAvailable;
      });
      _scanController.stop();
      _scanController.reset();

      // Update AI assistant context
      ref
          .read(aiAssistantProvider.notifier)
          .updateDiseaseContext(result.diseaseType);

      // In multi-leaf mode, add scan to session
      if (_isMultiLeafMode && !result.isNotALeaf && _imageBytes != null) {
        _multiLeafService.addScan(
          imageBytes: _imageBytes!,
          imagePath: _selectedImage!.path,
          result: result,
        );
      }

      // Auto-save to database if connected and valid leaf
      if (_isBackendConnected && !result.isNotALeaf) {
        _saveToDatabase();
      }

      // Auto-generate PDF for single-leaf mode (non multi-leaf)
      if (!_isMultiLeafMode && !result.isNotALeaf) {
        _autoGeneratePdfReport();
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _scanController.stop();
      _showError(AppLocalizations.of(context)!.error_analysis(e.toString()));
    }
  }

  Future<void> _analyzeMultiple() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _savedToDb = false;
      _multiDetections = null;
      _result = null;
    });
    _scanController.repeat();

    try {
      final iotState = ref.read(iotLiveProvider);
      final temp = (iotState.devices.isNotEmpty && iotState.devices.values.first.temperature != null)
          ? iotState.devices.values.first.temperature!
          : 26.5;
      final humidity = (iotState.devices.isNotEmpty && iotState.devices.values.first.humidity != null)
          ? iotState.devices.values.first.humidity!
          : 72.0;

      final detections = await _mlService.predictMultiple(
        _selectedImage!.path,
        liveTemperature: temp,
        liveHumidity: humidity,
      );

      if (!mounted) return;
      setState(() {
        _multiDetections = detections;
        _isProcessing = false;
        _isBackendConnected = _mlService.isBackendAvailable;
      });
      _scanController.stop();
      _scanController.reset();

      // We skip session tracking and auto-save for auto-multiple-leaf for now,
      // focusing purely on UI display of the grouped results.
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _scanController.stop();
      _showError('Multi-leaf analysis failed: $e');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Multi-leaf session
  // ───────────────────────────────────────────────────────────────────────────

  void _toggleMultiLeafMode() {
    setState(() {
      _isMultiLeafMode = !_isMultiLeafMode;
      _showSessionSummary = false;
      _sessionSummary = null;
      if (_isMultiLeafMode) {
        _multiLeafService.startSession();
      } else {
        _multiLeafService.clearSession();
      }
    });
    if (_isMultiLeafMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.eco, color: Colors.white),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.disease_multi_leaf_active),
          ]),
          backgroundColor: JarvisTheme.teaGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _addAnotherLeaf() {
    setState(() {
      _selectedImage = null;
      _imageBytes = null;
      _result = null;
      _multiDetections = null;
      _savedToDb = false;
    });
  }

  void _finishSession() {
    final summary = _multiLeafService.generateSummary();
    setState(() {
      _sessionSummary = summary;
      _showSessionSummary = true;
    });
    // Auto-generate multi-leaf PDF
    _autoGenerateMultiLeafPdfReport(summary);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PDF Reports
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _autoGeneratePdfReport() async {
    if (_result == null || _imageBytes == null) return;
    try {
      final pdfBytes = await _buildSingleLeafPdf();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.picture_as_pdf, color: Colors.white),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.disease_pdf_generated),
          ]),
          backgroundColor: JarvisTheme.teaGreen,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'VIEW',
            textColor: Colors.white,
            onPressed: () => _showPdf(pdfBytes),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Auto PDF generation failed: $e');
    }
  }

  Future<void> _autoGenerateMultiLeafPdfReport(MultiLeafSummary summary) async {
    try {
      final iotState = ref.read(iotLiveProvider);
      final temp = (iotState.devices.isNotEmpty &&
              iotState.devices.values.first.temperature != null)
          ? iotState.devices.values.first.temperature!
          : 26.5;
      final humidity = (iotState.devices.isNotEmpty &&
              iotState.devices.values.first.humidity != null)
          ? iotState.devices.values.first.humidity!
          : 72.0;

      final pdfBytes = await DiseaseReportService().generateMultiLeafReport(
        entries: _multiLeafService.entries,
        summary: summary,
        temperature: temp,
        humidity: humidity,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.picture_as_pdf, color: Colors.white),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.disease_multi_leaf_pdf_ready),
          ]),
          backgroundColor: JarvisTheme.teaGreen,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'VIEW',
            textColor: Colors.white,
            onPressed: () => _showPdf(pdfBytes),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Multi-leaf PDF generation failed: $e');
    }
  }

  Future<Uint8List> _buildSingleLeafPdf() async {
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
    return DiseaseReportService().generateReport(reportData);
  }

  Future<void> _generatePdfReport() async {
    if (_result == null || _imageBytes == null) return;
    try {
      final pdfBytes = await _buildSingleLeafPdf();
      _showPdf(pdfBytes);
    } catch (e) {
      _showError(AppLocalizations.of(context)!.error_report_failed(e.toString()));
    }
  }

  Future<void> _generateMultiLeafPdfReport() async {
    if (_sessionSummary == null) return;
    try {
      final iotState = ref.read(iotLiveProvider);
      final temp = (iotState.devices.isNotEmpty &&
              iotState.devices.values.first.temperature != null)
          ? iotState.devices.values.first.temperature!
          : 26.5;
      final humidity = (iotState.devices.isNotEmpty &&
              iotState.devices.values.first.humidity != null)
          ? iotState.devices.values.first.humidity!
          : 72.0;

      final pdfBytes = await DiseaseReportService().generateMultiLeafReport(
        entries: _multiLeafService.entries,
        summary: _sessionSummary!,
        temperature: temp,
        humidity: humidity,
      );
      _showPdf(pdfBytes);
    } catch (e) {
      _showError(AppLocalizations.of(context)!.disease_multi_leaf_report_failed(e.toString()));
    }
  }

  void _showPdf(Uint8List pdfBytes) {
    Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'tea_disease_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Database
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _saveToDatabase() async {
    if (_result == null || _selectedImage == null || _savedToDb) return;

    setState(() => _isSavingToDb = true);

    try {
      final authState = ref.read(authStateProvider);
      final authToken = authState.accessToken;

      if (authToken == null || authToken.isEmpty) {
        setState(() => _isSavingToDb = false);
        return;
      }

      final savedResult = await _storageService.saveDetectionWithImage(
        result: _result!.copyWith(userId: authState.user?.id),
        imagePath: _selectedImage!.path,
        authToken: authToken,
      );

      if (savedResult != null) {
        setState(() {
          _savedToDb = true;
          _isSavingToDb = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.disease_scan_saved),
              ]),
              backgroundColor: JarvisTheme.healthy,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        setState(() => _isSavingToDb = false);
      }
    } catch (e) {
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

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JarvisTheme.mistWhite,
      body: Stack(
        children: [
          const FloatingLeavesBackground(leafCount: 3, showDiseased: true),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.all(JarvisTheme.spacingMd),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Live Environment Status
                      _buildEnvironmentCard(),
                      const SizedBox(height: JarvisTheme.spacingLg),

                      // Multi-leaf mode toggle
                      _buildMultiLeafToggle(),
                      const SizedBox(height: JarvisTheme.spacingMd),

                      // Multi-leaf session progress
                      if (_isMultiLeafMode && _multiLeafService.hasScans)
                        _buildSessionProgress(),
                      if (_isMultiLeafMode && _multiLeafService.hasScans)
                        const SizedBox(height: JarvisTheme.spacingMd),

                      // Session Summary (after finishing)
                      if (_showSessionSummary && _sessionSummary != null) ...[
                        _buildSessionSummaryCard(),
                        const SizedBox(height: JarvisTheme.spacingMd),
                        _buildSessionRecommendationsCard(),
                        const SizedBox(height: JarvisTheme.spacingMd),
                        Row(children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _generateMultiLeafPdfReport,
                              icon: const Icon(Icons.picture_as_pdf),
                              label: Text(AppLocalizations.of(context)!.disease_view_pdf_report),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: JarvisTheme.healthy,
                                side: const BorderSide(
                                    color: JarvisTheme.healthy),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                _multiLeafService.clearSession();
                                setState(() {
                                  _showSessionSummary = false;
                                  _sessionSummary = null;
                                  _isMultiLeafMode = false;
                                  _selectedImage = null;
                                  _imageBytes = null;
                                  _result = null;
                                });
                              },
                              icon: const Icon(Icons.refresh),
                              label: Text(AppLocalizations.of(context)!.disease_new_session),
                              style: FilledButton.styleFrom(
                                backgroundColor: JarvisTheme.teaGreen,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: JarvisTheme.spacingXxl),
                      ],

                      // Image Section (hide when showing session summary)
                      if (!_showSessionSummary) ...[
                        _buildImageSection(),
                        const SizedBox(height: JarvisTheme.spacingLg),

                        // Validation indicator
                        if (_isValidating) _buildValidatingIndicator(),

                        // Action Buttons
                        if (_selectedImage == null && !_isValidating)
                          Column(
                            children: [
                              _buildCaptureButtons(),
                              const SizedBox(height: JarvisTheme.spacingMd),
                              // Helper Tip
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!.disease_multi_tip,
                                        style: const TextStyle(color: JarvisTheme.textSecondary, fontSize: 13, height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        if (_selectedImage != null && _result == null && _multiDetections == null)
                          Column(
                            children: [
                              _buildAnalyzeButton(),
                              const SizedBox(height: JarvisTheme.spacingMd),
                              _buildAnalyzeMultipleButton(),
                            ],
                          ),

                        // Multi-leaf results
                        if (_multiDetections != null) ...[
                          const SizedBox(height: JarvisTheme.spacingLg),
                          _buildMultiLeafSummary(_multiDetections!),
                          const SizedBox(height: JarvisTheme.spacingMd),
                          OutlinedButton.icon(
                            onPressed: _addAnotherLeaf,
                            icon: const Icon(Icons.refresh),
                            label: Text(AppLocalizations.of(context)!.common_try_again),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: JarvisTheme.healthy,
                              side: const BorderSide(color: JarvisTheme.healthy),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],

                        // Results
                        if (_result != null) ...[
                          const SizedBox(height: JarvisTheme.spacingLg),
                          _buildResultCard(),
                          const SizedBox(height: JarvisTheme.spacingMd),
                          _buildRecommendationsCard(),
                          const SizedBox(height: JarvisTheme.spacingMd),

                          // Action buttons after result
                          if (_isMultiLeafMode && !_result!.isNotALeaf)
                            _buildMultiLeafActions()
                          else if (!_result!.isNotALeaf)
                            OutlinedButton.icon(
                              onPressed: _generatePdfReport,
                              icon: const Icon(Icons.picture_as_pdf),
                              label: Text(AppLocalizations.of(context)!.disease_view_pdf_report),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: JarvisTheme.healthy,
                                side: const BorderSide(
                                    color: JarvisTheme.healthy),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                        ],
                        const SizedBox(height: JarvisTheme.spacingXxl),
                      ],
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

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

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
              colors: [
                JarvisTheme.critical,
                JarvisTheme.critical.withOpacity(0.8)
              ],
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
                  color:
                      _isBackendConnected ? JarvisTheme.healthy : Colors.orange,
                ),
          onPressed: _initializeService,
        ),
      ],
    );
  }

  Widget _buildEnvironmentCard() {
    return Consumer(
      builder: (context, ref, child) {
        final iotState = ref.watch(iotLiveProvider);
        final temp = (iotState.devices.isNotEmpty &&
                iotState.devices.values.first.temperature != null)
            ? iotState.devices.values.first.temperature!
            : 26.5;
        final humidity = (iotState.devices.isNotEmpty &&
                iotState.devices.values.first.humidity != null)
            ? iotState.devices.values.first.humidity!
            : 72.0;

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
                      iotState.devices.isNotEmpty
                          ? 'IoTENV'
                          : 'Fallback values',
                      style: TextStyle(
                        fontSize: 12,
                        color: iotState.devices.isNotEmpty
                            ? Colors.green
                            : JarvisTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _buildMetricChip(Icons.thermostat,
                  '${temp.toStringAsFixed(1)}\u00b0C', Colors.deepOrange),
              const SizedBox(width: 8),
              _buildMetricChip(
                  Icons.water_drop, '${humidity.toString()}%', Colors.blue),
            ],
          ),
        );
      },
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

  Widget _buildMultiLeafToggle() {
    return HologramCard(
      enableGlow: false,
      padding: const EdgeInsets.symmetric(
          horizontal: JarvisTheme.spacingMd, vertical: 10),
      child: Row(
        children: [
          Icon(
            _isMultiLeafMode ? Icons.grid_view_rounded : Icons.crop_original,
            color:
                _isMultiLeafMode ? JarvisTheme.teaGreen : JarvisTheme.textMuted,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Multi-Leaf Scan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: JarvisTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _isMultiLeafMode
                      ? '${_multiLeafService.leafCount} leaf${_multiLeafService.leafCount != 1 ? 'es' : ''} scanned'
                      : 'Scan multiple leaves from the same plant',
                  style: const TextStyle(
                    fontSize: 12,
                    color: JarvisTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isMultiLeafMode,
            onChanged:
                _showSessionSummary ? null : (_) => _toggleMultiLeafMode(),
            activeColor: JarvisTheme.teaGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionProgress() {
    final entries = _multiLeafService.entries;
    return HologramCard(
      enableGlow: false,
      padding: const EdgeInsets.all(JarvisTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco, color: JarvisTheme.teaGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Session: ${entries.length} leaf${entries.length != 1 ? 'es' : ''} scanned',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: JarvisTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entries.map((e) {
              final color = e.result.diseaseType == 'Healthy'
                  ? JarvisTheme.healthy
                  : JarvisTheme.critical;
              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: color.withOpacity(0.2),
                  child: Text('${e.leafIndex}',
                      style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.bold)),
                ),
                label: Text(
                  '${e.result.diseaseType} (${(e.result.confidence * 100).toStringAsFixed(0)}%)',
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: color.withOpacity(0.08),
                side: BorderSide(color: color.withOpacity(0.3)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildValidatingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: JarvisTheme.teaGreen.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Checking image quality...',
            style: TextStyle(color: JarvisTheme.textMuted, fontSize: 14),
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
              child: const DiseaseIndicatorLeaf(
                diseaseType: 'None',
                severity: 0,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isMultiLeafMode ? 'Scan Next Leaf' : 'Capture Tea Leaf',
              style: const TextStyle(
                color: JarvisTheme.teaGreen,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _isMultiLeafMode
                    ? 'Capture the next leaf from the same plant'
                    : 'Take a photo or select from gallery to detect diseases',
                textAlign: TextAlign.center,
                style: const TextStyle(
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
          ClipRRect(
            borderRadius: BorderRadius.circular(JarvisTheme.radiusLg),
            child: Image.memory(
              _imageBytes!,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
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
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              children: [
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
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 20),
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
                  child: const Icon(
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
                  child: const Icon(
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

  Widget _buildMultiLeafActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _addAnotherLeaf,
                icon: const Icon(Icons.add_a_photo),
                label: Text(AppLocalizations.of(context)!.disease_scan_next_leaf),
                style: FilledButton.styleFrom(
                  backgroundColor: JarvisTheme.teaGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    _multiLeafService.leafCount >= 1 ? _finishSession : null,
                icon: const Icon(Icons.summarize),
                label: Text(AppLocalizations.of(context)!.disease_finish_report),
                style: OutlinedButton.styleFrom(
                  foregroundColor: JarvisTheme.softGold,
                  side: const BorderSide(color: JarvisTheme.softGold),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
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
                      style: const TextStyle(
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
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
          if (isNotALeaf) ...[
            const SizedBox(height: JarvisTheme.spacingMd),
            Container(
              padding: const EdgeInsets.all(JarvisTheme.spacingMd),
              decoration: BoxDecoration(
                color: JarvisTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(JarvisTheme.radiusMd),
                border: Border.all(color: JarvisTheme.warning.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: JarvisTheme.warning),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This does not appear to be a valid tea leaf. Please capture a clear image of a tea leaf.',
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
                label: Text(AppLocalizations.of(context)!.common_try_again),
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

  Widget _buildAnalyzeMultipleButton() {
    return HologramCard(
      onTap: _isProcessing ? null : _analyzeMultiple,
      enableGlow: false,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: _isProcessing ? JarvisTheme.textMuted.withOpacity(0.3) : JarvisTheme.teaGreen.withOpacity(0.4),
          ),
          borderRadius: BorderRadius.circular(JarvisTheme.radiusMd),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.view_comfy_rounded,
              color: _isProcessing ? JarvisTheme.textMuted : JarvisTheme.teaGreen,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)!.disease_scan_multiple,
              style: TextStyle(
                color: _isProcessing ? JarvisTheme.textMuted : JarvisTheme.teaGreen,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        HologramCard(
          enableGlow: infectedCount > 0,
          glowColor: infectedCount > 0 ? JarvisTheme.critical : JarvisTheme.healthy,
          child: Container(
            padding: const EdgeInsets.all(JarvisTheme.spacingLg),
            decoration: BoxDecoration(
              border: Border.all(
                color: infectedCount > 0 ? JarvisTheme.critical.withOpacity(0.5) : JarvisTheme.healthy.withOpacity(0.5),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(JarvisTheme.radiusMd),
            ),
            child: Column(
              children: [
                Icon(
                  infectedCount > 0 ? Icons.warning_rounded : Icons.check_circle_rounded,
                  color: infectedCount > 0 ? JarvisTheme.critical : JarvisTheme.healthy,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.disease_scanned_leaves(total.toString()),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (infectedCount == 0)
                  Text(
                    AppLocalizations.of(context)!.disease_all_healthy,
                    style: const TextStyle(color: JarvisTheme.textMuted),
                  )
                else
                  Text(
                    AppLocalizations.of(context)!.disease_infected_healthy(infectedCount.toString(), healthyCount.toString()),
                    style: const TextStyle(color: JarvisTheme.critical, fontWeight: FontWeight.w600),
                  ),
                if (redRustCount > 0 || blisterBlightCount > 0 || otherCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (redRustCount > 0) _buildSummaryChip(AppLocalizations.of(context)!.disease_red_rust_count(redRustCount.toString()), JarvisTheme.warning),
                        if (redRustCount > 0 && blisterBlightCount > 0) const SizedBox(width: 8),
                        if (blisterBlightCount > 0) _buildSummaryChip(AppLocalizations.of(context)!.disease_blight_count(blisterBlightCount.toString()), JarvisTheme.critical),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: JarvisTheme.spacingMd),
        // Individual leaves expandable
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: HologramCard(
            enableGlow: false,
            child: ExpansionTile(
              title: Text(AppLocalizations.of(context)!.disease_individual_details,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              children: detections.map((det) {
                final isHealthy = det.result.diseaseType == 'Healthy' || det.result.diseaseType == 'Not A Leaf';
                final color = isHealthy ? JarvisTheme.healthy : JarvisTheme.critical;
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
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
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(AppLocalizations.of(context)!.disease_confidence_percent((det.result.confidence * 100).toStringAsFixed(1)),
                                style: const TextStyle(color: JarvisTheme.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
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
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
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
                child: const Icon(
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
              IconButton(
                icon: const Icon(
                  Icons.volume_up,
                  color: JarvisTheme.teaGreen,
                ),
                onPressed: () {
                  final recommendations = _result!.recommendations.join('. ');
                  ref
                      .read(voiceServiceProvider.notifier)
                      .speak(recommendations);
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
                    decoration: const BoxDecoration(
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
          const SizedBox(height: JarvisTheme.spacingSm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.medical_services_outlined),
              label: Text(AppLocalizations.of(context)!.disease_treatment_guide),
              style: OutlinedButton.styleFrom(
                foregroundColor: JarvisTheme.teaGreen,
                side: const BorderSide(color: JarvisTheme.teaGreen),
                padding: const EdgeInsets.all(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Session Summary Widgets
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildSessionSummaryCard() {
    final s = _sessionSummary!;
    final isHealthy = s.healthyCount == s.totalLeaves;

    return HologramCard(
      enableGlow: true,
      glowColor: isHealthy ? JarvisTheme.healthy : JarvisTheme.critical,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      (isHealthy ? JarvisTheme.healthy : JarvisTheme.critical)
                          .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isHealthy ? Icons.check_circle : Icons.warning_rounded,
                  color: isHealthy ? JarvisTheme.healthy : JarvisTheme.critical,
                  size: 30,
                ),
              ),
              const SizedBox(width: JarvisTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Plant Assessment',
                      style: TextStyle(
                        fontSize: 12,
                        color: JarvisTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.overallStatus,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isHealthy
                            ? JarvisTheme.healthy
                            : JarvisTheme.critical,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: JarvisTheme.spacingLg),

          // Stats row
          Row(
            children: [
              _buildStatTile('Total', '${s.totalLeaves}', JarvisTheme.info),
              _buildStatTile(
                  'Healthy', '${s.healthyCount}', JarvisTheme.healthy),
              if (s.redRustCount > 0)
                _buildStatTile(
                    'Red Rust', '${s.redRustCount}', JarvisTheme.critical),
              if (s.blisterBlightCount > 0)
                _buildStatTile(
                    'Blister', '${s.blisterBlightCount}', JarvisTheme.warning),
            ],
          ),
          const SizedBox(height: JarvisTheme.spacingMd),

          // Confidence & severity
          Container(
            padding: const EdgeInsets.all(JarvisTheme.spacingMd),
            decoration: BoxDecoration(
              color: _getSeverityColor(s.overallSeverity).withOpacity(0.1),
              borderRadius: BorderRadius.circular(JarvisTheme.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Avg Confidence: ${(s.averageConfidence * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: JarvisTheme.textPrimary,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(s.overallSeverity),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    s.overallSeverity,
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
      ),
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: JarvisTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionRecommendationsCard() {
    final recs = _sessionSummary!.recommendations;

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
                child: const Icon(Icons.lightbulb,
                    color: JarvisTheme.softGold, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recommended Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: JarvisTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: JarvisTheme.spacingMd),
          ...recs.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      gradient: JarvisTheme.goldGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
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
                      entry.value,
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
      case 'Critical':
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

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);

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
