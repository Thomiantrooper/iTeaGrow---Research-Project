import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../../../core/design_system/tea_colors.dart';
import '../../../../core/design_system/tea_typography.dart';
import '../../../../core/design_system/tea_spacing.dart';
import '../../data/datasources/leaf_maturity_pytorch_service.dart';
import '../../domain/entities/leaf_maturity_result.dart';

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
        });
      }
    } catch (e) {
      _showError('Gallery error: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() => _isProcessing = true);

    try {
      final result = await _mlService.predict(_selectedImage!);
      setState(() {
        _result = result;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Analysis error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: TeaColors.alertRust),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaf Maturity Detection'),
        actions: [
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
                label: const Text('Capture Image'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose from Gallery'),
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
                label: Text(_isProcessing ? 'Analyzing...' : 'Analyze Leaf'),
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
            'No image selected',
            style: TextStyle(color: TeaColors.darkGray, fontSize: 16),
          ),
        ],
      ),
    );
  }

  bool _showGradCam = false;

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

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            _imageBytes!,
            height: 300,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        if (_showGradCam && _result != null && _result!.heatmapPath != null)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_result!.heatmapPath!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        if (_result != null)
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: TeaColors.nearBlack.withOpacity(0.54),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Grad-CAM',
                    style: TextStyle(color: TeaColors.white, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: _showGradCam,
                    onChanged: (value) => setState(() => _showGradCam = value),
                    thumbColor: WidgetStatePropertyAll(TeaColors.warmAmber),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResults() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: TeaColors.healthyGreen, size: 28),
                SizedBox(width: 12),
                Text(
                  'Analysis Complete',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),

            // Step 1: Species Classification
            Text(
              'Species Classification',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TeaColors.darkGray,
              ),
            ),
            const SizedBox(height: 12),
            _buildResultRow(
              'Species',
              _result!.species,
              _getSpeciesColor(_result!.species),
            ),
            const SizedBox(height: 8),
            _buildResultRow(
              'Confidence',
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
              'Maturity Classification',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TeaColors.darkGray,
              ),
            ),
            const SizedBox(height: 12),
            _buildResultRow(
              'Maturity',
              _result!.maturity,
              _getMaturityColor(_result!.maturity),
            ),
            const SizedBox(height: 8),
            _buildResultRow(
              'Confidence',
              '${(_result!.maturityConfidence * 100).toStringAsFixed(1)}%',
              TeaColors.freshLeaf,
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
                  const SnackBar(
                    content:
                        Text('Yield prediction module - Ready for integration'),
                  ),
                );
              },
              icon: const Icon(Icons.calculate),
              label: const Text('Predict Yield'),
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

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
