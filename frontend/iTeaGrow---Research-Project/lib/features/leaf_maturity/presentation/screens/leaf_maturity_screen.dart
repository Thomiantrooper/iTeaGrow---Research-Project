import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:printing/printing.dart';
import '../../../../core/api/api_config.dart';
import '../../../../core/design_system/tea_colors.dart';
import '../../data/datasources/leaf_maturity_pytorch_service.dart';
import '../../domain/entities/leaf_maturity_result.dart';
import '../services/leaf_maturity_report_service.dart';
import '../../../disease_detection/data/datasources/leaf_validation_service.dart';
import 'package:iteagrow/l10n/app_localizations.dart';
import 'leaf_maturity_history_screen.dart';

class LeafMaturityScreen extends StatefulWidget {
  final bool isManagerOrAdmin;

  const LeafMaturityScreen({
    super.key,
    this.isManagerOrAdmin = false,
  });

  @override
  State<LeafMaturityScreen> createState() => _LeafMaturityScreenState();
}

class _LeafMaturityScreenState extends State<LeafMaturityScreen> {
  final ImagePicker _picker = ImagePicker();
  final LeafMaturityPyTorchService _mlService = LeafMaturityPyTorchService();
  final LeafValidationService _leafValidator = LeafValidationService();

  XFile? _selectedImage;
  Uint8List? _imageBytes;
  LeafMaturityResult? _result;
  bool _isProcessing = false;

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
          _result = null;
        });
      }
    } catch (e) {
      _showError(AppLocalizations.of(context)!.error_gallery(e.toString()));
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null || _imageBytes == null) return;

    setState(() => _isProcessing = true);

    try {
      // ── Pre-scan leaf validation ───────────────────────────────────
      // Checks: min dimensions, sharpness (Laplacian), colour variance,
      // and green/natural-leaf ratio — mirrors disease detection gate.
      final validation = await _leafValidator.validate(_imageBytes!);
      if (!validation.isValid) {
        setState(() => _isProcessing = false);
        _showError(validation.message);
        return;
      }

      final result = await _mlService.predict(_selectedImage!);
      setState(() {
        _result = result;
        _isProcessing = false;
      });
      unawaited(_saveToDb(result));
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError(AppLocalizations.of(context)!.error_analysis(e.toString()));
    }
  }

  Future<void> _saveToDb(LeafMaturityResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_access_token');
      final headers = {'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer token';
      await http.post(
        Uri.parse(ApiConfig.dbMaturity),
        headers: headers,
        body: jsonEncode({
          'species': result.species,
          'maturity': result.maturity,
          'species_confidence': result.speciesConfidence,
          'maturity_confidence': result.maturityConfidence,
          'raw_confidence': result.rawConfidence,
          'confidence_label': result.confidenceLabel,
          'is_ambiguous': result.isAmbiguous,
          'color_validated': result.colorValidated,
        }),
      );
    } catch (e) {
      debugPrint('Maturity save error: e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: TeaColors.alertRust),
    );
  }

  Future<void> _generatePdfReport() async {
    if (_result == null || _selectedImage == null) return;

    // We already have image locally, we don't need to base64 encode it unless the user
    // requires a remote upload. The PDF service handles memory image or base64.
    // For simplicity, we can pass base64 since `LeafMaturityReportService` expects it.
    final base64Image = base64Encode(_imageBytes!);

    try {
      final reportData = {
        'detection': {
          'species': _result!.species,
          'maturity': _result!.maturity,
          'species_confidence': _result!.speciesConfidence,
          'maturity_confidence': _result!.maturityConfidence,
          'image_data': base64Image,
          'created_at': _result!.timestamp.toIso8601String(),
          'species_probs': _result!.speciesProbabilities,
          'maturity_probs': _result!.maturityProbabilities,
        },
        'farmer': {
          'name': 'Current User',
          'location': 'Local Plantation',
        },
        'organization': {
          'name': 'iTeaGrow Leaf Maturity',
        },
        'report_id':
            'LM-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        'generated_at': DateTime.now().toIso8601String(),
      };

      final pdfBytes =
          await LeafMaturityReportService().generateReport(reportData);

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name:
            'tea_maturity_report_\${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      _showError(AppLocalizations.of(context)!.error_report_failed(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.leaf_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const LeafMaturityHistoryScreen()),
            ),
          ),
          if (_selectedImage != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => setState(() {
                _selectedImage = null;
                _result = null;
              }),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Display
            if (_selectedImage == null)
              _buildImagePlaceholder()
            else
              _buildImagePreview(),

            const SizedBox(height: 24),

            // Action Buttons
            if (_selectedImage == null) ...[
              ElevatedButton.icon(
                onPressed: _captureImage,
                icon: const Icon(Icons.camera_alt),
                label: Text(l10n.leaf_capture),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: Text(l10n.leaf_from_gallery),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ] else if (_result == null) ...[
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _analyzeImage,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: TeaColors.white,
                        ),
                      )
                    : const Icon(Icons.analytics),
                label: Text(_isProcessing ? l10n.leaf_analyzing : l10n.leaf_analyze),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],

            // Results
            if (_result != null) ...[
              const SizedBox(height: 24),
              _buildResults(),
            ],

            // Manager/Admin: Yield Prediction
            if (widget.isManagerOrAdmin && _result != null) ...[
              const SizedBox(height: 24),
              _buildYieldPrediction(),
            ],

            if (_result != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _generatePdfReport,
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(l10n.common_generate_report),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TeaColors.freshLeaf,
                  side: const BorderSide(color: TeaColors.freshLeaf),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: TeaColors.lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TeaColors.mediumGray, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 64,
            color: TeaColors.darkGray,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.leaf_no_image,
            style: TextStyle(color: TeaColors.darkGray, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_imageBytes == null) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: TeaColors.lightGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.memory(
        _imageBytes!,
        height: 300,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildResults() {
    // ── Validation failure card ─────────────────────────────────────────
    if (_result!.isNotALeaf) {
      return Card(
        color: TeaColors.alertRust.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: TeaColors.alertRust, width: 1.5),
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
                  _result!.validationMessage ??
                      AppLocalizations.of(context)!.leaf_validation_failed,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle,
                    color: TeaColors.healthyGreen, size: 28),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.leaf_analysis_complete,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),

            // ── Ambiguity warning banner ─────────────────────────────
            if (_result!.isAmbiguous)
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
                        AppLocalizations.of(context)!.leaf_borderline_warning,
                        style:
                            const TextStyle(fontSize: 12, color: TeaColors.warmAmber),
                      ),
                    ),
                  ],
                ),
              ),

            // Step 1: Species Classification
            Text(
              AppLocalizations.of(context)!.leaf_species_section,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TeaColors.darkGray,
              ),
            ),
            const SizedBox(height: 12),
            _buildResultRow(
              AppLocalizations.of(context)!.leaf_species,
              _result!.species,
              _getSpeciesColor(_result!.species),
            ),
            const SizedBox(height: 8),
            _buildResultRow(
              AppLocalizations.of(context)!.leaf_confidence,
              '${(_result!.speciesConfidence * 100).toStringAsFixed(1)}%',
              TeaColors.freshLeaf,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _result!.speciesConfidence,
              backgroundColor: TeaColors.lightGray,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getSpeciesColor(_result!.species),
              ),
              minHeight: 8,
            ),

            // Species probabilities
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _result!.speciesProbabilities.entries
                  .map(
                    (entry) => Column(
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(entry.value * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),

            const Divider(height: 32),

            // Step 2: Maturity Classification
            Text(
              AppLocalizations.of(context)!.leaf_maturity_section,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TeaColors.darkGray,
              ),
            ),
            const SizedBox(height: 12),
            _buildResultRow(
              AppLocalizations.of(context)!.leaf_maturity_label,
              _result!.maturity,
              _getMaturityColor(_result!.maturity),
            ),
            const SizedBox(height: 8),
            _buildResultRow(
              AppLocalizations.of(context)!.leaf_confidence,
              '${(_result!.maturityConfidence * 100).toStringAsFixed(1)}%',
              TeaColors.freshLeaf,
            ),
            const SizedBox(height: 8),
            _buildResultRow(
              AppLocalizations.of(context)!.leaf_confidence_level,
              _result!.confidenceLabel,
              _getConfidenceLabelColor(_result!.confidenceLabel),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _result!.maturityConfidence,
              backgroundColor: TeaColors.lightGray,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getMaturityColor(_result!.maturity),
              ),
              minHeight: 8,
            ),

            // Maturity probabilities
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _result!.maturityProbabilities.entries
                  .map(
                    (entry) => Column(
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(entry.value * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 16),
            Text(
              'Analyzed at: ${_formatTime(_result!.timestamp)}',
              style: TextStyle(fontSize: 12, color: TeaColors.darkGray),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYieldPrediction() {
    return Card(
      color: TeaColors.freshLeaf.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up, color: TeaColors.freshLeaf),
                SizedBox(width: 8),
                Text(
                  'Yield Prediction',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Manager/Admin Feature',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to yield prediction screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(AppLocalizations.of(context)!.leaf_yield_ready),
                  ),
                );
              },
              icon: const Icon(Icons.calculate),
              label: Text(AppLocalizations.of(context)!.leaf_predict_yield),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Color _getSpeciesColor(String species) {
    switch (species) {
      case 'Assamica':
        return TeaColors.matureLeaf;
      case 'DT1':
        return TeaColors.infoSky;
      default:
        return TeaColors.mediumGray;
    }
  }

  Color _getMaturityColor(String maturity) {
    switch (maturity) {
      case 'Tender':
        return TeaColors.healthyGreen;
      case 'Mature':
        return TeaColors.warmAmber;
      default:
        return TeaColors.mediumGray;
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

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
