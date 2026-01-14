// WEEK7: Dashboard Page dengan visualisasi data dan analytics
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/history_providers.dart';
import '../../data/local/screening_record.dart';
import 'history_page.dart';
import 'screening_page.dart';
import '../../../mood/presentation/pages/mood_scan_page.dart';

/// Dashboard Page untuk menampilkan ringkasan statistik dan trend data screening
///
/// Menggunakan ConsumerWidget dan Riverpod untuk manajemen state.
/// Memantau historyListProvider untuk mendapatkan data riwayat screening.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Lihat Histori',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              );
            },
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.refresh(historyListProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (items) {
          // Empty State: Jika history kosong, tampilkan UI edukatif
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assessment_outlined,
                        size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 24),
                    const Text(
                      'Belum Ada Data Screening',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Lakukan screening terlebih dahulu untuk melihat dashboard dan analisis data Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ScreeningPage()),
                        );
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Mulai Screening'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Pengolahan Data (Analytics): Hitung statistik berdasarkan risk level
          final tinggiCount =
              items.where((e) => e.riskLevel.toLowerCase() == 'tinggi').length;
          final sedangCount =
              items.where((e) => e.riskLevel.toLowerCase() == 'sedang').length;
          final rendahCount =
              items.where((e) => e.riskLevel.toLowerCase() == 'rendah').length;

          // Insight Generation: Generate kesimpulan otomatis berdasarkan kategori dominan
          String insightText;
          Color insightColor;
          if (tinggiCount >= sedangCount && tinggiCount >= rendahCount) {
            insightText =
                'Berdasarkan data Anda, mayoritas screening menunjukkan risiko tinggi. Disarankan untuk berkonsultasi dengan profesional kesehatan mental.';
            insightColor = Colors.red;
          } else if (sedangCount >= tinggiCount && sedangCount >= rendahCount) {
            insightText =
                'Data menunjukkan risiko sedang yang dominan. Pertimbangkan untuk mengelola stres dan menjaga pola hidup sehat.';
            insightColor = Colors.orange;
          } else {
            insightText =
                'Kebanyakan screening menunjukkan risiko rendah. Terus pertahankan kesehatan mental Anda dengan pola hidup sehat.';
            insightColor = Colors.green;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary Card: Menampilkan angka ringkasan statistik risiko
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ringkasan Statistik',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatisticItem(
                              label: 'Tinggi',
                              count: tinggiCount,
                              color: Colors.red,
                              icon: Icons.warning,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatisticItem(
                              label: 'Sedang',
                              count: sedangCount,
                              color: Colors.orange,
                              icon: Icons.info,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatisticItem(
                              label: 'Rendah',
                              count: rendahCount,
                              color: Colors.green,
                              icon: Icons.check_circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Screening:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${items.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Biometric Card: Akses cepat ke fitur kamera untuk mood scan
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MoodScanPage()),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.purple,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Scan Mood dengan Kamera',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Deteksi mood Anda menggunakan AI dari wajah',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Trend Card: Wadah untuk grafik sparkline yang menunjukkan perkembangan skor dari waktu ke waktu
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Trend Skor Screening',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: _SparklineChart(
                          records: items,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Insight Panel: Menampilkan kesimpulan otomatis dan tombol aksi (Call to Action)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                color: insightColor.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: insightColor),
                          const SizedBox(width: 8),
                          Text(
                            'Insight',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: insightColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        insightText,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const HistoryPage()),
                                );
                              },
                              icon: const Icon(Icons.history),
                              label: const Text('Lihat Histori'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const ScreeningPage()),
                                );
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Screening Baru'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Widget untuk menampilkan item statistik
class _StatisticItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatisticItem({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Sparkline Chart menggunakan CustomPainter
///
/// Karena paket fl_chart dinonaktifkan sementara, kode ini mengimplementasikan
/// Line Chart (Sparkline) sendiri dengan:
/// - CustomPainter: Menggunakan Canvas untuk menggambar jalur (path) grafik
///   berdasarkan skor riwayat
/// - Animasi: Menggunakan AnimationController sehingga grafik tampak "mengalir"
///   saat halaman dibuka
/// - Interaktivitas: Menggunakan MouseRegion dan GestureDetector untuk mendeteksi
///   posisi sentuhan, sehingga muncul tooltip (informasi skor) saat titik tertentu didekati
class _SparklineChart extends StatefulWidget {
  final List<ScreeningRecord> records;

  const _SparklineChart({required this.records});

  @override
  State<_SparklineChart> createState() => _SparklineChartState();
}

class _SparklineChartState extends State<_SparklineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    // Animasi: AnimationController untuk membuat grafik tampak "mengalir"
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.records.isEmpty) {
      return const Center(
        child: Text('Tidak ada data untuk ditampilkan'),
      );
    }

    // Siapkan data untuk grafik (ambil 10 terakhir untuk readability)
    final displayRecords = widget.records.take(10).toList().reversed.toList();
    final scores = displayRecords.map((r) => r.score.toDouble()).toList();
    final dates = displayRecords.map((r) => r.timestamp).toList();

    if (scores.isEmpty) {
      return const Center(child: Text('Tidak ada data'));
    }

    final minScore = scores.reduce((a, b) => a < b ? a : b);
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final scoreRange = (maxScore - minScore).abs();
    final normalizedRange = scoreRange > 0 ? scoreRange : 1.0;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return GestureDetector(
          // Interaktivitas: GestureDetector untuk mendeteksi posisi sentuhan
          onTapDown: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localPosition = box.globalToLocal(details.globalPosition);
            final width = box.size.width;
            final index = ((localPosition.dx / width) * scores.length).floor();
            if (index >= 0 && index < scores.length) {
              setState(() {
                _hoveredIndex = index;
              });
            }
          },
          onTapUp: (_) {
            setState(() {
              _hoveredIndex = null;
            });
          },
          child: CustomPaint(
            painter: _SparklinePainter(
              scores: scores,
              dates: dates,
              minScore: minScore,
              normalizedRange: normalizedRange,
              animationValue: _animation.value,
              hoveredIndex: _hoveredIndex,
            ),
            child: Container(),
          ),
        );
      },
    );
  }
}

/// CustomPainter untuk menggambar sparkline chart
class _SparklinePainter extends CustomPainter {
  final List<double> scores;
  final List<DateTime> dates;
  final double minScore;
  final double normalizedRange;
  final double animationValue;
  final int? hoveredIndex;

  _SparklinePainter({
    required this.scores,
    required this.dates,
    required this.minScore,
    required this.normalizedRange,
    required this.animationValue,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    final paint = Paint()
      ..color = Colors.indigo
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.indigo.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final pointPaint = Paint()
      ..color = Colors.indigo
      ..style = PaintingStyle.fill;

    final hoverPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter();

    // Hitung posisi titik-titik
    final points = <Offset>[];
    final spacing = size.width / (scores.length - 1).clamp(1, double.infinity);

    for (int i = 0; i < scores.length; i++) {
      final normalizedScore = (scores[i] - minScore) / normalizedRange;
      final y = size.height -
          (normalizedScore * size.height * 0.8) -
          (size.height * 0.1);
      final x = i * spacing;
      points.add(Offset(x, y));
    }

    // Gambar area fill (hanya untuk bagian yang ter-animasi)
    if (points.length > 1 && animationValue > 0) {
      final animatedPoints = <Offset>[];
      final animatedCount = (points.length * animationValue).ceil();

      for (int i = 0; i < animatedCount && i < points.length; i++) {
        animatedPoints.add(points[i]);
      }

      if (animatedPoints.length > 1) {
        final path = Path()
          ..moveTo(animatedPoints[0].dx, size.height)
          ..lineTo(animatedPoints[0].dx, animatedPoints[0].dy);

        for (int i = 1; i < animatedPoints.length; i++) {
          path.lineTo(animatedPoints[i].dx, animatedPoints[i].dy);
        }

        path.lineTo(animatedPoints.last.dx, size.height);
        path.close();

        canvas.drawPath(path, fillPaint);
      }
    }

    // Gambar garis (hanya untuk bagian yang ter-animasi)
    if (points.length > 1 && animationValue > 0) {
      final animatedCount = (points.length * animationValue).ceil();
      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);

      for (int i = 1; i < animatedCount && i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      canvas.drawPath(path, paint);
    }

    // Gambar titik-titik dan label
    final dateFormat = DateFormat('MM/dd', 'id');
    for (int i = 0; i < points.length; i++) {
      if (i <= (points.length * animationValue).ceil()) {
        final isHovered = hoveredIndex == i;
        final currentPaint = isHovered ? hoverPaint : pointPaint;

        // Gambar titik
        canvas.drawCircle(points[i], isHovered ? 6 : 4, currentPaint);

        // Gambar label tanggal di sumbu X (hanya beberapa untuk readability)
        if (i % ((scores.length / 5).ceil()).clamp(1, scores.length) == 0 ||
            isHovered) {
          textPainter.text = TextSpan(
            text: dateFormat.format(dates[i]),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(
              points[i].dx - textPainter.width / 2,
              size.height - textPainter.height - 4,
            ),
          );
        }

        // Tooltip saat hover
        if (isHovered) {
          final tooltipText =
              'Skor: ${scores[i].toInt()}\n${dateFormat.format(dates[i])}';
          textPainter.text = TextSpan(
            text: tooltipText,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          );
          textPainter.layout();

          final tooltipRect = Rect.fromLTWH(
            points[i].dx - textPainter.width / 2 - 8,
            points[i].dy - textPainter.height - 20,
            textPainter.width + 16,
            textPainter.height + 12,
          );

          // Background tooltip
          final tooltipPaint = Paint()
            ..color = Colors.black87
            ..style = PaintingStyle.fill;
          canvas.drawRRect(
            RRect.fromRectAndRadius(tooltipRect, const Radius.circular(8)),
            tooltipPaint,
          );

          // Text tooltip
          textPainter.paint(
            canvas,
            Offset(
              points[i].dx - textPainter.width / 2,
              points[i].dy - textPainter.height - 14,
            ),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.scores != scores;
  }
}
