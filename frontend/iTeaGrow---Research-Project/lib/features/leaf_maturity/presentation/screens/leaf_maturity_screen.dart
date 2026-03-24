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
import '../../domain/entities/leaf_detection.dart';
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
  List<LeafDetection>? _detections;
  bool _isProcessing = false;

  // Image display size — we need this to scale bounding-box coordinates.
  final GlobalKey _imageKey = GlobalKey();

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
          _detections = null;
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
          _detections = null;
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
      // ── Pre-scan leaf validation ──────────────────────────────────────
      final validation = await _leafValidator.validate(_imageBytes!);
      if (!validation.isValid) {
        setState(() => _isProcessing = false);
        _showError(validation.message);
        return;
      }

      // ── Multi-leaf inference ──────────────────────────────────────────
      final detections = await _mlService.predictMultiple(_selectedImage!);
      setState(() {
        _detections = detections;
        _isProcessing = false;
      });

      // Save all detections to DB (already done per-leaf inside the service)
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
    if (_detections == null || _detections!.isEmpty || _selectedImage == null) return;
    // For the PDF we use the primary (first) detection
    final primary = _detections!.first.result;
    final base64Image = base64Encode(_imageBytes!);

    try {
      final reportData = {
        'detection': {
          'species': primary.species,
          'maturity': primary.maturity,
          'species_confidence': primary.speciesConfidence,
          'maturity_confidence': primary.maturityConfidence,
          'image_data': base64Image,
          'created_at': primary.timestamp.toIso8601String(),
          'species_probs': primary.speciesProbabilities,
          'maturity_probs': primary.maturityProbabilities,
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
            'tea_maturity_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
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
                _detections = null;
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

            // Controlled-background tip
            if (_selectedImage == null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: TeaColors.freshLeaf.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: TeaColors.freshLeaf.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: TeaColors.freshLeaf, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Tip: Place leaves on a white or creme background for best results.'
                        'Leaves must not overlap for best multi-leaf results.',
                        style: TextStyle(fontSize: 12, color: TeaColors.freshLeaf),
                      ),
                    ),
                  ],
                ),
              ),

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
            ] else if (_detections == null) ...[
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
            if (_detections != null) ...[
              const SizedBox(height: 24),
              _buildMultiLeafResults(),
            ],

            // Manager/Admin: Yield Prediction
            if (widget.isManagerOrAdmin && _detections != null) ...[
              const SizedBox(height: 24),
              _buildYieldPrediction(),
            ],

            if (_detections != null) ...[
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

  /// Shows a summary header, an aggregated results card, and optional per-leaf detail.
  Widget _buildMultiLeafResults() {
    final detections = _detections!;
    final leafCount = detections.length;

    // If the single result is a validation error:
    if (leafCount == 1 && detections.first.result.isNotALeaf) {
      return _buildErrorCard(detections.first.result.validationMessage ??
          AppLocalizations.of(context)!.leaf_validation_failed);
    }

    int assamicaCount = 0;
    int dt1Count = 0;
    int matureCount = 0;
    int tenderCount = 0;

    for (final d in detections) {
      if (d.result.species == 'Assamica') assamicaCount++;
      if (d.result.species == 'DT1') dt1Count++;
      if (d.result.maturity == 'Mature') matureCount++;
      if (d.result.maturity == 'Tender') tenderCount++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.check_circle, color: TeaColors.healthyGreen, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                leafCount == 1
                    ? AppLocalizations.of(context)!.leaf_analysis_1_leaf
                    : AppLocalizations.of(context)!.leaf_analysis_n_leaves(leafCount.toString()),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Aggregated Summary Card
        if (leafCount > 0)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: TeaColors.freshLeaf.withOpacity(0.3), width: 1),
            ),
            color: TeaColors.freshLeaf.withOpacity(0.04),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.leaf_overall_summary,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: TeaColors.darkGray),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildSummaryStat(
                          AppLocalizations.of(context)!.leaf_species,
                          [
                            if (assamicaCount > 0) '$assamicaCount ${AppLocalizations.of(context)!.leaf_assamica}',
                            if (dt1Count > 0) '$dt1Count ${AppLocalizations.of(context)!.leaf_dt1}',
                          ].join('\n'),
                          assamicaCount >= dt1Count ? _getSpeciesColor('Assamica') : _getSpeciesColor('DT1'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryStat(
                          AppLocalizations.of(context)!.leaf_maturity_label,
                          [
                            if (matureCount > 0) '$matureCount ${AppLocalizations.of(context)!.leaf_mature}',
                            if (tenderCount > 0) '$tenderCount ${AppLocalizations.of(context)!.leaf_tender}',
                          ].join('\n'),
                          matureCount >= tenderCount ? _getMaturityColor('Mature') : _getMaturityColor('Tender'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        
        const SizedBox(height: 4),
        
        // Expansion Tile for Individual Details
        if (leafCount > 1)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                AppLocalizations.of(context)!.leaf_individual_details,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: TeaColors.freshLeaf,
                ),
              ),
              children: detections.map((d) => _buildLeafDetectionCard(d)).toList(),
            ),
          )
        else if (leafCount == 1)
          ...detections.map((d) => _buildLeafDetectionCard(d)),
      ],
    );
  }

  Widget _buildSummaryStat(String label, String value, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: TeaColors.mediumGray)),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? AppLocalizations.of(context)!.leaf_unknown : value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildLeafDetectionCard(LeafDetection detection) {
    final r = detection.result;
    final label = AppLocalizations.of(context)!.leaf_leaf_number((detection.index + 1).toString());
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: TeaColors.freshLeaf.withOpacity(0.35),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leaf label chip
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: TeaColors.freshLeaf.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: TeaColors.freshLeaf,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Spacer(),
                // Confidence badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getConfidenceLabelColor(r.confidenceLabel).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getConfidenceLabelColor(r.confidenceLabel),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _localizeConfidenceLabel(context, r.confidenceLabel),
                    style: TextStyle(
                      fontSize: 11,
                      color: _getConfidenceLabelColor(r.confidenceLabel),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Species + Maturity summary row
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    AppLocalizations.of(context)!.leaf_species,
                    _localizeSpecies(context, r.species),
                    _getSpeciesColor(r.species),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMiniStat(
                    AppLocalizations.of(context)!.leaf_maturity_label,
                    _localizeMaturity(context, r.maturity),
                    _getMaturityColor(r.maturity),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Confidence bars
            _buildMiniBar(AppLocalizations.of(context)!.leaf_species, r.speciesConfidence, _getSpeciesColor(r.species)),
            const SizedBox(height: 6),
            _buildMiniBar(AppLocalizations.of(context)!.leaf_maturity_label, r.maturityConfidence, _getMaturityColor(r.maturity)),
            if (r.isAmbiguous) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, color: TeaColors.warmAmber, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context)!.leaf_borderline_warning,
                    style: const TextStyle(fontSize: 11, color: TeaColors.warmAmber),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: TeaColors.darkGray)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBar(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(label, style: const TextStyle(fontSize: 11)),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: TeaColors.lightGray,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
        const SizedBox(width: 6),
        Text('${(value * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildErrorCard(String message) {
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
            const Icon(Icons.warning_amber_rounded, color: TeaColors.alertRust, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 14))),
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
            Row(
              children: [
                const Icon(Icons.trending_up, color: TeaColors.freshLeaf),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.leaf_yield_card_title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.leaf_yield_manager_feature,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
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

  String _localizeConfidenceLabel(BuildContext context, String label) {
    final l10n = AppLocalizations.of(context)!;
    switch (label) {
      case 'High': return l10n.leaf_high_confidence;
      case 'Moderate': return l10n.leaf_moderate_confidence;
      case 'Low': return l10n.leaf_low_confidence;
      default: return label;
    }
  }

  String _localizeSpecies(BuildContext context, String species) {
    if (species == 'Assamica') return AppLocalizations.of(context)!.leaf_assamica;
    if (species == 'DT1') return AppLocalizations.of(context)!.leaf_dt1;
    return species;
  }

  String _localizeMaturity(BuildContext context, String maturity) {
    if (maturity == 'Mature') return AppLocalizations.of(context)!.leaf_mature;
    if (maturity == 'Tender') return AppLocalizations.of(context)!.leaf_tender;
    return maturity;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bounding-box overlay painter
// ─────────────────────────────────────────────────────────────────────────────

/// Draws a green rectangle + "Leaf N" label around each detected leaf.
///
/// [bounds] values are in the original image's pixel space.
/// We scale them to [displayWidth] × [displayHeight] using the stored
/// original image dimensions baked into each [LeafDetection].
///
/// NOTE: We don't have the raw image dimensions here easily without
/// decoding again, so we store them as part of LeafSegmenterService
/// via the LeafRegion. For simplicity, the painter assumes the image
/// was loaded with BoxFit.cover into the display rectangle.
class _LeafBoundingBoxPainter extends CustomPainter {
  final List<LeafDetection> detections;
  final double displayWidth;
  final double displayHeight;

  _LeafBoundingBoxPainter({
    required this.detections,
    required this.displayWidth,
    required this.displayHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Find bounding extents of all detections to infer original image size.
    double imgW = 0;
    double imgH = 0;
    for (final d in detections) {
      if (d.bounds.right > imgW) imgW = d.bounds.right;
      if (d.bounds.bottom > imgH) imgH = d.bounds.bottom;
    }
    if (imgW == 0 || imgH == 0) return;

    final scaleX = displayWidth / imgW;
    final scaleY = displayHeight / imgH;

    final boxPaint = Paint()
      ..color = const Color(0xFF4CAF50) // green
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final bgPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;

    for (final detection in detections) {
      final b = detection.bounds;
      if (b.width == 0 || b.height == 0) continue;

      final scaledRect = Rect.fromLTRB(
        b.left * scaleX,
        b.top * scaleY,
        b.right * scaleX,
        b.bottom * scaleY,
      );

      // Draw bounding box
      canvas.drawRect(scaledRect, boxPaint);

      // Draw label chip background
      const labelText = TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: ' Leaf ${detection.index + 1} ',
          style: labelText,
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final chipRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          scaledRect.left,
          scaledRect.top - 18,
          tp.width + 4,
          18,
        ),
        const Radius.circular(3),
      );
      canvas.drawRRect(chipRect, bgPaint);
      tp.paint(canvas, Offset(scaledRect.left + 2, scaledRect.top - 17));
    }
  }

  @override
  bool shouldRepaint(covariant _LeafBoundingBoxPainter old) =>
      old.detections != detections;
}
