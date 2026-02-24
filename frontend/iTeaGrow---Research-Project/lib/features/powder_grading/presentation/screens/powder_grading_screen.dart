import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../../core/design_system/tea_colors.dart';
import '../../../market_analysis/providers/market_providers.dart';
import '../../../market_analysis/data/models/market_models.dart';

class PowderGradingScreen extends ConsumerStatefulWidget {
  final bool showMarketData;

  const PowderGradingScreen({super.key, this.showMarketData = true});

  @override
  ConsumerState<PowderGradingScreen> createState() =>
      _PowderGradingScreenState();
}

class _PowderGradingScreenState extends ConsumerState<PowderGradingScreen> {
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _showExplainability = false;

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
          _showExplainability = false;
          ref.read(classificationProvider.notifier).clear();
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
          _showExplainability = false;
          ref.read(classificationProvider.notifier).clear();
        });
      }
    } catch (e) {
      _showError('Gallery error: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    ref
        .read(classificationProvider.notifier)
        .classify(File(_selectedImage!.path), generateHeatmap: true);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: TeaColors.alertRust),
    );
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tea Powder Grading'),
        actions: [
          if (_selectedImage != null) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset and Retake',
              onPressed: () => setState(() {
                _selectedImage = null;
                _imageBytes = null;
                _showExplainability = false;
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
                label: const Text('Capture Powder Image'),
                style:
                    ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose from Gallery'),
                style:
                    OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            ] else if (classState.value == null && !classState.isLoading) ...[
              ElevatedButton.icon(
                onPressed: _analyzeImage,
                icon: const Icon(Icons.grade),
                label: const Text('Grade Powder'),
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
                label: const Text('Grading...'),
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
          const Text('No Powder Image Selected',
              style: TextStyle(
                  color: TeaColors.nearBlack,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 8),
          Text('Capture or upload an image to begin grading.',
              style: TextStyle(color: TeaColors.darkGray, fontSize: 14)),
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
          _showExplainability && result != null && result.heatmapPath != null
              ? Image.file(
                  File(result.heatmapPath!),
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : Image.memory(
                  _imageBytes!,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
          if (result != null && result.heatmapPath != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                backgroundColor: _showExplainability
                    ? TeaColors.alertRust.withOpacity(0.8)
                    : Colors.black54,
                label: Text(
                  _showExplainability ? 'Heatmap View' : 'Original View',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGradingResults(ClassificationResult result) {
    final gradeColor = TeaColors.healthyGreen;

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
                const Text(
                  'Grading Results',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),

            // Grade
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Grade', style: TextStyle(fontSize: 16)),
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
                const Text('Confidence', style: TextStyle(fontSize: 16)),
                Text(
                  '${result.confidence.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
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
              'Processing Source: ${result.source == 'offline' ? 'Local ML Model' : 'Cloud Server'}',
              style: TextStyle(fontSize: 12, color: TeaColors.darkGray),
            ),
            if (result.heatmapPath != null) ...[
              const Divider(height: 32),
              SwitchListTile(
                title: const Text('Explain Grading',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                subtitle: const Text('Show Grad-CAM heatmap overlay'),
                value: _showExplainability,
                activeColor: TeaColors.freshLeaf,
                onChanged: (val) => setState(() => _showExplainability = val),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
