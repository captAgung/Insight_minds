import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/local_face_detection_service.dart';
import '../../data/local/local_emotion_model_service.dart';
import '../../domain/services/face_detection_service.dart';
import '../../domain/services/emotion_model_service.dart';

final faceDetectionServiceProvider = Provider<FaceDetectionService>((ref) => LocalFaceDetectionService());
final emotionModelServiceProvider = Provider<EmotionModelService>((ref) => LocalEmotionModelService());

final isScanningProvider = StateProvider<bool>((ref) => false);
final lastInferenceProvider = StateProvider<EmotionInferenceResult?>((ref) => null);


