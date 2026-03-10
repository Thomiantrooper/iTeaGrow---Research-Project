import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:iteagrow/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/pdf_report_service.dart';
import '../../../../core/theme/app_theme.dart';

class ReportPreviewScreen extends ConsumerStatefulWidget {
  final String detectionId;

  const ReportPreviewScreen({super.key, required this.detectionId});

  @override
  ConsumerState<ReportPreviewScreen> createState() =>
      _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends ConsumerState<ReportPreviewScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _reportData;
  Uint8List? _pdfBytes;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get<Map<String, dynamic>>(
        '/api/reports/${widget.detectionId}',
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (response.success && response.data != null && response.data!['detection'] != null) {
        _reportData = response.data;
        final pdfService = PdfReportService();
        _pdfBytes = await pdfService.generateReport(response.data!);
      } else {
        _error = response.error ?? 'No report data found for this detection';
      }
    } catch (e) {
      _error = 'Failed to load report: $e';
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.reports_preview_title),
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
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadReport,
                child: Text(AppLocalizations.of(context)!.common_retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfBytes == null) {
      return Center(child: Text(AppLocalizations.of(context)!.reports_no_pdf));
    }

    return Column(
      children: [
        // Report info header
        Container(
          padding: const EdgeInsets.all(12),
          color: AppTheme.primaryGreen.withOpacity(0.1),
          child: Row(
            children: [
              const Icon(Icons.description, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _reportData?['detection']?['disease_name'] ??
                          'Disease Report',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Report ID: ${_reportData?['report_id'] ?? 'N/A'}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.download),
                label: Text(AppLocalizations.of(context)!.common_save),
                onPressed: _sharePdf,
              ),
            ],
          ),
        ),
        // PDF preview
        Expanded(
          child: PdfPreview(
            build: (format) async => _pdfBytes!,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            allowPrinting: true,
            allowSharing: true,
            pdfFileName:
                'iTeaGrow_Report_${_reportData?['report_id'] ?? 'unknown'}.pdf',
          ),
        ),
      ],
    );
  }

  Future<void> _sharePdf() async {
    if (_pdfBytes == null) return;
    await Printing.sharePdf(
      bytes: _pdfBytes!,
      filename:
          'iTeaGrow_Report_${_reportData?['report_id'] ?? 'unknown'}.pdf',
    );
  }

  Future<void> _printPdf() async {
    if (_pdfBytes == null) return;
    await Printing.layoutPdf(
      onLayout: (format) async => _pdfBytes!,
    );
  }
}
