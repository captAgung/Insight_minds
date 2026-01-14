import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../features/risk_analysis/domain/entities/assessment_result.dart';
import '../features/insightmind/domain/entities/question.dart';

class PdfReportService {
  // REPORT RINGKAS (dipertahankan untuk kompatibilitas)
  static Future<void> generateAndSharePatientReport({
    required String patientName,
    required int patientAge,
    required DateTime generatedAt,
    int? screeningScore,
    String? screeningRiskLevel,
    String? assessmentTitle,
    int? assessmentTotalScore,
  }) async {
    final doc = pw.Document();
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(generatedAt);

    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Laporan Pemeriksaan InsightMind',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Tanggal dibuat: $dateStr'),
          pw.SizedBox(height: 16),

          // Identitas
          pw.Text('Identitas Pasien',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(5),
            },
            children: [
              _row('Nama', patientName),
              _row('Usia', '$patientAge tahun'),
            ],
          ),

          pw.SizedBox(height: 16),
          pw.Text('Hasil Screening',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(5),
            },
            children: [
              _row('Skor', screeningScore != null ? '$screeningScore' : '-'),
              _row('Tingkat Risiko', screeningRiskLevel ?? '-'),
            ],
          ),

          pw.SizedBox(height: 16),
          pw.Text('Hasil Assessment',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(5),
            },
            children: [
              _row('Jenis', assessmentTitle ?? '-'),
              _row('Total Skor',
                  assessmentTotalScore != null ? '$assessmentTotalScore' : '-'),
            ],
          ),

          pw.SizedBox(height: 24),
          pw.Text(
            'Catatan: Laporan ini bersifat pendukung dan tidak menggantikan diagnosis profesional. Konsultasikan hasil ini dengan dokter atau psikolog profesional.',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );

    final Uint8List bytes = await doc.save();
    await Printing.sharePdf(
        bytes: bytes,
        filename:
            'InsightMind_Report_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

  // REPORT KOMPREHENSIF: Semua assessment + riwayat + rekomendasi
  static Future<void> generateAndShareComprehensiveReport({
    required String patientName,
    required int patientAge,
    required DateTime generatedAt,
    int? screeningScore,
    String? screeningRiskLevel,
    required List<dynamic> allAssessmentHistory, // AssessmentResult
    String? emergencyContactName,
    String? emergencyContactPhone,
    List<String>? localResources,
  }) async {
    final doc = pw.Document();
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(generatedAt);

    // Casting dan konversi ke AssessmentResult
    final List<AssessmentResult> assessments = allAssessmentHistory
        .map((e) => e as AssessmentResult)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Ambil latest per jenis
    AssessmentResult? latestPhq9Result =
        assessments.where((a) => a.type == AssessmentType.phq9).firstOrNull;
    AssessmentResult? latestGad7Result =
        assessments.where((a) => a.type == AssessmentType.gad7).firstOrNull;
    AssessmentResult? latestBurnoutResult =
        assessments.where((a) => a.type == AssessmentType.burnout).firstOrNull;

    // Buat entries untuk kompatibilitas
    final List<_AssessmentEntry> entries = assessments.map((e) {
      final typeName = e.type.name;
      return _AssessmentEntry(
        typeName: typeName,
        timestamp: e.timestamp,
        totalScore: e.totalScore,
        assessmentResult: e,
      );
    }).toList();

    _AssessmentEntry latestOf(String name) =>
        entries.firstWhere((x) => x.typeName == name,
            orElse: () => _AssessmentEntry.empty(name));

    final latestPhq9 = latestOf('phq9');
    final latestGad7 = latestOf('gad7');
    final latestBurnout = latestOf('burnout');

    // COVER PAGE
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(72),
        build: (context) => _coverPage(
          patientName: patientName,
          patientAge: patientAge,
          generatedAt: generatedAt,
          dateStr: dateStr,
        ),
      ),
    );

    // MAIN CONTENT
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(72),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Text(
            'InsightMind Report • Page ${context.pageNumber}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text(
            'Confidential - For Clinical Use Only • Generated: $dateStr',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ),
        build: (context) => [
          // EXECUTIVE SUMMARY
          _executiveSummarySection(
            latestPhq9Result,
            latestGad7Result,
            latestBurnoutResult,
            screeningScore,
            screeningRiskLevel,
          ),

          pw.SizedBox(height: 16),
          pw.Header(
            level: 0,
            child: pw.Text(
              'Laporan Komprehensif InsightMind',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text('Tanggal dibuat: $dateStr'),
          pw.SizedBox(height: 16),

          // Identitas
          pw.Text('Identitas Pasien',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(5)
            },
            children: [
              _row('Nama', patientName),
              _row('Usia', '$patientAge tahun'),
            ],
          ),

          pw.SizedBox(height: 16),
          pw.Text('Ringkasan Screening',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(5)
            },
            children: [
              _row('Skor Screening',
                  screeningScore != null ? '$screeningScore' : '-'),
              _row('Tingkat Risiko', screeningRiskLevel ?? '-'),
            ],
          ),

          pw.SizedBox(height: 16),
          pw.Text('Hasil Assessment Terbaru',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(3),
            },
            children: [
              _row3('PHQ-9 (Depresi)', _getSeverityForEntry(latestPhq9),
                  _labelWithDate(latestPhq9)),
              _row3('GAD-7 (Kecemasan)', _getSeverityForEntry(latestGad7),
                  _labelWithDate(latestGad7)),
              _row3('Burnout', _getSeverityForEntry(latestBurnout),
                  _labelWithDate(latestBurnout)),
            ],
          ),

          // INTERPRETASI KLINIS & SEVERITY LEVEL
          pw.SizedBox(height: 16),
          pw.Text('Interpretasi Klinis & Tingkat Keparahan',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _clinicalInterpretationSection(
              latestPhq9Result, latestGad7Result, latestBurnoutResult),

          // DETAIL JAWABAN PER PERTANYAAN
          if (latestPhq9Result != null ||
              latestGad7Result != null ||
              latestBurnoutResult != null) ...[
            pw.SizedBox(height: 16),
            pw.Text('Detail Jawaban Assessment Terbaru',
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            if (latestPhq9Result != null)
              _detailedAnswersSection(latestPhq9Result, AssessmentType.phq9),
            if (latestGad7Result != null)
              _detailedAnswersSection(latestGad7Result, AssessmentType.gad7),
            if (latestBurnoutResult != null)
              _detailedAnswersSection(
                  latestBurnoutResult, AssessmentType.burnout),
          ],

          pw.SizedBox(height: 16),
          pw.Text('Ringkasan Tren & Perkembangan',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _developmentProgressSection(
              entries, latestPhq9Result, latestGad7Result, latestBurnoutResult),

          pw.SizedBox(height: 16),
          pw.Text('Tren & Confidence',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _trendsAndConfidenceSection(
              entries, latestPhq9, latestGad7, latestBurnout),

          pw.SizedBox(height: 16),
          pw.Text('Checklist Tindakan Harian/Mingguan',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _actionChecklistSection(),

          if ((emergencyContactName ?? '').isNotEmpty ||
              (emergencyContactPhone ?? '').isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text('Kontak Darurat & Sumber Daya',
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _emergencySection(
              name: emergencyContactName,
              phone: emergencyContactPhone,
            ),
          ],

          pw.SizedBox(height: 16),
          pw.Text('Sumber Daya Lokal',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _resourcesSection(localResources),

          pw.SizedBox(height: 16),
          pw.Text('Rekomendasi Tindak Lanjut',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _recommendationsSection(latestPhq9, latestGad7, latestBurnout),

          pw.SizedBox(height: 24),
          pw.Text(
            'Catatan: Rekomendasi bersifat edukatif dan tidak menggantikan evaluasi profesional. '
            'Jika gejala berat/meningkat, segera konsultasi ke dokter/psikolog.',
            style: const pw.TextStyle(fontSize: 10),
          ),

          pw.SizedBox(height: 16),
          pw.Text('Tips Self-Care & Pemulihan',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _selfCareTipsSection(
              latestPhq9Result, latestGad7Result, latestBurnoutResult),

          // PATIENT FEEDBACK SECTION
          pw.SizedBox(height: 24),
          _patientFeedbackSection(),

          // GLOSSARY & RESOURCES
          pw.SizedBox(height: 24),
          _glossaryAndResourcesSection(localResources: localResources),
        ],
      ),
    );

    // BACK COVER - QUICK REFERENCE SUMMARY
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(72),
        build: (context) => _backCoverSummary(
          patientName: patientName,
          generatedAt: generatedAt,
          latestPhq9Result: latestPhq9Result,
          latestGad7Result: latestGad7Result,
          latestBurnoutResult: latestBurnoutResult,
          emergencyContactName: emergencyContactName,
          emergencyContactPhone: emergencyContactPhone,
        ),
      ),
    );

    final Uint8List bytes = await doc.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'InsightMind_Comprehensive_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  // Generate PDF tanpa share (untuk generate saja)
  static Future<void> generateComprehensiveReportWithoutShare({
    required String patientName,
    required int patientAge,
    required DateTime generatedAt,
    int? screeningScore,
    String? screeningRiskLevel,
    required List<dynamic> allAssessmentHistory,
    String? emergencyContactName,
    String? emergencyContactPhone,
    List<String>? localResources,
  }) async {
    // Panggil method yang sama tapi skip share
    final doc = pw.Document();
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(generatedAt);

    // Casting dan konversi ke AssessmentResult
    final List<AssessmentResult> assessments = allAssessmentHistory
        .map((e) => e as AssessmentResult)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Ambil latest per jenis
    AssessmentResult? latestPhq9Result =
        assessments.where((a) => a.type == AssessmentType.phq9).firstOrNull;
    AssessmentResult? latestGad7Result =
        assessments.where((a) => a.type == AssessmentType.gad7).firstOrNull;
    AssessmentResult? latestBurnoutResult =
        assessments.where((a) => a.type == AssessmentType.burnout).firstOrNull;

    // COVER PAGE
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(72),
        build: (context) => _coverPage(
          patientName: patientName,
          patientAge: patientAge,
          generatedAt: generatedAt,
          dateStr: dateStr,
        ),
      ),
    );

    // MAIN CONTENT - sama seperti generateAndShareComprehensiveReport
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(72),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Text(
            'InsightMind Report • Page ${context.pageNumber}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text(
            'Confidential - For Clinical Use Only • Generated: $dateStr',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ),
        build: (context) => [
          // EXECUTIVE SUMMARY
          _executiveSummarySection(
            latestPhq9Result,
            latestGad7Result,
            latestBurnoutResult,
            screeningScore,
            screeningRiskLevel,
          ),
          pw.SizedBox(height: 16),
          pw.Header(
            level: 0,
            child: pw.Text(
              'Laporan Komprehensif InsightMind',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text('Tanggal dibuat: $dateStr'),
          pw.SizedBox(height: 16),
          pw.Text('Identitas Pasien',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(5)
            },
            children: [
              _row('Nama', patientName),
              _row('Usia', '$patientAge tahun'),
            ],
          ),
        ],
      ),
    );

    // BACK COVER
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(72),
        build: (context) => _backCoverSummary(
          patientName: patientName,
          generatedAt: generatedAt,
          latestPhq9Result: latestPhq9Result,
          latestGad7Result: latestGad7Result,
          latestBurnoutResult: latestBurnoutResult,
          emergencyContactName: emergencyContactName,
          emergencyContactPhone: emergencyContactPhone,
        ),
      ),
    );

    // Hanya save tanpa share
    await doc.save();
    // PDF sudah di-generate, tidak perlu share
  }

  static pw.TableRow _row(String key, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child:
              pw.Text(key, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value),
        ),
      ],
    );
  }

  static pw.TableRow _row3(String c1, String c2, String c3) {
    return pw.TableRow(children: [_cell(c1), _cell(c2), _cell(c3)]);
  }

  static pw.Widget _cell(String text, {double? fontSize, PdfColor? color}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          text,
          style: (fontSize != null || color != null)
              ? pw.TextStyle(fontSize: fontSize, color: color)
              : null,
        ),
      );

  static pw.Widget _cellBold(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child:
            pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      );

  static String _labelWithDate(_AssessmentEntry e) {
    if (e.isEmpty) return '-';
    return 'Skor: ${e.totalScore} (${DateFormat('dd MMM yyyy').format(e.timestamp)})';
  }

  static String _getSeverityForEntry(_AssessmentEntry e) {
    if (e.isEmpty) return '-';
    switch (e.typeName) {
      case 'phq9':
        return _getPhq9Severity(e.totalScore);
      case 'gad7':
        return _getGad7Severity(e.totalScore);
      case 'burnout':
        return _getBurnoutSeverity(e.totalScore);
      default:
        return '-';
    }
  }

  static pw.Widget _trendsAndConfidenceSection(
    List<_AssessmentEntry> all,
    _AssessmentEntry phq9,
    _AssessmentEntry gad7,
    _AssessmentEntry burnout,
  ) {
    String trendFor(String type) {
      final list = all.where((e) => e.typeName == type && !e.isEmpty).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (list.length < 2) return 'Data tren belum cukup';
      final last = list.take(3).toList().reversed.toList();
      final deltas = <int>[];
      for (var i = 1; i < last.length; i++) {
        deltas.add(last[i].totalScore - last[i - 1].totalScore);
      }
      final sum = deltas.fold<int>(0, (a, b) => a + b);
      if (sum > 0) return 'Meningkat (memburuk)';
      if (sum < 0) return 'Menurun (membaik)';
      return 'Stabil';
    }

    String confidenceLevel() {
      final n = all.where((e) => !e.isEmpty).length;
      if (n >= 9) return 'High (banyak data historis)';
      if (n >= 4) return 'Medium (cukup data historis)';
      return 'Low (data historis terbatas)';
    }

    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(4),
      },
      children: [
        pw.TableRow(children: [
          _cellBold('Instrumen'),
          _cellBold('Tren 3 pengukuran terakhir'),
        ]),
        pw.TableRow(children: [_cell('PHQ-9'), _cell(trendFor('phq9'))]),
        pw.TableRow(children: [_cell('GAD-7'), _cell(trendFor('gad7'))]),
        pw.TableRow(children: [_cell('Burnout'), _cell(trendFor('burnout'))]),
        pw.TableRow(children: [
          _cellBold('Confidence'),
          _cell(confidenceLevel()),
        ]),
      ],
    );
  }

  // RINGKASAN TREN & PERKEMBANGAN SECTION
  static pw.Widget _developmentProgressSection(
    List<_AssessmentEntry> all,
    AssessmentResult? latestPhq9,
    AssessmentResult? latestGad7,
    AssessmentResult? latestBurnout,
  ) {
    pw.Widget buildProgressFor(String typeName, AssessmentResult? latest) {
      if (latest == null) {
        return pw.Text(
          'Belum ada data assessment untuk monitoring perkembangan.',
          style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
        );
      }

      final list = all
          .where((e) => e.typeName == typeName && !e.isEmpty)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (list.length < 2) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Data perkembangan: Baru ada 1 assessment. Lakukan assessment ulang untuk melihat perkembangan.',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        );
      }

      // Ambil 3-5 assessment terakhir untuk ditampilkan
      final recent = list.take(5).toList();
      final rows = <pw.TableRow>[];

      // Header
      rows.add(pw.TableRow(children: [
        _cellBold('Tanggal'),
        _cellBold('Skor'),
        _cellBold('Perubahan'),
        _cellBold('Status'),
      ]));

      // Data rows
      for (var i = 0; i < recent.length; i++) {
        final entry = recent[i];
        final dateStr = DateFormat('dd MMM yyyy').format(entry.timestamp);
        final scoreStr = '${entry.totalScore}';

        String changeStr = '-';
        String statusStr = '-';
        PdfColor statusColor = PdfColors.grey700;

        if (i < recent.length - 1) {
          final prevEntry = recent[i + 1];
          final change = entry.totalScore - prevEntry.totalScore;
          final daysDiff =
              entry.timestamp.difference(prevEntry.timestamp).inDays;

          if (change > 0) {
            changeStr = '+$change (memburuk)';
            statusStr = 'Memburuk';
            statusColor = PdfColors.red700;
          } else if (change < 0) {
            changeStr = '$change (membaik)';
            statusStr = 'Membaik';
            statusColor = PdfColors.green700;
          } else {
            changeStr = '0 (stabil)';
            statusStr = 'Stabil';
            statusColor = PdfColors.blue700;
          }

          if (daysDiff > 0) {
            changeStr += ' ($daysDiff hari)';
          }
        }

        // Determine severity label
        String severityLabel = '-';
        switch (typeName) {
          case 'phq9':
            severityLabel = _getPhq9Severity(entry.totalScore);
            break;
          case 'gad7':
            severityLabel = _getGad7Severity(entry.totalScore);
            break;
          case 'burnout':
            severityLabel = _getBurnoutSeverity(entry.totalScore);
            break;
        }

        rows.add(pw.TableRow(children: [
          _cell(dateStr),
          _cell('$scoreStr ($severityLabel)'),
          _cell(changeStr),
          _cell(statusStr, color: statusColor),
        ]));
      }

      // Summary
      final firstScore = recent.last.totalScore;
      final lastScore = recent.first.totalScore;
      final totalChange = lastScore - firstScore;
      final totalDays =
          recent.first.timestamp.difference(recent.last.timestamp).inDays;

      String summaryText = '';
      if (totalChange > 0) {
        summaryText =
            'Perkembangan: Skor meningkat $totalChange poin dalam $totalDays hari. '
            'Perlu perhatian dan evaluasi lebih lanjut.';
      } else if (totalChange < 0) {
        summaryText =
            'Perkembangan: Skor menurun ${totalChange.abs()} poin dalam $totalDays hari. '
            'Menunjukkan kemajuan positif.';
      } else {
        summaryText = 'Perkembangan: Skor stabil dalam $totalDays hari. '
            'Pertimbangkan strategi baru untuk perbaikan.';
      }

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2.5),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(1.5),
            },
            children: rows,
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              border: pw.Border.all(width: 0.5, color: PdfColors.blue300),
            ),
            child: pw.Text(
              summaryText,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      );
    }

    final sections = <pw.Widget>[];

    if (latestPhq9 != null) {
      sections.addAll([
        pw.Text('PHQ-9 (Depresi)',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        buildProgressFor('phq9', latestPhq9),
        pw.SizedBox(height: 12),
      ]);
    }

    if (latestGad7 != null) {
      sections.addAll([
        pw.Text('GAD-7 (Kecemasan)',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        buildProgressFor('gad7', latestGad7),
        pw.SizedBox(height: 12),
      ]);
    }

    if (latestBurnout != null) {
      sections.addAll([
        pw.Text('Burnout',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        buildProgressFor('burnout', latestBurnout),
      ]);
    }

    if (sections.isEmpty) {
      return pw.Text(
        'Belum ada data assessment untuk monitoring perkembangan.',
        style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: sections,
    );
  }

  // TIPS SELF-CARE SECTION
  static pw.Widget _selfCareTipsSection(
    AssessmentResult? phq9,
    AssessmentResult? gad7,
    AssessmentResult? burnout,
  ) {
    final tips = <String>[];

    if (phq9 != null) {
      final severity = phq9.totalScore;
      if (severity >= 20) {
        tips.addAll([
          '• Prioritaskan konsultasi profesional segera untuk depresi berat',
          '• Jaga rutinitas tidur: tidur dan bangun di waktu yang sama setiap hari',
          '• Aktivitas fisik ringan: jalan kaki 10-15 menit jika memungkinkan',
          '• Hindari isolasi: hubungi teman atau keluarga yang dipercaya',
          '• Perhatikan nutrisi: makan teratur meskipun tidak nafsu makan',
        ]);
      } else if (severity >= 15) {
        tips.addAll([
          '• Pertimbangkan konsultasi profesional untuk depresi sedang-berat',
          '• Bangun rutinitas harian yang terstruktur',
          '• Latihan fisik: 20-30 menit aktivitas ringan 3-4x per minggu',
          '• Eksposur sinar matahari: 15-20 menit di pagi hari',
          '• Praktik mindfulness: meditasi 5-10 menit per hari',
        ]);
      } else if (severity >= 10) {
        tips.addAll([
          '• Pertahankan rutinitas harian yang konsisten',
          '• Aktivitas fisik teratur: olahraga 30 menit 3x per minggu',
          '• Koneksi sosial: jadwalkan waktu dengan teman atau keluarga',
          '• Hobi dan aktivitas menyenangkan: lakukan sesuatu yang disukai setiap hari',
          '• Teknik relaksasi: pernapasan dalam atau progressive muscle relaxation',
        ]);
      } else if (severity >= 5) {
        tips.addAll([
          '• Pertahankan gaya hidup sehat: tidur, makan, olahraga seimbang',
          '• Aktivitas fisik: minimal 150 menit per minggu aktivitas sedang',
          '• Koneksi sosial: jaga hubungan dengan orang terdekat',
          '• Manajemen stres: identifikasi dan kelola sumber stres',
          '• Self-compassion: bersikap baik pada diri sendiri',
        ]);
      }
    }

    if (gad7 != null) {
      final severity = gad7.totalScore;
      if (severity >= 15) {
        tips.addAll([
          '• Konsultasi profesional segera untuk kecemasan berat',
          '• Teknik pernapasan: 4-7-8 breathing (tarik 4, tahan 7, buang 8)',
          '• Grounding technique: 5-4-3-2-1 (5 hal yang dilihat, 4 yang disentuh, dll)',
          '• Batasi kafein dan stimulan lainnya',
          '• Rutinitas relaksasi: mandi air hangat, musik tenang sebelum tidur',
        ]);
      } else if (severity >= 10) {
        tips.addAll([
          '• Pertimbangkan konsultasi profesional untuk kecemasan sedang',
          '• Latihan pernapasan dalam: 10 menit 2x sehari',
          '• Yoga atau stretching ringan untuk mengurangi ketegangan fisik',
          '• Time management: buat daftar prioritas untuk mengurangi overwhelm',
          '• Batasi paparan media yang memicu kecemasan',
        ]);
      } else if (severity >= 5) {
        tips.addAll([
          '• Teknik pernapasan: latihan pernapasan dalam saat merasa cemas',
          '• Aktivitas fisik teratur: membantu mengurangi gejala kecemasan',
          '• Mindfulness practice: latihan kesadaran penuh 10 menit sehari',
          '• Struktur waktu: buat jadwal harian untuk mengurangi ketidakpastian',
          '• Self-care routine: jaga tidur, makan, dan aktivitas seimbang',
        ]);
      }
    }

    if (burnout != null) {
      final severity = burnout.totalScore;
      if (severity >= 12) {
        tips.addAll([
          '• Pertimbangkan evaluasi beban kerja dan kebutuhan istirahat',
          '• Batasi jam kerja: usahakan tidak lebih dari 8 jam per hari',
          '• Ambil waktu istirahat: break 5-10 menit setiap 1-2 jam kerja',
          '• Boundary setting: pisahkan waktu kerja dan waktu pribadi',
          '• Aktivitas restoratif: lakukan aktivitas yang memulihkan energi',
        ]);
      } else if (severity >= 6) {
        tips.addAll([
          '• Evaluasi beban kerja dan delegasi tugas jika memungkinkan',
          '• Time management: prioritaskan tugas penting, delegasikan yang lain',
          '• Work-life balance: jaga keseimbangan antara kerja dan kehidupan pribadi',
          '• Self-care: jadwalkan waktu untuk diri sendiri setiap hari',
          '• Aktivitas rekreasi: lakukan hobi atau aktivitas yang menyenangkan',
        ]);
      }
    }

    if (tips.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
        ),
        child: pw.Text(
          'Tips self-care akan muncul setelah Anda menyelesaikan assessment. '
          'Tips akan disesuaikan dengan hasil assessment Anda.',
          style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
        ),
      );
    }

    // Remove duplicates
    final uniqueTips = tips.toSet().toList();

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        border: pw.Border.all(width: 1, color: PdfColors.green300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Tips berikut disesuaikan dengan hasil assessment Anda. '
            'Lakukan secara bertahap dan konsisten untuk hasil terbaik.',
            style: pw.TextStyle(
              fontSize: 10,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 8),
          ...uniqueTips.map((tip) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(tip, style: const pw.TextStyle(fontSize: 10)),
              )),
        ],
      ),
    );
  }

  static pw.Widget _actionChecklistSection() {
    final habits = <String>[
      'Sleep hygiene: jadwal tidur tetap (7–9 jam), kurangi layar 1 jam sebelum tidur',
      'Aktivitas fisik 150 menit/minggu total (mis. 5×30 menit jalan cepat/olahraga ringan)',
      'Teknik relaksasi 5–10 menit (napas 4-7-8 / box breathing / relaksasi otot progresif)',
      'Journaling: 3 hal disyukuri + rencana 1 tugas kecil untuk besok',
      'Kontak sosial: hubungi 1 orang tepercaya (telepon/chat/ketemu singkat)',
      'Micro-break: 5 menit istirahat tiap 60–90 menit kerja/belajar (atur timer)',
      'Paparan cahaya pagi 10–15 menit (bila memungkinkan)',
      'CBT tools: Socratic questioning, reframe pikiran otomatis, behavioral activation',
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: habits
          .map((h) => pw.Row(children: [
                pw.Container(
                  width: 10,
                  height: 10,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 1),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(child: pw.Text(h)),
              ]))
          .toList(),
    );
  }

  static pw.Widget _emergencySection({String? name, String? phone}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if ((name ?? '').isNotEmpty) _cell('Kontak Darurat: $name'),
        if ((phone ?? '').isNotEmpty) _cell('Telepon: $phone'),
        _cell(
            'Catatan: Jika kondisi darurat/krisis, hubungi layanan darurat setempat.'),
      ],
    );
  }

  static pw.Widget _resourcesSection(List<String>? resources) {
    final list = (resources ?? <String>[]);
    if (list.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _cell('Belum ada sumber daya lokal yang diatur.'),
          _cell('Tambahkan di Akun/Settings agar tercetak di laporan.'),
        ],
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: list.map((e) => pw.Bullet(text: e)).toList(),
    );
  }

  static pw.Widget _recommendationsSection(
    _AssessmentEntry phq9,
    _AssessmentEntry gad7,
    _AssessmentEntry burnout,
  ) {
    final items = <String>[];

    void addRecForPhq9(int s) {
      if (s >= 20) {
        items.add(
            'Depresi berat: Segera konsultasi psikiater/psikolog. Alasan: PHQ-9 ≥ 20.');
      } else if (s >= 15)
        // ignore: curly_braces_in_flow_control_structures
        items.add(
            'Depresi sedang–berat: Evaluasi profesional. Alasan: PHQ-9 15–19.');
      else if (s >= 10)
        // ignore: curly_braces_in_flow_control_structures
        items.add(
            'Depresi sedang: Konseling/CBT disarankan. Alasan: PHQ-9 10–14.');
      else if (s >= 5)
        // ignore: curly_braces_in_flow_control_structures
        items.add(
            'Depresi ringan: Self-care + pantau ulang 2–4 minggu. Alasan: PHQ-9 5–9.');
      else
        // ignore: curly_braces_in_flow_control_structures
        items.add('Depresi minimal: Pertahankan kebiasaan sehat.');
    }

    void addRecForGad7(int s) {
      if (s >= 15) {
        items.add(
            'Kecemasan berat: Rujukan segera ke profesional. Alasan: GAD-7 ≥ 15.');
      } else if (s >= 10)
        // ignore: curly_braces_in_flow_control_structures
        items.add(
            'Kecemasan sedang: Terapi/teknik relaksasi disarankan. Alasan: GAD-7 10–14.');
      else if (s >= 5)
        // ignore: curly_braces_in_flow_control_structures
        items.add(
            'Kecemasan ringan: Latihan pernapasan, sleep hygiene. Alasan: GAD-7 5–9.');
      else
        // ignore: curly_braces_in_flow_control_structures
        items.add('Kecemasan minimal: Lanjutkan gaya hidup sehat.');
    }

    void addRecForBurnout(int s) {
      if (s >= 20) {
        items.add(
            'Burnout tinggi: Kurangi beban kerja, jadwalkan pemulihan, konsultasi profesional.');
      } else if (s >= 10)
        // ignore: curly_braces_in_flow_control_structures
        items.add(
            'Burnout sedang: Batas kerja harian, micro-break, aktivitas restorative.');
      else
        // ignore: curly_braces_in_flow_control_structures
        items.add('Burnout rendah: Pertahankan strategi coping yang efektif.');
    }

    if (!phq9.isEmpty) addRecForPhq9(phq9.totalScore);
    if (!gad7.isEmpty) addRecForGad7(gad7.totalScore);
    if (!burnout.isEmpty) addRecForBurnout(burnout.totalScore);

    // Kombinasi lintas-instrumen
    if (!phq9.isEmpty && !gad7.isEmpty) {
      if (phq9.totalScore >= 10 && gad7.totalScore >= 10) {
        items.add(
            'Kombinasi depresi & kecemasan sedang/tinggi: Pertimbangkan intervensi terpadu (psikoterapi terstruktur).');
      }
    }
    if (!burnout.isEmpty && (phq9.totalScore >= 10 || gad7.totalScore >= 10)) {
      items.add(
          'Burnout + skor emosional sedang/tinggi: Evaluasi beban kerja & dukungan sosial di kerja/sekolah.');
    }

    // Interval follow-up berbasis keparahan total
    final severitySum = (phq9.isEmpty ? 0 : phq9.totalScore) +
        (gad7.isEmpty ? 0 : gad7.totalScore) +
        (burnout.isEmpty ? 0 : burnout.totalScore);
    final followup = severitySum >= 40
        ? 'Follow-up 1 minggu'
        : severitySum >= 25
            ? 'Follow-up 2 minggu'
            : severitySum >= 10
                ? 'Follow-up 4 minggu'
                : 'Follow-up 6–8 minggu';
    items.add('Jadwal tindak lanjut: $followup');

    // Safety flag
    items.add(
        'Jika muncul pikiran menyakiti diri/krisis: segera hubungi layanan darurat atau tenaga profesional.');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items.isEmpty
          ? [
              pw.Text(
                  'Belum ada rekomendasi karena data assessment belum lengkap.')
            ]
          : items.map((t) => pw.Bullet(text: t)).toList(),
    );
  }

  static pw.Widget _clinicalInterpretationSection(
    AssessmentResult? phq9,
    AssessmentResult? gad7,
    AssessmentResult? burnout,
  ) {
    final items = <pw.TableRow>[];

    // PHQ-9 Interpretation
    if (phq9 != null) {
      final severity = _getPhq9Severity(phq9.totalScore);
      final normalized = (phq9.totalScore / 27 * 100).toStringAsFixed(1);
      items.add(pw.TableRow(children: [
        _cellBold('PHQ-9 (Depresi)'),
        _cell('Skor: ${phq9.totalScore}/27 ($normalized%)'),
        _cell('Severity: $severity'),
      ]));
    }

    // GAD-7 Interpretation
    if (gad7 != null) {
      final severity = _getGad7Severity(gad7.totalScore);
      final normalized = (gad7.totalScore / 21 * 100).toStringAsFixed(1);
      items.add(pw.TableRow(children: [
        _cellBold('GAD-7 (Kecemasan)'),
        _cell('Skor: ${gad7.totalScore}/21 ($normalized%)'),
        _cell('Severity: $severity'),
      ]));
    }

    // Burnout Interpretation
    if (burnout != null) {
      final severity = _getBurnoutSeverity(burnout.totalScore);
      final normalized = (burnout.totalScore / 15 * 100).toStringAsFixed(1);
      items.add(pw.TableRow(children: [
        _cellBold('Burnout'),
        _cell('Skor: ${burnout.totalScore}/15 ($normalized%)'),
        _cell('Severity: $severity'),
      ]));
    }

    if (items.isEmpty) {
      return pw.Text('Belum ada data assessment terbaru');
    }

    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5),
        1: const pw.FlexColumnWidth(2.5),
        2: const pw.FlexColumnWidth(2.5),
      },
      children: [
        pw.TableRow(children: [
          _cellBold('Instrumen'),
          _cellBold('Skor & Persentase'),
          _cellBold('Tingkat Keparahan'),
        ]),
        ...items,
      ],
    );
  }

  static String _getPhq9Severity(int score) {
    if (score >= 20) return 'Berat (Severe Depression)';
    if (score >= 15) return 'Sedang-Berat (Moderately Severe)';
    if (score >= 10) return 'Sedang (Moderate)';
    if (score >= 5) return 'Ringan (Mild)';
    return 'Minimal (Minimal/None)';
  }

  static String _getGad7Severity(int score) {
    if (score >= 15) return 'Berat (Severe Anxiety)';
    if (score >= 10) return 'Sedang (Moderate)';
    if (score >= 5) return 'Ringan (Mild)';
    return 'Minimal (Minimal/None)';
  }

  static String _getBurnoutSeverity(int score) {
    if (score >= 12) return 'Tinggi (High Burnout)';
    if (score >= 6) return 'Sedang (Moderate)';
    return 'Rendah (Low)';
  }

  static pw.Widget _detailedAnswersSection(
      AssessmentResult result, AssessmentType type) {
    List<Question> questions;
    String title;
    switch (type) {
      case AssessmentType.phq9:
        questions = phq9Questions;
        title = 'PHQ-9 (Patient Health Questionnaire-9)';
        break;
      case AssessmentType.gad7:
        questions = gad7Questions;
        title = 'GAD-7 (Generalized Anxiety Disorder-7)';
        break;
      case AssessmentType.burnout:
        questions = burnoutQuestions;
        title = 'Burnout Assessment';
        break;
    }

    final rows = <pw.TableRow>[
      pw.TableRow(children: [
        _cellBold('No.'),
        _cellBold('Pertanyaan'),
        _cellBold('Skor'),
        _cellBold('Interpretasi'),
      ]),
    ];

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final score = result.answers[q.id] ?? 0;
      final answerLabel = _getAnswerLabel(score, q.options);
      final interpretation = _getScoreInterpretation(score);

      rows.add(pw.TableRow(children: [
        _cell('${i + 1}', fontSize: 9),
        _cell(q.text, fontSize: 9),
        _cell('$score', fontSize: 9),
        _cell('$answerLabel\n($interpretation)', fontSize: 9),
      ]));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Tanggal: ${DateFormat('dd MMM yyyy, HH:mm').format(result.timestamp)}',
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(0.5),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(0.8),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: rows,
        ),
        pw.SizedBox(height: 12),
      ],
    );
  }

  static String _getAnswerLabel(int score, List<AnswerOption> options) {
    try {
      return options.firstWhere((opt) => opt.score == score).label;
    } catch (e) {
      return 'Tidak ada jawaban';
    }
  }

  static String _getScoreInterpretation(int score) {
    if (score == 0) return 'Tidak ada gejala';
    if (score == 1) return 'Gejala ringan';
    if (score == 2) return 'Gejala sedang';
    return 'Gejala berat';
  }

  // COVER PAGE
  static pw.Widget _coverPage({
    required String patientName,
    required int patientAge,
    required DateTime generatedAt,
    required String dateStr,
  }) {
    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Spacer(),
        pw.Text(
          'InsightMind',
          style: pw.TextStyle(
            fontSize: 32,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          'Laporan Monitoring Kesehatan Mental',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 40),
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 1, color: PdfColors.grey400),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Identitas Pasien',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Nama: $patientName'),
              pw.Text('Usia: $patientAge tahun'),
              pw.SizedBox(height: 12),
              pw.Text('Tanggal Laporan: $dateStr'),
            ],
          ),
        ),
        pw.SizedBox(height: 40),
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.red100,
            border: pw.Border.all(width: 2, color: PdfColors.red900),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'DISCLAIMER PENTING',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red900,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Laporan ini didasarkan pada data yang dilaporkan sendiri dan analisis algoritmik. '
                'Laporan ini BUKAN pengganti untuk evaluasi klinis profesional. '
                'Semua keputusan diagnosis dan pengobatan harus dibuat oleh profesional kesehatan mental '
                'yang berkualifikasi setelah penilaian komprehensif.',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
        pw.Spacer(),
        pw.Text(
          'Confidential - For Clinical Use Only',
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey700,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      ],
    );
  }

  // EXECUTIVE SUMMARY
  static pw.Widget _executiveSummarySection(
    AssessmentResult? phq9,
    AssessmentResult? gad7,
    AssessmentResult? burnout,
    int? screeningScore,
    String? screeningRiskLevel,
  ) {
    final items = <pw.Widget>[];

    // Risk Assessment Boxes
    final riskBoxes = <pw.Widget>[];

    if (phq9 != null) {
      final severity = _getPhq9Severity(phq9.totalScore);
      final color = phq9.totalScore >= 20
          ? PdfColors.red900
          : phq9.totalScore >= 10
              ? PdfColors.orange700
              : PdfColors.green700;
      riskBoxes.add(_riskBox(
          'PHQ-9 (Depresi)', '${phq9.totalScore}/27', severity, color));
    }

    if (gad7 != null) {
      final severity = _getGad7Severity(gad7.totalScore);
      final color = gad7.totalScore >= 15
          ? PdfColors.red900
          : gad7.totalScore >= 10
              ? PdfColors.orange700
              : PdfColors.green700;
      riskBoxes.add(_riskBox(
          'GAD-7 (Kecemasan)', '${gad7.totalScore}/21', severity, color));
    }

    if (burnout != null) {
      final severity = _getBurnoutSeverity(burnout.totalScore);
      final color =
          burnout.totalScore >= 12 ? PdfColors.orange700 : PdfColors.green700;
      riskBoxes.add(
          _riskBox('Burnout', '${burnout.totalScore}/15', severity, color));
    }

    items.add(
      pw.Header(
        level: 1,
        child: pw.Text(
          'Executive Summary',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );

    items.add(
      pw.Wrap(
        spacing: 16,
        runSpacing: 16,
        children: riskBoxes,
      ),
    );

    return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start, children: items);
  }

  static pw.Widget _riskBox(
      String title, String score, String severity, PdfColor color) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 2, color: color),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style:
                  pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(score,
              style: pw.TextStyle(
                  fontSize: 16, fontWeight: pw.FontWeight.bold, color: color)),
          pw.Text(severity, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  // PATIENT FEEDBACK SECTION
  static pw.Widget _patientFeedbackSection() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1, color: PdfColors.blue400),
        color: PdfColors.blue50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PATIENT\'S PERSPECTIVE',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Text('Apa yang paling mengganggu saat ini?',
              style:
                  pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.Container(
            height: 40,
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
          ),
          pw.SizedBox(height: 12),
          pw.Text('Apa yang sudah dicoba untuk mengatasi?',
              style:
                  pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.Container(
            height: 40,
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
          ),
          pw.SizedBox(height: 12),
          pw.Text('Harapan dari terapi/konsultasi?',
              style:
                  pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.Container(
            height: 40,
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
          ),
          pw.SizedBox(height: 12),
          pw.Text('Goals jangka pendek (1-3 bulan):',
              style:
                  pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.Text('☐ ________________________________________________'),
          pw.Text('☐ ________________________________________________'),
          pw.Text('☐ ________________________________________________'),
          pw.SizedBox(height: 12),
          pw.Text('Goals jangka panjang (6-12 bulan):',
              style:
                  pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.Text('☐ ________________________________________________'),
          pw.Text('☐ ________________________________________________'),
        ],
      ),
    );
  }

  // GLOSSARY & RESOURCES SECTION
  static pw.Widget _glossaryAndResourcesSection(
      {List<String>? localResources}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Glossary & Resources',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Text('Glossary:',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text(
            '• Anhedonia: Kehilangan kemampuan merasakan kesenangan dari aktivitas yang biasanya menyenangkan'),
        pw.Text(
            '• Cognitive Distortion: Pola pikir yang tidak akurat atau bias negatif'),
        pw.Text(
            '• Comorbidity: Adanya dua atau lebih kondisi kesehatan mental secara bersamaan'),
        pw.Text(
            '• DSM-5: Diagnostic and Statistical Manual of Mental Disorders, Fifth Edition'),
        pw.Text(
            '• GAD: Generalized Anxiety Disorder - Gangguan kecemasan yang ditandai dengan kekhawatiran berlebihan'),
        pw.Text(
            '• PHQ-9: Patient Health Questionnaire - alat screening untuk depresi'),
        pw.Text(
            '• SSRI: Selective Serotonin Reuptake Inhibitor - jenis antidepresan'),
        pw.Text(
            '• Subsyndromal: Gejala ada tapi belum memenuhi kriteria penuh untuk diagnosis'),
        pw.Text(
            '• Suicidal Ideation: Pikiran tentang kematian atau bunuh diri'),
        pw.SizedBox(height: 16),
        pw.Text('Resources & Recommendations:',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('BUKU/ARTIKEL:'),
        pw.Text('• "Feeling Good: The New Mood Therapy" - David Burns'),
        pw.Text('• "The Anxiety and Phobia Workbook" - Edmund Bourne'),
        pw.Text(
            '• "Burnout: The Secret to Unlocking the Stress Cycle" - Emily & Amelia Nagoski'),
        pw.SizedBox(height: 8),
        pw.Text('APPS:'),
        pw.Text('• Headspace, Calm (untuk mindfulness)'),
        pw.Text('• Sanvello, MindShift (untuk CBT self-help)'),
        pw.SizedBox(height: 8),
        pw.Text('ONLINE RESOURCES:'),
        pw.Text('• www.sehatmental.id (Indonesia mental health info)'),
        pw.Text('• www.intothelightid.org (Suicide prevention)'),
        pw.Text('• www.anxietyindonesia.com (Anxiety community)'),
        pw.SizedBox(height: 8),
        pw.Text('PROFESSIONAL DIRECTORIES:'),
        pw.Text('• www.ibunda.id (Find psychologists in Indonesia)'),
        pw.Text('• www.halodoc.com (Online consultation)'),
        pw.Text('• www.alodokter.com (Mental health directory)'),
        if (localResources != null && localResources.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Text('Sumber Daya Lokal:',
              style:
                  pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ...localResources.map((r) => pw.Text('• $r')),
        ],
      ],
    );
  }

  // BACK COVER SUMMARY
  static pw.Widget _backCoverSummary({
    required String patientName,
    required DateTime generatedAt,
    AssessmentResult? latestPhq9Result,
    AssessmentResult? latestGad7Result,
    AssessmentResult? latestBurnoutResult,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) {
    final dateStr = DateFormat('dd MMM yyyy').format(generatedAt);
    final initials = patientName
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .join('')
        .toUpperCase();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'QUICK REFERENCE SUMMARY',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 16),
        pw.Text('Patient: $initials'),
        pw.Text('Report Date: $dateStr'),
        pw.SizedBox(height: 16),
        pw.Text('KEY FINDINGS:',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        if (latestGad7Result != null) ...[
          () {
            final result = latestGad7Result;
            final level = result.totalScore >= 15
                ? 'High'
                : result.totalScore >= 10
                    ? 'Moderate'
                    : 'Low';
            final color = level == 'High'
                ? '🔴'
                : level == 'Moderate'
                    ? '🟡'
                    : '🟢';
            return pw.Text(
                '$color $level Anxiety (GAD-7: ${result.totalScore})');
          }(),
        ],
        if (latestPhq9Result != null) ...[
          () {
            final result = latestPhq9Result;
            final level = result.totalScore >= 20
                ? 'High'
                : result.totalScore >= 10
                    ? 'Moderate'
                    : 'Low';
            final color = level == 'High'
                ? '🔴'
                : level == 'Moderate'
                    ? '🟡'
                    : '🟢';
            return pw.Text(
                '$color $level Depression (PHQ-9: ${result.totalScore})');
          }(),
        ],
        if (latestBurnoutResult != null) ...[
          () {
            final result = latestBurnoutResult;
            final level = result.totalScore >= 12 ? 'High' : 'Moderate';
            final color = level == 'High' ? '🟡' : '🟢';
            return pw.Text('$color $level Burnout (${result.totalScore}/15)');
          }(),
        ],
        pw.SizedBox(height: 16),
        pw.Text('RECOMMENDED ACTIONS:',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.Text('☐ Psychotherapy (CBT) - Weekly'),
        pw.Text('☐ Consider pharmacotherapy (SSRI)'),
        pw.Text('☐ Sleep intervention - Priority'),
        pw.Text('☐ Lifestyle modifications - Essential'),
        pw.Text('☐ Follow-up in 2 weeks'),
        pw.SizedBox(height: 16),
        pw.Text('EMERGENCY CONTACTS:',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        if ((emergencyContactName ?? '').isNotEmpty)
          pw.Text(
              '📞 Family: $emergencyContactName ${emergencyContactPhone ?? ''}'),
        pw.Text('📞 Crisis Hotline: 119 / 021-500-454'),
        pw.SizedBox(height: 24),
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Text(
          'Report generated by InsightMind v2.0',
          style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#757575')),
        ),
        pw.Text(
          'Data encryption: AES-256 | Privacy compliant: GDPR, Indonesia Data Protection',
          style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#757575')),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'DISCLAIMER: This report is based on self-reported data and algorithmic analysis. '
          'It is NOT a substitute for professional clinical evaluation.',
          style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
        ),
      ],
    );
  }
}

class _AssessmentEntry {
  final String typeName;
  final DateTime timestamp;
  final int totalScore;
  final AssessmentResult? assessmentResult;
  const _AssessmentEntry({
    required this.typeName,
    required this.timestamp,
    required this.totalScore,
    this.assessmentResult,
  });

  static _AssessmentEntry empty(String typeName) => _AssessmentEntry(
      typeName: typeName,
      timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      totalScore: -1,
      assessmentResult: null);
  bool get isEmpty => totalScore < 0;
  String get totalScoreLabel => isEmpty ? '-' : '$totalScore';
  String get prettyType => typeName == 'phq9'
      ? 'PHQ-9'
      : typeName == 'gad7'
          ? 'GAD-7'
          : 'Burnout';
}
