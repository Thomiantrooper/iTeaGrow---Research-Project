import 'dart:typed_data';
import '../../domain/entities/disease_detection_result.dart';

/// A single leaf scan entry within a multi-leaf session.
class LeafScanEntry {
  final int leafIndex;
  final Uint8List imageBytes;
  final String imagePath;
  final DiseaseDetectionResult result;
  final DateTime scannedAt;

  LeafScanEntry({
    required this.leafIndex,
    required this.imageBytes,
    required this.imagePath,
    required this.result,
    DateTime? scannedAt,
  }) : scannedAt = scannedAt ?? DateTime.now();
}

/// Summary of a multi-leaf scanning session.
class MultiLeafSummary {
  final int totalLeaves;
  final int healthyCount;
  final int redRustCount;
  final int blisterBlightCount;
  final int otherCount;
  final double averageConfidence;
  final String overallStatus;
  final String overallSeverity;
  final bool requiresAction;
  final List<String> recommendations;

  MultiLeafSummary({
    required this.totalLeaves,
    required this.healthyCount,
    required this.redRustCount,
    required this.blisterBlightCount,
    required this.otherCount,
    required this.averageConfidence,
    required this.overallStatus,
    required this.overallSeverity,
    required this.requiresAction,
    required this.recommendations,
  });

  double get healthPercentage =>
      totalLeaves > 0 ? (healthyCount / totalLeaves) * 100 : 0;
  double get infectedPercentage => 100 - healthPercentage;
}

/// Manages a multi-leaf scanning session where several leaves from the same
/// bush can be analysed individually, then summarised.
class MultiLeafScanService {
  final List<LeafScanEntry> _entries = [];
  DateTime? _sessionStart;

  List<LeafScanEntry> get entries => List.unmodifiable(_entries);
  int get leafCount => _entries.length;
  bool get hasScans => _entries.isNotEmpty;
  DateTime? get sessionStart => _sessionStart;

  /// Start a fresh session (clears previous scans).
  void startSession() {
    _entries.clear();
    _sessionStart = DateTime.now();
  }

  /// Add a completed scan result to the session.
  void addScan({
    required Uint8List imageBytes,
    required String imagePath,
    required DiseaseDetectionResult result,
  }) {
    _entries.add(LeafScanEntry(
      leafIndex: _entries.length + 1,
      imageBytes: imageBytes,
      imagePath: imagePath,
      result: result,
    ));
  }

  /// Remove a scan by index.
  void removeScan(int index) {
    if (index >= 0 && index < _entries.length) {
      _entries.removeAt(index);
      // Re-index
      for (int i = 0; i < _entries.length; i++) {
        _entries[i] = LeafScanEntry(
          leafIndex: i + 1,
          imageBytes: _entries[i].imageBytes,
          imagePath: _entries[i].imagePath,
          result: _entries[i].result,
          scannedAt: _entries[i].scannedAt,
        );
      }
    }
  }

  /// Generate summary of all scanned leaves in this session.
  MultiLeafSummary generateSummary() {
    if (_entries.isEmpty) {
      return MultiLeafSummary(
        totalLeaves: 0,
        healthyCount: 0,
        redRustCount: 0,
        blisterBlightCount: 0,
        otherCount: 0,
        averageConfidence: 0,
        overallStatus: 'No scans',
        overallSeverity: 'None',
        requiresAction: false,
        recommendations: ['Scan at least one leaf to begin analysis.'],
      );
    }

    int healthy = 0, redRust = 0, blisterBlight = 0, other = 0;
    double totalConfidence = 0;

    for (final entry in _entries) {
      totalConfidence += entry.result.confidence;
      switch (entry.result.diseaseType) {
        case 'Healthy':
          healthy++;
          break;
        case 'Red Rust':
          redRust++;
          break;
        case 'Blister Blight':
          blisterBlight++;
          break;
        default:
          other++;
      }
    }

    final total = _entries.length;
    final avgConfidence = totalConfidence / total;
    final infectedCount = redRust + blisterBlight + other;
    final infectedRatio = infectedCount / total;

    // Determine overall status
    String overallStatus;
    String overallSeverity;
    bool requiresAction;

    if (infectedCount == 0) {
      overallStatus = 'Plant Healthy';
      overallSeverity = 'None';
      requiresAction = false;
    } else if (infectedRatio < 0.25) {
      overallStatus = 'Minor Infection';
      overallSeverity = 'Low';
      requiresAction = false;
    } else if (infectedRatio < 0.5) {
      overallStatus = 'Moderate Infection';
      overallSeverity = 'Medium';
      requiresAction = true;
    } else if (infectedRatio < 0.75) {
      overallStatus = 'Significant Infection';
      overallSeverity = 'High';
      requiresAction = true;
    } else {
      overallStatus = 'Severe Infection';
      overallSeverity = 'Critical';
      requiresAction = true;
    }

    // Build recommendations
    final recommendations = <String>[];
    if (healthy == total) {
      recommendations.addAll([
        'All $total leaves appear healthy.',
        'Continue regular monitoring and standard cultural practices.',
        'Maintain current pest management schedule.',
      ]);
    } else {
      recommendations.add(
          '$infectedCount of $total leaves show signs of disease.');
      if (redRust > 0) {
        recommendations.addAll([
          'Red Rust detected on $redRust leaf${redRust > 1 ? 'es' : ''}. '
              'Apply copper-based fungicide and improve canopy ventilation.',
        ]);
      }
      if (blisterBlight > 0) {
        recommendations.addAll([
          'Blister Blight detected on $blisterBlight leaf${blisterBlight > 1 ? 'es' : ''}. '
              'Apply systemic fungicide and avoid overhead irrigation.',
        ]);
      }
      if (requiresAction) {
        recommendations.add(
            'Immediate action recommended. Isolate affected plants and consult plantation agronomist.');
      } else {
        recommendations.add(
            'Monitor closely over the next 7-14 days for further spread.');
      }
    }

    return MultiLeafSummary(
      totalLeaves: total,
      healthyCount: healthy,
      redRustCount: redRust,
      blisterBlightCount: blisterBlight,
      otherCount: other,
      averageConfidence: avgConfidence,
      overallStatus: overallStatus,
      overallSeverity: overallSeverity,
      requiresAction: requiresAction,
      recommendations: recommendations,
    );
  }

  /// Clear session data.
  void clearSession() {
    _entries.clear();
    _sessionStart = null;
  }
}
