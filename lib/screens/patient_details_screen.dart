import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient.dart';
import '../models/visit.dart';
import '../services/firestore_service.dart';
import 'add_edit_patient_screen.dart';
import 'new_visit_screen.dart';
import 'visit_details_screen.dart';

class PatientDetailsScreen extends StatefulWidget {
  final Patient patient;

  const PatientDetailsScreen({super.key, required this.patient});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Patient _patient;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
  }

  void _editPatient() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditPatientScreen(patient: _patient),
      ),
    );

    if (result == true) {
      _refreshPatient();
    }
  }

  void _refreshPatient() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(_patient.id)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _patient = Patient.fromMap(doc.id, doc.data()!);
        });
      }
    } catch (e) {
      // تجاهل الخطأ
    }
  }

  // أداة مساعدة لعرض العناوين والنصوص بشكل مرتب
  Widget _buildInfoSection(String title, String content, IconData icon) {
    if (content.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 26.0),
            child: Text(
              content,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient File'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_document),
            onPressed: _editPatient,
            tooltip: 'Edit Patient Info',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- بطاقة معلومات المريض الشاملة ---
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الرأس: الاسم والعمر والنوع
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            _patient.fullName.isNotEmpty
                                ? _patient.fullName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _patient.fullName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('Age: ${_patient.age}'),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _patient.gender == 'Female' ? Colors.pink.shade50 : Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _patient.gender,
                                      style: TextStyle(
                                        color: _patient.gender == 'Female' ? Colors.pink.shade700 : Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32, thickness: 1),

                    // التفاصيل السريرية
                    _buildInfoSection('Medical History', _patient.medicalHistory, Icons.history),
                    _buildInfoSection('Investigations & Imaging', _patient.investigationAndImaging, Icons.biotech),
                    _buildInfoSection('Differential Diagnosis', _patient.differentialDiagnosis, Icons.device_unknown),
                    _buildInfoSection('Final Diagnosis', _patient.finalDiagnosis, Icons.fact_check),
                    _buildInfoSection('Initial Treatment Plan', _patient.firstTreatmentPlan, Icons.medication),
                  ],
                ),
              ),
            ),

            // --- قسم الزيارات ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Clinical Visits',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NewVisitScreen(patientId: _patient.id!),
                        ),
                      ).then((_) => setState(() {}));
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Visit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // قائمة الزيارات
            StreamBuilder<List<Visit>>(
              stream: _firestoreService.getVisitsForPatient(_patient.id!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No visits recorded yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  );
                }

                final visits = snapshot.data!;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visits.length,
                  itemBuilder: (context, index) {
                    final visit = visits[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade50,
                          radius: 25,
