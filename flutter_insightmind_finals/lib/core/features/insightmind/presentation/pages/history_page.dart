import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/history_providers.dart';
import 'package:intl/intl.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  String _riskDescription(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'rendah':
        return 'Risiko rendah. Terus pertahankan kesehatan mental Anda.';
      case 'sedang':
        return 'Risiko sedang. Cobalah kelola stres, dan pertimbangkan untuk konsultasi jika perlu.';
      case 'tinggi':
        return 'Risiko tinggi. Disarankan mencari bantuan profesional atau berdiskusi dengan konselor.';
      default:
        return '-';
    }
  }

  Color _riskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'rendah':
        return Colors.green;
      case 'sedang':
        return Colors.orange;
      case 'tinggi':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyListProvider);
    final dateFormat = DateFormat('EEEE, d MMM yyyy HH:mm', 'id');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Screening'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await ref.read(historyRepositoryProvider).clearAll();
              final _ = ref.refresh(historyListProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Riwayat dihapus')),
                );
              }
            },
          ),
        ],
      ),
      body: historyAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Belum ada riwayat'));
          }
          // Hitung ringkasan sederhana
          final scores = items.map((e) => e.score).toList();
          final total = scores.length;
          final sum = scores.fold<int>(0, (a, b) => a + b);
          final avg = (sum / total).toStringAsFixed(1);
          final maxScore = scores.reduce((a, b) => a > b ? a : b);
          final minScore = scores.reduce((a, b) => a < b ? a : b);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Kartu ringkasan
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ringkasan',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('Total: $total'),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Rata-rata: $avg'),
                          Text('Min/Max: $minScore/$maxScore'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Daftar riwayat
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final r = items[i];
                  final color = _riskColor(r.riskLevel);
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Detail Riwayat Screening'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Nama: ${r.name}'),
                                Text('Umur: ${r.age}'),
                                const SizedBox(height: 4),
                                Text('Skor: ${r.score}'),
                                Text('Kategori: ${r.riskLevel}',
                                    style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold)),
                                Text('Waktu: ${dateFormat.format(
                                        DateTime.tryParse(r.timestamp.toString()) ??
                                            DateTime.now())}'),
                                const SizedBox(height: 8),
                                Text(_riskDescription(r.riskLevel)),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Tutup'),
                              ),
                            ],
                          ),
                        );
                      },
                      title: Row(
                        children: [
                          Chip(
                            label: Text(r.riskLevel),
                            backgroundColor: color.withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                                color: color, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text('Skor: ${r.score}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500))
                        ],
                      ),
                      subtitle: Text('${r.name} • ${r.age} th • ${dateFormat.format(
                          DateTime.tryParse(r.timestamp.toString()) ??
                              DateTime.now())}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await ref
                              .read(historyRepositoryProvider)
                              .deleteById(r.id);
                          final _ = ref.refresh(historyListProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Riwayat dihapus')),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton.icon(
          icon: const Icon(Icons.delete_sweep),
          label: const Text('Kosongkan Semua Riwayat'),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Konfirmasi'),
                content: const Text('Yakin ingin menghapus semua riwayat?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Batal'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Hapus'),
                  ),
                ],
              ),
            );
            if (ok == true) {
              await ref.read(historyRepositoryProvider).clearAll();
              final _ = ref.refresh(historyListProvider);
            }
          },
        ),
      ),
    );
  }
}
