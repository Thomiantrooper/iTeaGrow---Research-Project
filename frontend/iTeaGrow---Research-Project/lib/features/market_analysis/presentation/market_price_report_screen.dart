import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:iteagrow/core/design_system/design_system.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import '../data/models/market_models.dart';

class MarketPriceReportScreen extends ConsumerStatefulWidget {
  final MarketPriceResponse reportData;
  const MarketPriceReportScreen({super.key, required this.reportData});

  @override
  ConsumerState<MarketPriceReportScreen> createState() =>
      _MarketPriceReportScreenState();
}

class _MarketPriceReportScreenState
    extends ConsumerState<MarketPriceReportScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  final List<String> _gradesList = [
    'BOPF',
    'BOP',
    'Pekoe',
    'Fanning1',
    'Dust',
    'Dust1'
  ];

  Future<void> _selectDateRange(BuildContext context) async {
    final now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: TeaColors.freshLeaf,
              onPrimary: Colors.white,
              onSurface: TeaColors.darkGray,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        // Adjust end date to capture the full last day
        _endDate = picked.end.add(const Duration(hours: 23, minutes: 59));
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  // Helper function to extract and filter the history keys
  List<String> _getFilteredHistoryKeys() {
    final keys = widget.reportData.marketPrices.keys
        .where((k) => k != 'default')
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (keys.isEmpty) return [];

    // The first one is the "Current" latest week
    var historyKeys = keys.skip(1).toList();

    // Apply exact DateRange filtering if active
    if (_startDate != null && _endDate != null) {
      historyKeys = historyKeys.where((weekStr) {
        try {
          final dt = DateTime.parse(weekStr);
          return dt.isAfter(_startDate!) && dt.isBefore(_endDate!);
        } catch (_) {
          return true; // Keep malformed dates just in case, or drop them
        }
      }).toList();
    }

    return historyKeys;
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    final teaGreen = const PdfColor.fromInt(0xFF4A7C59);
    final lightGreen = const PdfColor.fromInt(0xFFE8F0E9);

    final keys = widget.reportData.marketPrices.keys
        .where((k) => k != 'default')
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final latestWeek = keys.isNotEmpty ? keys.first : 'N/A';
    final latestPrices = widget.reportData.latestPrices;
    final historyKeys = _getFilteredHistoryKeys();

    pw.Widget _buildPdfSummaryRow(
        String label, String value, pw.Font font, pw.Font fontBold,
        {PdfColor? valueColor}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 6),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: pw.TextStyle(
                    font: font, fontSize: 12, color: PdfColors.grey700)),
            pw.Text(value,
                style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 13,
                    color: valueColor ?? PdfColors.black)),
          ],
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        header: (context) => pw.Header(
          level: 0,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Market Prices Report',
                  style: pw.TextStyle(
                      font: fontBold, fontSize: 24, color: teaGreen)),
              pw.PdfLogo(), // Can replace with your custom SVG logo logic if needed
            ],
          ),
        ),
        footer: (context) => pw.Footer(
          leading: pw.Text('iTeaGrow - Smart Tea Management',
              style: pw.TextStyle(font: font, fontSize: 10, color: teaGreen)),
          trailing: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(
                  font: font, fontSize: 10, color: PdfColors.grey)),
        ),
        build: (context) => [
          pw.SizedBox(height: 10),
          pw.Text(
              'Generated on: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(
                  font: font, fontSize: 10, color: PdfColors.grey700)),
          if (_startDate != null && _endDate != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
                'Filtered Range: ${DateFormat('MMM dd, yyyy').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}',
                style: pw.TextStyle(
                    font: fontBold, fontSize: 10, color: teaGreen)),
          ],
          pw.SizedBox(height: 20),

          // Top Highlight card
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: teaGreen, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              color: lightGreen,
            ),
            padding: const pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Latest Auction Target: $latestWeek',
                    style: pw.TextStyle(
                        font: fontBold, fontSize: 16, color: teaGreen)),
                pw.Divider(color: teaGreen),
                ..._gradesList.map((g) => _buildPdfSummaryRow(
                    g, 'Rs. ${latestPrices[g] ?? 0.0}', font, fontBold)),
              ],
            ),
          ),

          if (historyKeys.isNotEmpty) ...[
            pw.SizedBox(height: 30),
            pw.Text('Historical Auction Records',
                style: pw.TextStyle(
                    font: fontBold, fontSize: 16, color: teaGreen)),
            pw.SizedBox(height: 10),
            pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Date',
                                style: pw.TextStyle(font: fontBold))),
                        ..._gradesList.map((g) => pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(g,
                                style: pw.TextStyle(font: fontBold)))),
                      ]),
                  ...historyKeys.map((week) {
                    final pastPrices =
                        widget.reportData.marketPrices[week] ?? {};
                    return pw.TableRow(children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child:
                              pw.Text(week, style: pw.TextStyle(font: font))),
                      ..._gradesList.map((g) {
                        final price = pastPrices.containsKey(g)
                            ? (pastPrices[g] as num).toDouble()
                            : 0.0;
                        return pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(price.toStringAsFixed(2),
                                style: pw.TextStyle(font: font)));
                      }),
                    ]);
                  })
                ])
          ] else ...[
            pw.SizedBox(height: 30),
            pw.Text('No historical records found for this timeframe.',
                style: pw.TextStyle(
                    font: font, fontSize: 12, color: PdfColors.grey600)),
          ]
        ],
      ),
    );

    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeaColors.mistGreen,
      appBar: AppBar(
        title: const Text('Price Report Setup'),
        backgroundColor: TeaColors.freshLeaf,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Date Filtering',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDateRange(context),
                        icon: const Icon(Icons.date_range,
                            color: TeaColors.freshLeaf),
                        label: Text(
                            _startDate != null
                                ? '${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd').format(_endDate!)}'
                                : 'Select Date Range',
                            style: const TextStyle(color: TeaColors.darkGray)),
                      ),
                    ),
                    if (_startDate != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        onPressed: _clearFilters,
                        tooltip: 'Clear Filter',
                      )
                    ]
                  ],
                )
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: PdfPreview(
              build: (format) => _generatePdf(format),
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false, // Ensures the dark/light format toggle is hidden
              allowSharing: true,
              allowPrinting: true,
              initialPageFormat: PdfPageFormat.a4,
              pdfFileName: 'Market_Prices_History.pdf',
              scrollViewDecoration:
                  const BoxDecoration(color: TeaColors.mistGreen),
            ),
          )
        ],
      ),
    );
  }
}
