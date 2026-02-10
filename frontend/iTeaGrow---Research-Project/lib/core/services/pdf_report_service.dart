import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

/// PDF Report Generation Service for iTeaGrow Disease Detection Reports.
///
/// Generates professionally formatted PDF reports with:
/// - iTeaGrow branded header
/// - Disease detection information with image
/// - Weather conditions from IoT sensors
/// - Treatment recommendations and precautions
/// - Professional footer with report ID and branding
class PdfReportService {
  static final PdfReportService _instance = PdfReportService._internal();
  factory PdfReportService() => _instance;
  PdfReportService._internal();

  /// Generate a PDF document from report data.
  Future<Uint8List> generateReport(Map<String, dynamic> reportData) async {
    final pdf = pw.Document();

    final detection = reportData['detection'] as Map<String, dynamic>? ?? {};
    final farmer = reportData['farmer'] as Map<String, dynamic>? ?? {};
    final weather = reportData['weather'] as Map<String, dynamic>?;
    final recommendations = (reportData['recommendations'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final precautions = (reportData['precautions'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final organization = reportData['organization'] as Map<String, dynamic>? ?? {};

    final reportId = reportData['report_id'] ?? 'N/A';
    final generatedAt = reportData['generated_at'] ?? DateTime.now().toIso8601String();

    // Decode image if available
    pw.MemoryImage? scanImage;
    if (detection['image_data'] != null) {
      try {
        final imageBytes = base64Decode(detection['image_data']);
        scanImage = pw.MemoryImage(imageBytes);
      } catch (_) {}
    }

    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
    final detectionDate = detection['created_at'] != null
        ? dateFormat.format(DateTime.tryParse(detection['created_at']) ?? DateTime.now())
        : 'N/A';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(),
        footer: (context) => _buildFooter(reportId, generatedAt, organization),
        build: (context) => [
          // Title
          pw.Center(
            child: pw.Text(
              'Tea Disease Detection Report',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#2E7D32'),
              ),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              'Report ID: $reportId',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColor.fromHex('#4CAF50'), thickness: 2),
          pw.SizedBox(height: 16),

          // Detection Info Section
          _buildSectionTitle('Disease Detection Information'),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Image
              if (scanImage != null)
                pw.Container(
                  width: 150,
                  height: 150,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.ClipRRect(
                    horizontalRadius: 8,
                    verticalRadius: 8,
                    child: pw.Image(scanImage, fit: pw.BoxFit.cover),
                  ),
                ),
              if (scanImage != null) pw.SizedBox(width: 20),
              // Details
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Disease Name', detection['disease_name'] ?? 'Unknown'),
                    _buildInfoRow('Confidence', '${((detection['confidence'] ?? 0) * 100).toStringAsFixed(1)}%'),
                    _buildInfoRow('Severity', detection['severity'] ?? 'Unknown'),
                    _buildInfoRow('Date/Time', detectionDate),
                    _buildInfoRow('Farmer', farmer['name'] ?? 'Unknown'),
                    _buildInfoRow('Location', farmer['location'] ?? 'N/A'),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // Weather Conditions Section
          if (weather != null) ...[
            _buildSectionTitle('Weather Conditions (IoT Sensor Data)'),
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                _buildWeatherCard('Temperature', '${weather['temperature'] ?? "N/A"}', 'C'),
                pw.SizedBox(width: 10),
                _buildWeatherCard('Humidity', '${weather['humidity'] ?? "N/A"}', '%'),
                pw.SizedBox(width: 10),
                _buildWeatherCard('Soil Moisture', '${weather['soil_moisture'] ?? "N/A"}', '%'),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          // Recommendations Section
          if (recommendations.isNotEmpty) ...[
            _buildSectionTitle('Recommended Treatment'),
            pw.SizedBox(height: 10),
            ...recommendations.asMap().entries.map((entry) =>
                _buildBulletPoint('${entry.key + 1}. ${entry.value}')),
            pw.SizedBox(height: 16),
          ],

          // Precautions Section
          if (precautions.isNotEmpty) ...[
            _buildSectionTitle('Precautionary Measures'),
            pw.SizedBox(height: 10),
            ...precautions.map((p) => _buildBulletPoint(p, icon: '!')),
            pw.SizedBox(height: 16),
          ],

          // Disclaimer
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#FFF3E0'),
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColor.fromHex('#FFB74D')),
            ),
            child: pw.Text(
              'Disclaimer: This report is generated by AI-based disease detection. '
              'For critical decisions, please consult with a qualified agricultural expert or pathologist.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.green, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'iTeaGrow',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#2E7D32'),
                ),
              ),
              pw.Text(
                'AI-Powered Tea Disease Detection',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'OFFICIAL REPORT',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1565C0'),
                ),
              ),
              pw.Text(
                DateFormat('yyyy-MM-dd').format(DateTime.now()),
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(String reportId, String generatedAt, Map<String, dynamic> organization) {
    final formattedTime = DateFormat('MMM dd, yyyy HH:mm:ss').format(
      DateTime.tryParse(generatedAt) ?? DateTime.now(),
    );

    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                organization['name'] ?? 'iTeaGrow',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.green800),
              ),
              pw.Text(
                organization['description'] ?? 'Tea Plantation Management System',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Report: $reportId', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              pw.Text('Generated: $formattedTime', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#E8F5E9'),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#2E7D32'),
        ),
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildWeatherCard(String label, String value, String unit) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#E3F2FD'),
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: PdfColor.fromHex('#90CAF9')),
        ),
        child: pw.Column(
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(
              '$value$unit',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildBulletPoint(String text, {String icon = '-'}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4, left: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('$icon ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.Expanded(child: pw.Text(text, style: const pw.TextStyle(fontSize: 10))),
        ],
      ),
    );
  }
}
