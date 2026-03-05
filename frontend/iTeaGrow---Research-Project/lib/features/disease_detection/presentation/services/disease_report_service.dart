import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../data/datasources/multi_leaf_scan_service.dart';

class DiseaseReportService {
  static final DiseaseReportService _instance =
      DiseaseReportService._internal();
  factory DiseaseReportService() => _instance;
  DiseaseReportService._internal();

  /// Generate a multi-leaf session report containing per-leaf results and
  /// an overall summary with recommendations.
  Future<Uint8List> generateMultiLeafReport({
    required List<LeafScanEntry> entries,
    required MultiLeafSummary summary,
    Map<String, dynamic>? farmer,
    Map<String, dynamic>? organization,
    double? temperature,
    double? humidity,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
    final reportId =
        'ML-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final generatedAt = DateTime.now().toIso8601String();
    final org = organization ??
        {
          'name': 'iTeaGrow',
          'description': 'Tea Plantation Management System',
        };

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(),
        footer: (context) => _buildFooter(reportId, generatedAt, org),
        build: (context) => [
          // Title
          pw.Center(
            child: pw.Text(
              'Multi-Leaf Disease Analysis Report',
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
              'Report ID: $reportId  |  Leaves Scanned: ${entries.length}',
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColor.fromHex('#4CAF50'), thickness: 2),
          pw.SizedBox(height: 16),

          // Overall Summary
          _buildSectionTitle('Overall Plant Assessment'),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                    'Status', summary.overallStatus,
                    color: summary.healthyCount == summary.totalLeaves
                        ? PdfColors.green
                        : PdfColors.red),
              ),
              pw.SizedBox(width: 10),
              Expanded(
                child: _buildSummaryCard(
                    'Severity', summary.overallSeverity),
              ),
              pw.SizedBox(width: 10),
              Expanded(
                child: _buildSummaryCard(
                    'Avg Confidence',
                    '${(summary.averageConfidence * 100).toStringAsFixed(1)}%'),
              ),
            ],
          ),
          pw.SizedBox(height: 12),

          // Summary Statistics Table
          _buildMultiLeafStatsTable(summary),
          pw.SizedBox(height: 20),

          // Per-Leaf Breakdown
          _buildSectionTitle('Individual Leaf Results'),
          pw.SizedBox(height: 10),
          _buildPerLeafTable(entries, dateFormat),
          pw.SizedBox(height: 20),

          // Environmental Conditions
          if (temperature != null || humidity != null) ...[
            _buildSectionTitle('Environmental Conditions (IoT Snapshot)'),
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                if (temperature != null)
                  Expanded(
                    child: _buildEnvCard(
                        'Temperature', '${temperature.toStringAsFixed(1)} \u00b0C'),
                  ),
                if (temperature != null && humidity != null)
                  pw.SizedBox(width: 12),
                if (humidity != null)
                  Expanded(
                    child: _buildEnvCard(
                        'Humidity', '${humidity.toStringAsFixed(1)} %'),
                  ),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          // Recommendations
          _buildRecommendations(
            summary.overallStatus,
            summary.recommendations,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildSummaryCard(String label, String value,
      {PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#E8F5E9'),
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColor.fromHex('#A5D6A7')),
      ),
      child: pw.Column(
        children: [
          pw.Text(label,
              style:
                  const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          pw.SizedBox(height: 4),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  pw.Widget _buildMultiLeafStatsTable(MultiLeafSummary summary) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#C8E6C9')),
          children: [
            _cell('Metric', isHeader: true),
            _cell('Value', isHeader: true),
          ],
        ),
        _statsRow('Total Leaves Scanned', '${summary.totalLeaves}'),
        _statsRow('Healthy', '${summary.healthyCount}'),
        _statsRow('Red Rust', '${summary.redRustCount}'),
        _statsRow('Blister Blight', '${summary.blisterBlightCount}'),
        _statsRow('Health %',
            '${summary.healthPercentage.toStringAsFixed(1)}%'),
        _statsRow('Requires Action', summary.requiresAction ? 'Yes' : 'No'),
      ],
    );
  }

  pw.TableRow _statsRow(String label, String value) {
    return pw.TableRow(children: [_cell(label), _cell(value)]);
  }

  pw.Widget _buildPerLeafTable(
      List<LeafScanEntry> entries, DateFormat dateFormat) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(3),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#FFCDD2')),
          children: [
            _cell('#', isHeader: true),
            _cell('Disease', isHeader: true),
            _cell('Confidence', isHeader: true),
            _cell('Severity', isHeader: true),
            _cell('Scan Time', isHeader: true),
          ],
        ),
        ...entries.map((e) => pw.TableRow(children: [
              _cell('${e.leafIndex}'),
              _cell(e.result.diseaseType),
              _cell(
                  '${(e.result.confidence * 100).toStringAsFixed(1)}%'),
              _cell(e.result.severity),
              _cell(dateFormat.format(e.scannedAt)),
            ])),
      ],
    );
  }

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
        scanImage = pw.MemoryImage(base64Decode(detection['image_data']));
      } catch (_) {}
    }

    pw.MemoryImage? heatmapImage;
    if (detection['heatmap_data'] != null) {
      try {
        heatmapImage =
            pw.MemoryImage(base64Decode(detection['heatmap_data']));
      } catch (_) {}
    }

    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
    final detectionDate = detection['timestamp'] != null
        ? dateFormat
            .format(DateTime.tryParse(detection['timestamp']) ?? DateTime.now())
        : 'N/A';

    final diseaseType = detection['disease_type'] as String? ?? 'Unknown';
    final confidence = (detection['confidence'] as num?)?.toDouble() ?? 0.0;
    final severity = detection['severity'] as String? ?? 'N/A';
    final recommendations =
        List<String>.from(detection['recommendations'] ?? []);

    final detections =
        (detection['detections'] as List<dynamic>?) ?? [];
    final summary =
        detection['summary'] as Map<String, dynamic>?;
    final temperature = (detection['temperature'] as num?)?.toDouble();
    final humidity = (detection['humidity'] as num?)?.toDouble();
    final airQuality = (detection['air_quality'] as num?)?.toDouble();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(),
        footer: (context) => _buildFooter(reportId, generatedAt, organization),
        build: (context) => [
          // ── Title ──────────────────────────────────────────────────────
          pw.Center(
            child: pw.Text(
              'Tea Leaf Disease Analysis Report',
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
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColor.fromHex('#4CAF50'), thickness: 2),
          pw.SizedBox(height: 16),

          // ── Analysis Information ────────────────────────────────────────
          _buildSectionTitle('Analysis Information'),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (scanImage != null)
                pw.Container(
                  width: 180,
                  height: 180,
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
                    _buildInfoRow('Disease Type', diseaseType),
                    _buildInfoRow('Confidence',
                        '${(confidence * 100).toStringAsFixed(1)}%'),
                    _buildInfoRow('Severity', severity),
                    pw.SizedBox(height: 8),
                    _buildInfoRow('Analyst', farmer['name'] ?? 'Current User'),
                    _buildInfoRow(
                        'Location', farmer['location'] ?? 'Tea Plantation'),
                    _buildInfoRow('Date / Time', detectionDate),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // ── GradCAM Heatmap ─────────────────────────────────────────────
          if (heatmapImage != null) ...[
            _buildSectionTitle('GradCAM Explainability Heatmap'),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Container(
                width: 200,
                height: 200,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.ClipRRect(
                  horizontalRadius: 8,
                  verticalRadius: 8,
                  child: pw.Image(heatmapImage, fit: pw.BoxFit.cover),
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'Red regions indicate areas most indicative of the detected condition.',
                style: const pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey600),
              ),
            ),
            pw.SizedBox(height: 20),
          ],

          // ── Detection Breakdown ─────────────────────────────────────────
          if (detections.isNotEmpty || summary != null) ...[
            _buildSectionTitle('Detection Breakdown'),
            pw.SizedBox(height: 10),
            _buildDetectionTable(detections, summary),
            pw.SizedBox(height: 20),
          ],

          // ── Environmental Conditions ────────────────────────────────────
          if (temperature != null || humidity != null || airQuality != null) ...[
            _buildSectionTitle('Environmental Conditions (IoT Snapshot)'),
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                if (temperature != null)
                  Expanded(
                    child: _buildEnvCard(
                        'Temperature', '${temperature.toStringAsFixed(1)} °C'),
                  ),
                if (temperature != null && (humidity != null || airQuality != null))
                  pw.SizedBox(width: 12),
                if (humidity != null)
                  Expanded(
                    child: _buildEnvCard(
                        'Humidity', '${humidity.toStringAsFixed(1)} %'),
                  ),
                if (humidity != null && airQuality != null)
                  pw.SizedBox(width: 12),
                if (airQuality != null)
                  Expanded(
                    child: _buildEnvCard(
                        'Air Quality', _aqiLabel(airQuality)),
                  ),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          // ── Recommendations ─────────────────────────────────────────────
          _buildRecommendations(diseaseType, recommendations),
        ],
      ),
    );

    return pdf.save();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  pw.Widget Expanded({required pw.Widget child}) => pw.Expanded(child: child);

  String _aqiLabel(double aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy';
    if (aqi <= 200) return 'Bad';
    return 'Hazardous';
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
                'AI-Powered Tea Disease Detection',
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'DISEASE REPORT',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#B71C1C'),
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
                style: const pw.TextStyle(
                    fontSize: 7, color: PdfColors.grey600),
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
        color: PdfColor.fromHex('#FFEBEE'),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#B71C1C'),
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
                style: pw.TextStyle(
                    fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDetectionTable(
      List<dynamic> detections, Map<String, dynamic>? summary) {
    // Build rows from individual detections if available; fallback to summary counts
    final rows = <Map<String, dynamic>>[];

    if (detections.isNotEmpty) {
      for (final d in detections) {
        rows.add({
          'class': _formatName(d['class_name'] ?? d['className'] ?? 'unknown'),
          'confidence':
              (((d['confidence'] as num?)?.toDouble() ?? 0.0) * 100)
                  .toStringAsFixed(1),
          'area':
              (((d['area_percentage'] as num?)?.toDouble() ?? 0.0))
                  .toStringAsFixed(1),
        });
      }
    } else if (summary != null) {
      if ((summary['healthy_count'] ?? 0) > 0)
        rows.add({'class': 'Healthy', 'confidence': '-', 'area': '-'});
      if ((summary['red_rust_count'] ?? 0) > 0)
        rows.add({'class': 'Red Rust', 'confidence': '-', 'area': '-'});
      if ((summary['blister_blight_count'] ?? 0) > 0)
        rows.add({'class': 'Blister Blight', 'confidence': '-', 'area': '-'});
    }

    if (rows.isEmpty) return pw.SizedBox();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration:
              pw.BoxDecoration(color: PdfColor.fromHex('#FFCDD2')),
          children: [
            _cell('Disease Class', isHeader: true),
            _cell('Confidence', isHeader: true),
            _cell('Area %', isHeader: true),
          ],
        ),
        ...rows.map((r) => pw.TableRow(children: [
              _cell(r['class']),
              _cell('${r['confidence']}%'),
              _cell('${r['area']}%'),
            ])),
      ],
    );
  }

  pw.Widget _cell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildEnvCard(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#E8F5E9'),
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColor.fromHex('#A5D6A7')),
      ),
      child: pw.Column(
        children: [
          pw.Text(label,
              style: const pw.TextStyle(
                  fontSize: 9, color: PdfColors.grey600)),
          pw.SizedBox(height: 4),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _buildRecommendations(
      String diseaseType, List<String> recommendations) {
    final guidelines = recommendations.isNotEmpty
        ? recommendations
        : _defaultGuidelines(diseaseType);

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
                      child: pw.Text(g,
                          style: const pw.TextStyle(fontSize: 10))),
                ],
              ),
            )),
      ],
    );
  }

  List<String> _defaultGuidelines(String diseaseType) {
    switch (diseaseType.toLowerCase()) {
      case 'healthy':
        return [
          'The tea leaf appears healthy.',
          'Continue regular monitoring and standard cultural practices.',
          'Maintain proper irrigation and fertilization schedules.',
        ];
      case 'red rust':
        return [
          'Red Rust (Cephaleuros parasiticus) detected.',
          'Apply copper-based fungicide as a preventive/curative measure.',
          'Improve canopy ventilation by selective pruning.',
          'Remove and destroy heavily infected leaves to reduce inoculum.',
          'Monitor neighboring plants for spread.',
        ];
      case 'blister blight':
        return [
          'Blister Blight (Exobasidium vexans) detected.',
          'Apply systemic or contact fungicide (e.g., triadimefon, copper oxychloride).',
          'Carry out skiffing to remove infected shoots promptly.',
          'Avoid overhead irrigation which promotes spore dispersal.',
          'Increase monitoring frequency during cool, humid weather.',
        ];
      default:
        return [
          'Consult your plantation agronomist for a detailed treatment plan.',
          'Isolate affected plants where possible.',
          'Continue regular field monitoring.',
        ];
    }
  }

  String _formatName(String name) {
    switch (name) {
      case 'healthy':
        return 'Healthy';
      case 'red_rust':
        return 'Red Rust';
      case 'blister_blight':
        return 'Blister Blight';
      default:
        return name
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) =>
                w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
            .join(' ');
    }
  }
}
