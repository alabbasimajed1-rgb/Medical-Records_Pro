class Patient {
  final String? id;
  final String fullName;
  final int age;
  final String medicalHistory;

  Patient({
    this.id,
    required this.fullName,
    required this.age,
    required this.medicalHistory,
  });

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'age': age,
        'medicalHistory': medicalHistory,
      };

  factory Patient.fromMap(String id, Map<String, dynamic> map) => Patient(
        id: id,
        fullName: map['fullName'] ?? '',
        age: map['age'] ?? 0,
        medicalHistory: map['medicalHistory'] ?? '',
      );
}
