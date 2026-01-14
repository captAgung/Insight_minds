import '../../domain/services/face_detection_service.dart';

class LocalFaceDetectionService implements FaceDetectionService {
  @override
  Future<FaceDetectionResult> detectFaceFromPreviewFrame() async {
    // Stub detection: always assume face is found in POC
    return const FaceDetectionResult(faceFound: true);
  }
}


