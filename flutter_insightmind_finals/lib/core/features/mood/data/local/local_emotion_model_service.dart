import '../../domain/services/emotion_model_service.dart';

class LocalEmotionModelService implements EmotionModelService {
  @override
  Future<EmotionInferenceResult> inferFromFacePreview() async {
    // Stub inference: return neutral with moderate confidence.
    return const EmotionInferenceResult(label: 'neutral', confidence: 0.62);
  }
}


