import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/powder_grading_ml_service.dart';
import '../../domain/entities/powder_grading_result.dart';

class PowderGradingScreen extends StatefulWidget {
  final bool showMarketData;

  const PowderGradingScreen({super.key, this.showMarketData = true});

  @override
  State<PowderGradingScreen> createState() => _PowderGradingScreenState();
}

class _PowderGradingScreenState extends State<PowderGradingScreen> {
  final ImagePicker _picker = ImagePicker();
  final PowderGradingMLService _mlService = PowderGradingMLService();

  XFile? _selectedImage;
  Uint8List? _imageBytes;
  PowderGradingResult? _result;
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
      final result = await _mlService.gradePowder(_selectedImage!.path);
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tea Powder Grading'),
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
                label: const Text('Capture Powder Image'),
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
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.grade),
                label: Text(_isProcessing ? 'Grading...' : 'Grade Powder'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],

            // Results
            if (_result != null) ...[
              const SizedBox(height: 24),
              _buildGradingResults(),
              if (widget.showMarketData) ...[
                const SizedBox(height: 16),
                _buildMarketAnalysis(),
              ],
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
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate,
              size: 64, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          Text(
            'No image selected',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
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
          color: Colors.grey.shade300,
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
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildGradingResults() {
    final gradeColor = _getGradeColor(_result!.grade);

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
                    _result!.grade,
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

            // Quality Score
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Quality Score', style: TextStyle(fontSize: 16)),
                Text(
                  '${_result!.qualityScore.toStringAsFixed(1)}/100',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _result!.qualityScore / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
              minHeight: 8,
            ),

            const SizedBox(height: 16),
            Text(
              'Graded at: ${_formatTime(_result!.timestamp)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketAnalysis() {
    final trendColor = _getTrendColor(_result!.marketTrend);
    final priceChangeColor =
        _result!.priceChange >= 0 ? Colors.green : Colors.red;

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_money,
                    color: Colors.green.shade700, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Market Value Analysis',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),

            // Current Market Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Current Price', style: TextStyle(fontSize: 16)),
                Text(
                  'Rs ${_result!.marketPrice.toStringAsFixed(2)}/kg',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Price Change
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Price Change (7 days)',
                    style: TextStyle(fontSize: 14)),
                Row(
                  children: [
                    Icon(
                      _result!.priceChange >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: priceChangeColor,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_result!.priceChange >= 0 ? '+' : ''}${_result!.priceChange.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: priceChangeColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Market Trend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Market Trend', style: TextStyle(fontSize: 14)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: trendColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _result!.marketTrend,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: trendColor,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Regional Prices
            const Text(
              'Regional Prices',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            ..._result!.regionalPrices.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(entry.key),
                        ],
                      ),
                      Text(
                        'Rs ${entry.value.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'Premium':
        return Colors.purple;
      case 'Grade A':
        return Colors.green;
      case 'Grade B':
        return Colors.orange;
      case 'Grade C':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'Rising':
        return Colors.green;
      case 'Stable':
        return Colors.blue;
      case 'Falling':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
