class Patient {
  final String? id;
  final String fullName;
  final int age;
  final String gender; // النوع (Male/Female)
  final String medicalHistory;
  final String investigationAndImaging; // الفحوصات ونتائج الأشعة
  final String differentialDiagnosis; // التشخيص المبدئي
  final String finalDiagnosis; // التشخيص النهائي
  final String firstTreatmentPlan; // العلاجات واستخدامها
  final DateTime firstVisitDate;

  Patient({
    this.id,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.medicalHistory,
    required this.investigationAndImaging,
    required this.differentialDiagnosis,
    required this.finalDiagnosis,
    required this.firstTreatmentPlan,
    required this.firstVisitDate,
  });

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'age': age,
        'gender': gender,
        'medicalHistory': medicalHistory,
        'investigationAndImaging': investigationAndImaging,
        'differentialDiagnosis': differentialDiagnosis,
        'finalDiagnosis': finalDiagnosis,
        'firstTreatmentPlan': firstTreatmentPlan,
        'firstVisitDate': firstVisitDate.toIso8601String(),
      };

  factory Patient.fromMap(String id, Map<String, dynamic> map) => Patient(
        id: id,
        fullName: map['fullName'] ?? '',
        age: map['age'] ?? 0,
        // وضعنا قيماً افتراضية حتى لا تظهر أخطاء مع المرضى القدامى
        gender: map['gender'] ?? 'Unknown', 
        medicalHistory: map['medicalHistory'] ?? '',
        investigationAndImaging: map['investigationAndImaging'] ?? '',
        differentialDiagnosis: map['differentialDiagnosis'] ?? '',
        finalDiagnosis: map['finalDiagnosis'] ?? '',
        firstTreatmentPlan: map['firstTreatmentPlan'] ?? '',
        firstVisitDate: map['firstVisitDate'] != null
            ? DateTime.parse(map['firstVisitDate'])
            : DateTime.now(),
      );
}
