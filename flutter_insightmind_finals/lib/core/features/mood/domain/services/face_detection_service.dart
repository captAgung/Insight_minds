class FaceDetectionResult {
  final bool faceFound;
  const FaceDetectionResult({required this.faceFound});
}

abstract class FaceDetectionService {
  Future<FaceDetectionResult> detectFaceFromPreviewFrame();
}


