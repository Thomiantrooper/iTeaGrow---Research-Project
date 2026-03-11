import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:iteagrow/l10n/app_localizations.dart';
import '../../../../core/design_system/tea_colors.dart';
import '../../../../core/design_system/tea_typography.dart';
import '../../../../core/services/pdf_report_service.dart';
import '../providers/market_providers.dart';

class MarketReportPreviewScreen extends ConsumerStatefulWidget {
  final String recordId;
  final List<String> historicalIds;

  const MarketReportPreviewScreen({
    super.key,
    required this.recordId,
    this.historicalIds = const [],
  });

  @override
  ConsumerState<MarketReportPreviewScreen> createState() =>
      _MarketReportPreviewScreenState();
}

class _MarketReportPreviewScreenState
    extends ConsumerState<MarketReportPreviewScreen> {
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _mainReportData;

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(marketApiServiceProvider);

      // 1. Fetch main report data
      final mainData = await api.getMarketReportData(widget.recordId);
      _mainReportData = mainData;

      // 2. Fetch historical records data
      List<Map<String, dynamic>> historicalRecords = [];
      for (final id in widget.historicalIds) {
        try {
          final hData = await api.getMarketReportData(id);
          if (hData.containsKey('record')) {
            historicalRecords.add(hData['record'] as Map<String, dynamic>);
          }
        } catch (e) {
          debugPrint('Error fetching historical record $id: $e');
        }
      }

      // 3. Generate PDF
      final pdfService = PdfReportService();
      _pdfBytes = await pdfService.generateMarketReport(mainData, historicalRecords);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Market Report Preview',
          style: TeaTypography.titleMedium.copyWith(color: TeaColors.white),
        ),
        backgroundColor: TeaColors.freshLeaf,
        foregroundColor: TeaColors.white,
        actions: [
          if (_pdfBytes != null) ...[
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share PDF',
              onPressed: _sharePdf,
            ),
            IconButton(
              icon: const Icon(Icons.print),
              tooltip: 'Print',
              onPressed: _printPdf,
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.reports_generating),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _generateReport,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfBytes == null) {
      return const Center(child: Text('Failed to generate PDF.'));
    }

    return PdfPreview(
      build: (format) async => _pdfBytes!,
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
      allowPrinting: false,
      allowSharing: false,
      pdfFileName:
          'iTeaGrow_Market_Report_${_mainReportData?['report_id'] ?? 'N/A'}.pdf',
    );
  }

  Future<void> _sharePdf() async {
    if (_pdfBytes == null) return;
    await Printing.sharePdf(
      bytes: _pdfBytes!,
      filename:
          'iTeaGrow_Market_Report_${_mainReportData?['report_id'] ?? 'N/A'}.pdf',
    );
  }

  Future<void> _printPdf() async {
    if (_pdfBytes == null) return;
    await Printing.layoutPdf(
      onLayout: (format) async => _pdfBytes!,
    );
  }
}
