import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class LeafMaturityReportService {
  static final LeafMaturityReportService _instance =
      LeafMaturityReportService._internal();
  factory LeafMaturityReportService() => _instance;
  LeafMaturityReportService._internal();

  Future<Uint8List> generateReport(Map<String, dynamic> reportData) async {
    final pdf = pw.Document();

    final detection = reportData['detection'] as Map<String, dynamic>? ?? {};
    final farmer = reportData['farmer'] as Map<String, dynamic>? ?? {};
    final organization =
        reportData['organization'] as Map<String, dynamic>? ?? {};

    final reportId = reportData['report_id'] ?? 'N/A';
    final generatedAt =
        reportData['generated_at'] ?? DateTime.now().toIso8601String();

    pw.MemoryImage? scanImage;
    if (detection['image_data'] != null) {
      try {
        final imageBytes = base64Decode(detection['image_data']);
        scanImage = pw.MemoryImage(imageBytes);
      } catch (_) {}
    }

    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
    final detectionDate = detection['created_at'] != null
        ? dateFormat.format(
            DateTime.tryParse(detection['created_at']) ?? DateTime.now())
        : 'N/A';

    final species = detection['species'] ?? 'Unknown';
    final maturity = detection['maturity'] ?? 'Unknown';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(),
        footer: (context) => _buildFooter(reportId, generatedAt, organization),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              'Tea Leaf Maturity Analysis Report',
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
          _buildSectionTitle('Analysis Information'),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (scanImage != null)
                pw.Container(
                  width: 200,
                  height: 200,
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
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Species', species),
                    _buildInfoRow('Species Confidence',
                        '${((detection['species_confidence'] ?? 0) * 100).toStringAsFixed(1)}%'),
                    pw.SizedBox(height: 8),
                    _buildInfoRow('Maturity', maturity),
                    _buildInfoRow('Maturity Confidence',
                        '${((detection['maturity_confidence'] ?? 0) * 100).toStringAsFixed(1)}%'),
                    pw.SizedBox(height: 12),
                    _buildInfoRow('Farmer', farmer['name'] ?? 'Unknown'),
                    _buildInfoRow('Date/Time', detectionDate),
                    _buildInfoRow('Location',
                        farmer['location'] ?? 'Talawakelle, Sri Lanka'),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          _buildSectionTitle('Classification Probability Breakdown'),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (detection['species_probs'] != null)
                pw.Expanded(
                  child: _buildProbabilityTable('Species',
                      detection['species_probs'] as Map<String, dynamic>),
                ),
              pw.SizedBox(width: 16),
              if (detection['maturity_probs'] != null)
                pw.Expanded(
                  child: _buildProbabilityTable('Maturity',
                      detection['maturity_probs'] as Map<String, dynamic>),
                ),
            ],
          ),
          pw.SizedBox(height: 20),
          _buildRecommendations(maturity),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border:
            pw.Border(bottom: pw.BorderSide(color: PdfColors.green, width: 2)),
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
                'AI-Powered Tea Maturity Detection',
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'MATURITY REPORT',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1565C0'),
                ),
              ),
              pw.Text(
                DateFormat('yyyy-MM-dd').format(DateTime.now()),
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(
      String reportId, String generatedAt, Map<String, dynamic> organization) {
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
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800),
              ),
              pw.Text(
                organization['description'] ??
                    'Tea Plantation Management System',
                style:
                    const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Report: $reportId',
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey600)),
              pw.Text('Generated: $formattedTime',
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey600)),
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
            width: 110,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style:
                    pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildProbabilityTable(
      String title, Map<String, dynamic> probabilities) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('$title Probabilities',
              style:
                  pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          ...probabilities.entries.map((e) {
            final value = (e.value as num).toDouble();
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(e.key, style: const pw.TextStyle(fontSize: 10)),
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 60,
                        height: 6,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey300,
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                        child: pw.Align(
                          alignment: pw.Alignment.centerLeft,
                          child: pw.Container(
                            width: 60 * value,
                            height: 6,
                            decoration: pw.BoxDecoration(
                              color: value > 0.5
                                  ? PdfColors.green
                                  : PdfColors.orange,
                              borderRadius: pw.BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text('${(value * 100).toStringAsFixed(1)}%',
                          style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  pw.Widget _buildRecommendations(String maturity) {
    List<String> guidelines = [];
    if (maturity.toLowerCase() == 'tender') {
      guidelines = [
        'Optimal conditions met: The leaf is in a tender state.',
        'Action: Better for immediate plucking.',
        'Recommendation: Best suited for high-quality tea production (e.g., premium white or green tea).'
      ];
    } else {
      guidelines = [
        'Conditions: The leaf has reached a mature state.',
        'Action: Can be plucked, but may yield a stronger, more astringent brew.',
        'Recommendation: Suitable for black tea or blends where robustness is desired.',
        'Note: Monitor the surrounding leaves to ensure timely plucking before over-maturation.'
      ];
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Agricultural Guidelines & Next Steps'),
        pw.SizedBox(height: 10),
        ...guidelines.map((g) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6, left: 8),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('- ',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Expanded(
                      child:
                          pw.Text(g, style: const pw.TextStyle(fontSize: 10))),
                ],
              ),
            )),
      ],
    );
  }
}
