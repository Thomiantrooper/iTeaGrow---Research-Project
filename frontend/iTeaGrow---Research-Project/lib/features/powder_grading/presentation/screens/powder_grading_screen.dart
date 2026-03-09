import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../../core/design_system/tea_colors.dart';
import '../../../market_analysis/providers/market_providers.dart';
import '../../../market_analysis/data/models/market_models.dart';
import '../../data/datasources/powder_validation_service.dart';
import 'package:iteagrow/l10n/app_localizations.dart';

class PowderGradingScreen extends ConsumerStatefulWidget {
  final bool showMarketData;

  const PowderGradingScreen({super.key, this.showMarketData = true});

  @override
  ConsumerState<PowderGradingScreen> createState() =>
      _PowderGradingScreenState();
}

class _PowderGradingScreenState extends ConsumerState<PowderGradingScreen> {
  final ImagePicker _picker = ImagePicker();
  final PowderValidationService _powderValidator = PowderValidationService();

  XFile? _selectedImage;
  Uint8List? _imageBytes;

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
          ref.read(classificationProvider.notifier).clear();
        });
      }
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

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _imageBytes = bytes;
          ref.read(classificationProvider.notifier).clear();
        });
      }
    } catch (e) {
      _showError(AppLocalizations.of(context)!.error_gallery(e.toString()));
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null || _imageBytes == null) return;

    // ── Pre-scan powder validation ───────────────────────────────────
    // Checks: min resolution, sharpness (Laplacian), colour variance,
    // green-dominance rejection, and brownish/dark powder pixel ratio.
    final validation = await _powderValidator.validate(_imageBytes!);
    if (!validation.isValid) {
      _showError(validation.message);
      return;
    }

    ref
        .read(classificationProvider.notifier)
        .classify(File(_selectedImage!.path), generateHeatmap: false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: TeaColors.alertRust),
    );
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classificationProvider);

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.powder_title),
        actions: [
          if (_selectedImage != null) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: l10n.powder_reset,
              onPressed: () => setState(() {
                _selectedImage = null;
                _imageBytes = null;
                ref.read(classificationProvider.notifier).clear();
              }),
            ),
          ]
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_selectedImage == null)
              _buildImagePlaceholder()
            else
              _buildImagePreview(classState.value),
            const SizedBox(height: 24),
            if (_selectedImage == null) ...[
              ElevatedButton.icon(
                onPressed: _captureImage,
                icon: const Icon(Icons.camera_alt),
                label: Text(l10n.powder_capture_image),
                style:
                    ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: Text(l10n.leaf_from_gallery),
                style:
                    OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            ] else if (classState.value == null && !classState.isLoading) ...[
              ElevatedButton.icon(
                onPressed: _analyzeImage,
                icon: const Icon(Icons.grade),
                label: Text(l10n.powder_grade_action),
                style:
                    ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            ] else if (classState.isLoading) ...[
              ElevatedButton.icon(
                onPressed: null,
                icon: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
                label: Text(l10n.powder_grading),
                style:
                    ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            ],
            if (_selectedImage != null && classState.value != null) ...[
              const SizedBox(height: 24),
              _buildGradingResults(classState.value!),
            ],
            if (_selectedImage != null && classState.hasError) ...[
              const SizedBox(height: 16),
              Text('Error: ${classState.error}',
                  style: const TextStyle(color: Colors.red)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TeaColors.mediumGray.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TeaColors.freshLeaf.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add_photo_alternate_outlined,
                size: 48, color: TeaColors.freshLeaf),
          ),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.powder_no_image,
              style: const TextStyle(
                  color: TeaColors.nearBlack,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.powder_no_image_subtitle,
              style: const TextStyle(color: TeaColors.darkGray, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildImagePreview(ClassificationResult? result) {
    if (_imageBytes == null) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: TeaColors.lightGray.withOpacity(0.3),
        child: const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Image.memory(
            _imageBytes!,
            height: 250,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ],
      ),
    );
  }

  Widget _buildGradingResults(ClassificationResult result) {
    // ── Validation failure card ─────────────────────────────────────────
    if (result.isValidationFailure) {
      return Card(
        color: TeaColors.alertRust.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: TeaColors.alertRust, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: TeaColors.alertRust, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.validationMessage ??
                      AppLocalizations.of(context)!.powder_validation_failed,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final gradeColor = _getGradeColor(result.grade);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.grade, color: gradeColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.powder_results,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),

            // ── Ambiguity warning banner ──────────────────────────────
            if (result.isAmbiguous)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: TeaColors.warmAmber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: TeaColors.warmAmber, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: TeaColors.warmAmber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.powder_borderline,
                        style: const
                            TextStyle(fontSize: 12, color: TeaColors.warmAmber),
                      ),
                    ),
                  ],
                ),
              ),

            // Grade
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.powder_grade, style: const TextStyle(fontSize: 16)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: gradeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    result.grade,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: gradeColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.powder_confidence_level, style: const TextStyle(fontSize: 16)),
                Text(
                  '${result.confidence.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // ── Confidence level badge ────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.powder_confidence_level, style: const TextStyle(fontSize: 16)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getConfidenceLabelColor(result.confidenceLabel)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    result.confidenceLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getConfidenceLabelColor(result.confidenceLabel),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: result.confidence / 100,
              backgroundColor: TeaColors.lightGray,
              valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
              minHeight: 8,
            ),
            const SizedBox(height: 16),
            Text(
              result.source == 'offline'
                  ? AppLocalizations.of(context)!.powder_local_source
                  : AppLocalizations.of(context)!.powder_cloud_source,
              style: TextStyle(fontSize: 12, color: TeaColors.darkGray),
            ),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'BOPF':
      case 'BOP':
        return TeaColors.freshLeaf;
      case 'Pekoe':
        return TeaColors.warmAmber;
      default:
        return TeaColors.darkGray;
    }
  }

  Color _getConfidenceLabelColor(String label) {
    switch (label) {
      case 'High':
        return TeaColors.healthyGreen;
      case 'Moderate':
        return TeaColors.warmAmber;
      case 'Low':
        return Colors.orange;
      default:
        return TeaColors.alertRust;
    }
  }
}
