import 'treatment.dart';

class Attachment {
  String type; // 'xray', 'lab_report', 'photo'
  String description;
  String fileUrl;

  Attachment({
    required this.type,
    required this.description,
    required this.fileUrl,
  });

  Map<String, dynamic> toMap() => {
        'type': type,
        'description': description,
        'fileUrl': fileUrl,
      };

  factory Attachment.fromMap(Map<String, dynamic> map) => Attachment(
        type: map['type'] ?? '',
        description: map['description'] ?? '',
        fileUrl: map['fileUrl'] ?? '',
      );
}

class Visit {
  final String? id;
  final String patientId;
  final DateTime visitDate;
  final String procedure;
  final String recommendations;
  final List<Treatment> treatments;
  final String notes;
  final List<Attachment> attachments;

  Visit({
    this.id,
    required this.patientId,
    required this.visitDate,
    required this.procedure,
    required this.recommendations,
    required this.treatments,
    required this.notes,
    required this.attachments,
  });

  Map<String, dynamic> toMap() => {
        'patientId': patientId,
        'visitDate': visitDate.toIso8601String(),
        'procedure': procedure,
        'recommendations': recommendations,
        'treatments': treatments.map((t) => t.toMap()).toList(),
        'notes': notes,
        'attachments': attachments.map((a) => a.toMap()).toList(),
      };

  factory Visit.fromMap(String id, Map<String, dynamic> map) => Visit(
        id: id,
        patientId: map['patientId'] ?? '',
        visitDate: DateTime.parse(map['visitDate']),
        procedure: map['procedure'] ?? '',
        recommendations: map['recommendations'] ?? '',
        treatments: (map['treatments'] as List<dynamic>?)
                ?.map((t) => Treatment.fromMap(t))
                .toList() ??
            [],
        notes: map['notes'] ?? '',
        attachments: (map['attachments'] as List<dynamic>?)
                ?.map((a) => Attachment.fromMap(a))
                .toList() ??
            [],
      );
}
