import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/mood_scan_providers.dart';
import '../providers/mood_providers.dart';

class MoodScanPage extends ConsumerStatefulWidget {
  const MoodScanPage({super.key});

  @override
  ConsumerState<MoodScanPage> createState() => _MoodScanPageState();
}

class _MoodScanPageState extends ConsumerState<MoodScanPage> {
  CameraController? _cameraController;
  Future<void>? _initCameraFuture;

  @override
  void initState() {
    super.initState();
    _initCameraFuture = _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      throw Exception('Izin kamera ditolak');
    }
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _cameraController = CameraController(front, ResolutionPreset.medium, enableAudio: false);
    await _cameraController!.initialize();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final isScanning = ref.watch(isScanningProvider);
    final result = ref.watch(lastInferenceProvider);

    Future<void> doScan() async {
      if (isScanning) return;
      ref.read(isScanningProvider.notifier).state = true;
      try {
        final face = await ref.read(faceDetectionServiceProvider).detectFaceFromPreviewFrame();
        if (!face.faceFound) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Wajah tidak terdeteksi. Pastikan pencahayaan cukup.')),
            );
          }
          return;
        }
        final inference = await ref.read(emotionModelServiceProvider).inferFromFacePreview();
        ref.read(lastInferenceProvider.notifier).state = inference;
      } finally {
        ref.read(isScanningProvider.notifier).state = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pindai Mood (Eksperimental)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Privasi'),
            const SizedBox(height: 4),
            const Text(
              'Fitur ini memproses gambar wajah secara lokal untuk memperkirakan mood. '
              'Kami tidak menyimpan foto. Anda dapat menyimpan hanya label dan tingkat keyakinan.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FutureBuilder(
                  future: _initCameraFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || _cameraController == null || !_cameraController!.value.isInitialized) {
                      return Center(
                        child: Text(
                          'Kamera tidak tersedia: ${snapshot.error ?? ''}'.trim(),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return CameraPreview(_cameraController!);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: isScanning ? null : doScan,
                  icon: const Icon(Icons.center_focus_strong),
                  label: Text(isScanning ? 'Memindai...' : 'Pindai Sekarang'),
                ),
                const SizedBox(width: 12),
                if (result != null)
                  OutlinedButton.icon(
                    onPressed: () async {
                      final moodValue = _mapLabelToMood(result.label);
                      ref.read(isSavingMoodProvider.notifier).state = true;
                      try {
                        await ref.read(moodRepositoryProvider).add(
                              mood: moodValue,
                              note: 'auto:${result.label} (${(result.confidence * 100).toStringAsFixed(0)}%)',
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Tersimpan sebagai mood $moodValue (${result.label}).')),
                          );
                          Navigator.of(context).pop();
                        }
                      } finally {
                        ref.read(isSavingMoodProvider.notifier).state = false;
                      }
                    },
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Simpan Hasil'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (result != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.fact_check),
                  title: Text('Deteksi: ${result.label}'),
                  subtitle: Text('Keyakinan: ${(result.confidence * 100).toStringAsFixed(0)}%'),
                ),
              ),
            const Spacer(),
            const Text(
              'Catatan: Ini fitur eksperimental. Silakan konfirmasi sebelum menyimpan.',
              style: TextStyle(color: Colors.grey),
            )
          ],
        ),
      ),
    );
  }

  int _mapLabelToMood(String label) {
    switch (label) {
      case 'happy':
        return 5;
      case 'neutral':
        return 3;
      case 'sad':
        return 1;
      default:
        return 3;
    }
  }
}


