import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/tea_colors.dart';
import '../../../../core/design_system/tea_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/soil_health_record.dart';

class SoilHealthPdfScreen extends StatelessWidget {
  final SoilHealthRecord record;

  const SoilHealthPdfScreen({super.key, required this.record});

  String _getZoneName(int id) {
    if (id <= 25) return 'North';
    if (id <= 50) return 'East';
    if (id <= 75) return 'South';
    if (id <= 100) return 'West';
    return 'Central';
  }

  String _getHectareLabel(int id) {
    return '${_getZoneName(id)} B$id';
  }

  String _getLocationLabel(SoilHealthRecord r) {
    final base = _getHectareLabel(r.hectareId);
    if (r.blockId != null) return '$base · Block ${r.blockId}';
    return base;
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    final primaryGreen = PdfColor.fromHex('#1A3D2B'); // TeaColors.deepForest
    final accentGreen = PdfColor.fromHex('#2E7D32');
    final offWhite = PdfColor.fromHex('#F7FAF8');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('iTeaGrow Official Report',
                  style: pw.TextStyle(
                      font: fontBold, fontSize: 18, color: primaryGreen)),
              pw.Text('Agricultural Monitoring System',
                  style: pw.TextStyle(
                      font: font, fontSize: 10, color: PdfColors.grey600)),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(
                  font: font, fontSize: 10, color: PdfColors.grey)),
        ),
        build: (context) => [
          // ── Title Section ──
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Soil Health Analysis',
                      style: pw.TextStyle(
                          font: fontBold, fontSize: 24, color: primaryGreen)),
                  pw.SizedBox(height: 4),
                  pw.Text('Location: ${_getLocationLabel(record)}',
                      style: pw.TextStyle(
                          font: fontBold, fontSize: 14, color: accentGreen)),
                  if (record.blockId != null)
                    pw.Text('Sub-division block ${record.blockId}',
                        style: pw.TextStyle(
                            font: font, fontSize: 11, color: PdfColors.grey700)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                      'Date: ${DateFormat('yyyy-MM-dd').format(record.timestamp)}',
                      style: pw.TextStyle(font: font, fontSize: 11)),
                  pw.Text('Time: ${record.formattedTime}',
                      style: pw.TextStyle(font: font, fontSize: 11)),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 12),
          pw.Divider(color: primaryGreen, thickness: 1.0),
          pw.SizedBox(height: 12),

          // ── Executive Summary ──
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: offWhite,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('EXECUTIVE SUMMARY',
                    style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 10,
                        color: PdfColors.grey700,
                        letterSpacing: 1.5)),
                pw.SizedBox(height: 8),
                pw.Text(
                  'The soil analysis for ${_getLocationLabel(record)} indicates an overall condition of ${record.healthStatus.label.toUpperCase()}. '
                  'Immediate actions are recommended based on the chemistry breakdown below.',
                  style:
                      pw.TextStyle(font: font, fontSize: 12, lineSpacing: 1.5),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 15),

          // ── Chemistry Table ──
          pw.Text('Soil Chemistry Breakdown',
              style: pw.TextStyle(
                  font: fontBold, fontSize: 16, color: primaryGreen)),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildCell('Parameter', fontBold, isHeader: true),
                  _buildCell('Recorded Value', fontBold, isHeader: true),
                  _buildCell('Optimal Range', fontBold, isHeader: true),
                  _buildCell('Status', fontBold, isHeader: true),
                ],
              ),
              _buildDataRow(
                  'Nitrogen (N)',
                  '${record.nitrogen.toStringAsFixed(0)} mg/kg',
                  '150 – 250 mg/kg',
                  _getStatus(record.nitrogen, 150, 250),
                  font),
              _buildDataRow(
                  'Phosphorus (P)',
                  '${record.phosphorus.toStringAsFixed(0)} mg/kg',
                  '80 – 150 mg/kg',
                  _getStatus(record.phosphorus, 80, 150),
                  font),
              _buildDataRow(
                  'Potassium (K)',
                  '${record.potassium.toStringAsFixed(0)} mg/kg',
                  '150 – 250 mg/kg',
                  _getStatus(record.potassium, 150, 250),
                  font),
              _buildDataRow(
                  'Soil pH',
                  record.ph.toStringAsFixed(1),
                  '4.5 – 5.5',
                  _getStatus(record.ph, 4.5, 5.5),
                  font),
              _buildDataRow(
                  'Soil Moisture',
                  '${record.humidity.toStringAsFixed(1)}%',
                  '40 – 70%',
                  _getStatus(record.humidity, 40, 70),
                  font),
              _buildDataRow(
                  'Electrical Conductivity',
                  '${(record.ec * 1000).toStringAsFixed(0)} µS/cm',
                  '100 – 500 µS/cm',
                  _getStatus(record.ec * 1000, 100, 500),
                  font),
              _buildDataRow(
                  'Temperature',
                  '${record.temperature.toStringAsFixed(1)} °C',
                  '18 – 25 °C',
                  _getStatus(record.temperature, 18, 25),
                  font),
            ],
          ),

          pw.SizedBox(height: 15),

          // ── Fertilizer Recommendations ──
          pw.Text('Required Fertilizer Actions',
              style: pw.TextStyle(
                  font: fontBold, fontSize: 16, color: primaryGreen)),
          pw.SizedBox(height: 12),
          if (record.sanitizedAdvice.isEmpty)
            pw.Text(
                'No immediate fertilization required. Maintain current monitoring schedule.',
                style: pw.TextStyle(
                    font: font, fontSize: 11, color: PdfColors.grey700))
          else
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: record.sanitizedAdvice.map((advice) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        margin: const pw.EdgeInsets.only(top: 4, right: 8),
                        width: 5,
                        height: 5,
                        decoration: const pw.BoxDecoration(
                            color: PdfColors.grey600,
                            shape: pw.BoxShape.circle),
                      ),
                      pw.Expanded(
                        child: pw.Text(advice,
                            style: pw.TextStyle(font: font, fontSize: 11)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColors.grey300),
          pw.Center(
            child: pw.Text('Certified by iTeaGrow Intelligence Engine',
                style: pw.TextStyle(
                    font: font,
                    fontSize: 9,
                    color: PdfColors.grey500,
                    fontStyle: pw.FontStyle.italic)),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildCell(String text, pw.Font font, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text,
          style: pw.TextStyle(font: font, fontSize: isHeader ? 11 : 10)),
    );
  }

  pw.TableRow _buildDataRow(
      String label, String value, String target, String status, pw.Font font) {
    return pw.TableRow(
      children: [
        _buildCell(label, font),
        _buildCell(value, font),
        _buildCell(target, font),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(status,
              style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color:
                      status == 'Optimal' ? PdfColors.green : PdfColors.red)),
        ),
      ],
    );
  }

  String _getStatus(double val, double min, double max) {
    if (val < min) return 'Low';
    if (val > max) return 'High';
    return 'Optimal';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '${AppLocalizations.of(context)!.soil_pdf_export_title}: ${_getLocationLabel(record)}',
          style: TeaTypography.titleMedium.copyWith(color: TeaColors.white),
        ),
        backgroundColor: TeaColors.deepForest,
        foregroundColor: TeaColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowSharing: true,
        allowPrinting: true,
        initialPageFormat: PdfPageFormat.a4,
        pdfFileName:
            'iTeaGrow_Soil_Report_${_getLocationLabel(record).replaceAll(' ', '_').replaceAll('·', 'B')}.pdf',
      ),
    );
  }
}
