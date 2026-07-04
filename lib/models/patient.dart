class Patient {
  final String? id;
  final String fullName;
  final int age;
  final String medicalHistory;
  final DateTime firstVisitDate; // هذه هي الكلمة التي كان يبحث عنها النظام!

  Patient({
    this.id,
    required this.fullName,
    required this.age,
    required this.medicalHistory,
    required this.firstVisitDate,
  });

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'age': age,
        'medicalHistory': medicalHistory,
        'firstVisitDate': firstVisitDate.toIso8601String(), 
      };

  factory Patient.fromMap(String id, Map<String, dynamic> map) => Patient(
        id: id,
        fullName: map['fullName'] ?? '',
        age: map['age'] ?? 0,
        medicalHistory: map['medicalHistory'] ?? '',
        firstVisitDate: map['firstVisitDate'] != null 
            ? DateTime.parse(map['firstVisitDate']) 
            : DateTime.now(), 
      );
}
