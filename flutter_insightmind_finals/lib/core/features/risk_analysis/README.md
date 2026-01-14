# Sistem Prediksi Risiko Kesehatan Mental

Sistem ini menyediakan prediksi risiko kesehatan mental berdasarkan assessment (PHQ-9, GAD-7, Burnout) dan behavioral data (mood tracking, sleep, activity, social interaction, productivity).

## Fitur Utama

### 1. Assessment System
- **PHQ-9** (9 pertanyaan untuk depresi) - Skala 0-3 per pertanyaan
- **GAD-7** (7 pertanyaan untuk anxiety) - Skala 0-3 per pertanyaan  
- **Burnout Assessment** (5 pertanyaan untuk burnout) - Skala 0-3 per pertanyaan

### 2. Daily Mood Tracking (Enhanced)
- Rating 1-10 (bukan hanya 1-5)
- Emosi: Cemas, Lelah, Sedih, Bahagia, Marah, Netral
- Behavioral Data:
  - Jam tidur (sleep hours)
  - Aktivitas fisik (physical activity minutes)
  - Interaksi sosial (social interaction level 0-10)
  - Produktivitas (productivity level 0-10)

### 3. AI Prediction Engine
Menghitung risk score untuk:
- **Depression Risk** (0-100%)
  - PHQ-9: 40%
  - Mood trend: 25%
  - Sleep: 20%
  - Social activity: 15%

- **Anxiety Risk** (0-100%)
  - GAD-7: 40%
  - Physical symptoms (dari emotions): 30%
  - Mood volatility: 30%

- **Burnout Risk** (0-100%)
  - Burnout assessment: 50%
  - Energy levels (mood + activity): 30%
  - Cynicism indicators (dari emotions): 20%

**Risk Levels:**
- Low: 0-40%
- Moderate: 40-70%
- High: 70-100%

**Confidence Score** (0-100%):
- Assessment completeness: 40%
- Mood entries quantity: 30%
- Data consistency: 30%

### 4. Pattern Detection
Mendeteksi pola berbahaya:
- Mood drop >30% dalam 3 hari
- Risk score naik ke High
- Mood rendah berturut-turut (5+ hari)
- Gangguan pola tidur (5+ hari)
- Penurunan interaksi sosial (>40%)

### 5. Alert System
Alert dengan severity (low, medium, high, critical) dan rekomendasi actionable untuk:
- Penurunan mood signifikan
- Tingkat risiko tinggi
- Pola berbahaya terdeteksi
- Gangguan tidur
- Penarikan sosial

## Struktur File

```
lib/core/features/risk_analysis/
├── domain/
│   ├── entities/
│   │   ├── risk_score.dart          # RiskScore entity dengan risk levels
│   │   ├── assessment_result.dart   # AssessmentResult entity
│   │   └── pattern_alert.dart       # PatternAlert entity
│   └── usecase/
│       ├── calculate_risk_score.dart # Algoritma perhitungan risk
│       └── detect_patterns.dart      # Pattern detection & alerts
└── README.md
```

## Cara Menggunakan

### 1. Hitung Risk Score

```dart
import 'package:your_app/core/features/risk_analysis/domain/usecase/calculate_risk_score.dart';
import 'package:your_app/core/features/risk_analysis/domain/entities/assessment_result.dart';
import 'package:your_app/core/features/mood/data/local/mood_entry.dart';

final calculator = CalculateRiskScore();
final riskScore = calculator.execute(
  assessments: assessmentResults, // List<AssessmentResult>
  moodEntries: moodEntries, // List<MoodEntry> - last 30 days ideally
);

print('Depression Risk: ${riskScore.depressionRisk}%');
print('Anxiety Risk: ${riskScore.anxietyRisk}%');
print('Burnout Risk: ${riskScore.burnoutRisk}%');
print('Confidence: ${riskScore.confidenceScore}%');
print('Overall Level: ${riskScore.overallLevel}'); // low, moderate, high
```

### 2. Deteksi Patterns & Alerts

```dart
import 'package:your_app/core/features/risk_analysis/domain/usecase/detect_patterns.dart';

final detector = DetectPatterns();
final alerts = detector.execute(
  moodEntries: moodEntries,
  currentRiskScore: currentRiskScore,
  previousRiskScore: previousRiskScore, // 7 days ago
);

for (final alert in alerts) {
  print('${alert.title}: ${alert.message}');
  print('Recommendation: ${alert.recommendation}');
  print('Severity: ${alert.severity}');
}
```

### 3. Enhanced Mood Entry

```dart
import 'package:your_app/core/features/mood/data/local/mood_repository.dart';

await moodRepository.add(
  mood: 3, // backward compatibility
  moodRating: 7, // 1-10
  emotions: ['bahagia', 'netral'],
  sleepHours: 7.5,
  physicalActivityMinutes: 30,
  socialInteractionLevel: 7,
  productivityLevel: 8,
);
```

## Catatan Penting

1. **Backward Compatibility**: MoodEntry masih mendukung field `mood` (1-5) untuk kompatibilitas dengan data lama. Gunakan `effectiveMoodRating` untuk mendapatkan rating 1-10.

2. **Data Completeness**: Confidence score tergantung pada kelengkapan data. Semakin lengkap data assessment dan mood entries, semakin tinggi confidence score.

3. **Disclaimer**: Sistem ini bukan diagnosis medis profesional. Hasil hanya sebagai indikasi awal. Untuk diagnosis yang akurat, konsultasikan dengan profesional kesehatan mental.

4. **Privacy**: Semua data disimpan lokal di perangkat menggunakan Hive. Tidak ada data yang dikirim ke server eksternal.

## Next Steps (TODO)

- [ ] Repository untuk menyimpan AssessmentResult dan RiskScore
- [ ] Riverpod providers untuk state management
- [ ] UI untuk Risk Dashboard
- [ ] UI untuk Enhanced Mood Tracking (dengan behavioral data)
- [ ] UI untuk Assessment Forms (PHQ-9, GAD-7, Burnout)
- [ ] UI untuk Alert Notifications
- [ ] History & Analytics page dengan charts
