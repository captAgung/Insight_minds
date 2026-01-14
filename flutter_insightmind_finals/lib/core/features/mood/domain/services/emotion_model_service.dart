class EmotionInferenceResult {
  final String label; // e.g., happy, neutral, sad
  final double confidence; // 0.0 - 1.0
  const EmotionInferenceResult({required this.label, required this.confidence});
}

abstract class EmotionModelService {
  Future<EmotionInferenceResult> inferFromFacePreview();
}


