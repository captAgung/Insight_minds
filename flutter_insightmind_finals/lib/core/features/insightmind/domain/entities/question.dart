enum AssessmentType {
  phq9, // Patient Health Questionnaire-9 (Depression)
  gad7, // Generalized Anxiety Disorder-7
  burnout; // Burnout Assessment

  /// Get the name of the enum value (e.g., 'phq9', 'gad7', 'burnout')
  String get name => toString().split('.').last;
}

class AnswerOption {
  final String label; // contoh: "Tidak Pernah", "Beberapa Hari", ...
  final int score; // 0..3

  const AnswerOption({required this.label, required this.score});
}

class Question {
  final String id;
  final String text;
  final List<AnswerOption> options;
  final AssessmentType? type; // Optional: untuk grouping questions

  const Question({
    required this.id,
    required this.text,
    required this.options,
    this.type,
  });
}

/// PHQ-9 Questions (9 pertanyaan untuk depresi)
const phq9Questions = <Question>[
  Question(
    id: 'phq9_q1',
    type: AssessmentType.phq9,
    text:
        'Dalam 2 minggu terakhir, seberapa sering Anda merasa sedih, putus asa, atau depresi?',
    options: [
      AnswerOption(label: 'Tidak Pernah', score: 0),
      AnswerOption(label: 'Beberapa Hari', score: 1),
      AnswerOption(label: 'Lebih dari Separuh Hari', score: 2),
      AnswerOption(label: 'Hampir Setiap Hari', score: 3),
    ],
  ),
  Question(
    id: 'phq9_q2',
    type: AssessmentType.phq9,
    text:
        'Kesulitan menikmati atau tertarik pada hal-hal yang biasanya menyenangkan?',
    options: [
      AnswerOption(label: 'Tidak Pernah', score: 0),
      AnswerOption(label: 'Beberapa Hari', score: 1),
      AnswerOption(label: 'Lebih dari Separuh Hari', score: 2),
      AnswerOption(label: 'Hampir Setiap Hari', score: 3),
    ],
  ),
  Question(
    id: 'phq9_q3',
    type: AssessmentType.phq9,
    text: 'Kesulitan tidur, tertidur, atau tidur terlalu banyak?',
    options: [
      AnswerOption(label: 'Tidak Pernah', score: 0),
      AnswerOption(label: 'Beberapa Hari', score: 1),
      AnswerOption(label: 'Lebih dari Separuh Hari', score: 2),
      AnswerOption(label: 'Hampir Setiap Hari', score: 3),
    ],
  ),
  Question(
    id: 'phq9_q4',
    type: AssessmentType.phq9,
    text: 'Merasa lelah atau kehilangan energi?',
    options: [
      AnswerOption(label: 'Tidak Pernah', score: 0),
      AnswerOption(label: 'Beberapa Hari', score: 1),
      AnswerOption(label: 'Lebih dari Separuh Hari', score: 2),
      AnswerOption(label: 'Hampir Setiap Hari', score: 3),
    ],
  ),
  Question(
    id: 'phq9_q5',
    type: AssessmentType.phq9,
    text: 'Nafsu makan menurun atau makan berlebihan?',
    options: [
      AnswerOption(label: 'Tidak Pernah', score: 0),
      AnswerOption(label: 'Beberapa Hari', score: 1),
      AnswerOption(label: 'Lebih dari Separuh Hari', score: 2),
      AnswerOption(label: 'Hampir Setiap Hari', score: 3),
    ],
  ),
  Question(
    id: 'phq9_q6',
    type: AssessmentType.phq9,
    text:
        'Merasa buruk tentang diri sendiri, atau merasa bahwa Anda adalah kegagalan atau telah mengecewakan diri sendiri atau keluarga?',
    options: [
      AnswerOption(label: 'Tidak Pernah', score: 0),
      AnswerOption(label: 'Beberapa Hari', score: 1),
      AnswerOption(label: 'Lebih dari Separuh Hari', score: 2),
      AnswerOption(label: 'Hampir Setiap Hari', score: 3),
    ],
  ),
  Question(
    id: 'phq9_q7',
    type: AssessmentType.phq9,
    text:
        'Kesulitan berkonsentrasi pada hal-hal seperti membaca koran atau menonton TV?',
    options: [
      AnswerOption(label: 'Tidak Pernah', score: 0),
      AnswerOption(label: 'Beberapa Hari', score: 1),
      AnswerOption(label: 'Lebih dari Separuh Hari', score: 2),
      AnswerOption(label: 'Hampir Setiap Hari', score: 3),
    ],
  ),
  Question(
    id: 'phq9_q8',
    type: AssessmentType.phq9,
    text:
        'Bergerak atau berbicara sangat lambat sehingga orang lain menyadarinya? Atau sebaliknya, merasa gelisah sehingga lebih sering bergerak dibanding biasanya?',
    options: [
      AnswerOption(label: 'Tidak Pernah', score: 0),
      AnswerOption(label: 'Beberapa Hari', score: 1),
      AnswerOption(label: 'Lebih dari Separuh Hari', score: 2),
      AnswerOption(label: 'Hampir Setiap Hari', score: 3),
    ],
  ),
  Question(
    id: 'phq9_q9',
    type: AssessmentType.phq9,
    text:
        'Memiliki pikiran untuk menyakiti diri sendiri, atau berpikir bahwa akan lebih baik jika Anda mati?',
    options: [
      AnswerOption(label: 'Tidak Pernah', score: 0),
      AnswerOption(label: 'Beberapa Hari', score: 1),
      AnswerOption(label: 'Lebih dari Separuh Hari', score: 2),
      AnswerOption(label: 'Hampir Setiap Hari', score: 3),
    ],
  ),
];

/// GAD-7 Questions (7 pertanyaan untuk anxiety)
const gad7Questions = <Question>[
  Question(
    id: 'gad7_q1',
    type: AssessmentType.gad7,
    text: 'Merasa gugup, cemas, atau gelisah?',
    options: [
      AnswerOption(label: 'Tidak Pernah', score: 0),
      AnswerOption(label: 'Beberapa Hari', score: 1),
      AnswerOption(label: 'Lebih dari Separuh Hari', score: 2),
      AnswerOption(label: 'Hampir Setiap Hari', score: 3),
    ],
  ),
  Question(
    id: 'gad7_q2',
    type: AssessmentType.gad7,
    text: 'Tidak dapat menghentikan atau mengontrol kekhawatiran?',
    options: [
      AnswerOption(label: 'Tidak Pernah', score: 0),
      AnswerOption(label: 'Beberapa Hari', score: 1),
      AnswerOption(label: 'Lebih dari Separuh Hari', score: 2),
      AnswerOption(label: 'Hampir Setiap Hari', score: 3),
    ],
  ),
  Question(
    id: 'gad7_q3',
    type: AssessmentType.gad7,
    text: 'Terlalu khawatir tentang berbagai hal?',
    options: [
      AnswerOption(label: 'Tidak Pernah', score: 0),
      AnswerOption(label: 'Beberapa Hari', score: 1),
      AnswerOption(label: 'Lebih dari Separuh Hari', score: 2),
      AnswerOption(label: 'Hampir Setiap Hari', score: 3),
    ],
  ),
  Question(
    id: 'gad7_q4',
    type: AssessmentType.gad7,
    text: 'Kesulitan untuk rileks?',
    options: [
      AnswerOption(label: 'Tidak Pernah', score: 0),
      AnswerOption(label: 'Beberapa Hari', score: 1),
      AnswerOption(label: 'Lebih dari Separuh Hari', score: 2),
      AnswerOption(label: 'Hampir Setiap Hari', score: 3),
    ],
  ),
  Question(
    id: 'gad7_q5',
    type: AssessmentType.gad7,
    text: 'Sangat gelisah sehingga sulit untuk duduk diam?',
    options: [
      AnswerOption(label: 'Tidak Pernah', score: 0),
      AnswerOption(label: 'Beberapa Hari', score: 1),
      AnswerOption(label: 'Lebih dari Separuh Hari', score: 2),
      AnswerOption(label: 'Hampir Setiap Hari', score: 3),
    ],
  ),
  Question(
    id: 'gad7_q6',
    type: AssessmentType.gad7,
    text: 'Mudah kesal atau mudah marah?',
    options: [
      AnswerOption(label: 'Tidak Pernah', score: 0),
      AnswerOption(label: 'Beberapa Hari', score: 1),
      AnswerOption(label: 'Lebih dari Separuh Hari', score: 2),
      AnswerOption(label: 'Hampir Setiap Hari', score: 3),
    ],
  ),
  Question(
    id: 'gad7_q7',
    type: AssessmentType.gad7,
    text: 'Merasa takut bahwa sesuatu yang buruk akan terjadi?',
    options: [
      AnswerOption(label: 'Tidak Pernah', score: 0),
      AnswerOption(label: 'Beberapa Hari', score: 1),
      AnswerOption(label: 'Lebih dari Separuh Hari', score: 2),
      AnswerOption(label: 'Hampir Setiap Hari', score: 3),
    ],
  ),
];

/// Burnout Assessment Questions
const burnoutQuestions = <Question>[
  Question(
    id: 'burnout_q1',
    type: AssessmentType.burnout,
    text:
        'Merasa kelelahan secara fisik atau emosional karena pekerjaan/tugas?',
    options: [
      AnswerOption(label: 'Tidak Pernah', score: 0),
      AnswerOption(label: 'Kadang-kadang', score: 1),
      AnswerOption(label: 'Sering', score: 2),
      AnswerOption(label: 'Sangat Sering', score: 3),
    ],
  ),
  Question(
    id: 'burnout_q2',
    type: AssessmentType.burnout,
    text: 'Merasa sinis atau apatis terhadap pekerjaan/tugas Anda?',
    options: [
      AnswerOption(label: 'Tidak Pernah', score: 0),
      AnswerOption(label: 'Kadang-kadang', score: 1),
      AnswerOption(label: 'Sering', score: 2),
      AnswerOption(label: 'Sangat Sering', score: 3),
    ],
  ),
  Question(
    id: 'burnout_q3',
    type: AssessmentType.burnout,
    text:
        'Merasa bahwa pekerjaan/tugas Anda tidak lagi berarti atau tidak penting?',
    options: [
      AnswerOption(label: 'Tidak Pernah', score: 0),
      AnswerOption(label: 'Kadang-kadang', score: 1),
      AnswerOption(label: 'Sering', score: 2),
      AnswerOption(label: 'Sangat Sering', score: 3),
    ],
  ),
  Question(
    id: 'burnout_q4',
    type: AssessmentType.burnout,
    text:
        'Merasa kelelahan di pagi hari ketika memikirkan hari kerja yang akan datang?',
    options: [
      AnswerOption(label: 'Tidak Pernah', score: 0),
      AnswerOption(label: 'Kadang-kadang', score: 1),
      AnswerOption(label: 'Sering', score: 2),
      AnswerOption(label: 'Sangat Sering', score: 3),
    ],
  ),
  Question(
    id: 'burnout_q5',
    type: AssessmentType.burnout,
    text: 'Sulit untuk berkonsentrasi atau fokus pada tugas-tugas penting?',
    options: [
      AnswerOption(label: 'Tidak Pernah', score: 0),
      AnswerOption(label: 'Kadang-kadang', score: 1),
      AnswerOption(label: 'Sering', score: 2),
      AnswerOption(label: 'Sangat Sering', score: 3),
    ],
  ),
];

/// Default questions untuk backward compatibility (PHQ-9)
const defaultQuestions = phq9Questions;
