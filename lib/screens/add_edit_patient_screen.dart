import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/firestore_service.dart';

class AddEditPatientScreen extends StatefulWidget {
  final Patient? patient; 

  const AddEditPatientScreen({super.key, this.patient});

  @override
  State<AddEditPatientScreen> createState() => _AddEditPatientScreenState();
}

class _AddEditPatientScreenState extends State<AddEditPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSaving = false;

  // تعريف متحكمات النصوص لجميع الحقول
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _chiefComplaintController; // متحكم الشكوى الرئيسية
  late TextEditingController _historyController;
  late TextEditingController _investigationController;
  late TextEditingController _diffDiagnosisController;
  late TextEditingController _finalDiagnosisController;
  late TextEditingController _treatmentController;
  
  // متغير لتحديد النوع (افتراضياً ذكر)
  String _selectedGender = 'Male';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patient?.fullName ?? '');
    _ageController = TextEditingController(text: widget.patient?.age.toString() ?? '');
    // إضافة الشكوى الرئيسية
    _chiefComplaintController = TextEditingController(text: widget.patient?.chiefComplaint ?? '');
    _historyController = TextEditingController(text: widget.patient?.medicalHistory ?? '');
    _investigationController = TextEditingController(text: widget.patient?.investigationAndImaging ?? '');
    _diffDiagnosisController = TextEditingController(text: widget.patient?.differentialDiagnosis ?? '');
    _finalDiagnosisController = TextEditingController(text: widget.patient?.finalDiagnosis ?? '');
    _treatmentController = TextEditingController(text: widget.patient?.firstTreatmentPlan ?? '');
    
    // جلب النوع إذا كنا في وضع التعديل
    if (widget.patient != null && (widget.patient!.gender == 'Male' || widget.patient!.gender == 'Female')) {
      _selectedGender = widget.patient!.gender;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _chiefComplaintController.dispose(); // إغلاق المتحكم
    _historyController.dispose();
    _investigationController.dispose();
    _diffDiagnosisController.dispose();
    _finalDiagnosisController.dispose();
    _treatmentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final patient = Patient(
          id: widget.patient?.id, 
          fullName: _nameController.text.trim(),
          age: int.parse(_ageController.text.trim()),
          gender: _selectedGender, 
          chiefComplaint: _chiefComplaintController.text.trim(), // حفظ الشكوى الرئيسية
          medicalHistory: _historyController.text.trim(),
          investigationAndImaging: _investigationController.text.trim(),
          differentialDiagnosis: _diffDiagnosisController.text.trim(),
          finalDiagnosis: _finalDiagnosisController.text.trim(),
          firstTreatmentPlan: _treatmentController.text.trim(),
          firstVisitDate: widget.patient?.firstVisitDate ?? DateTime.now(), 
        );

        if (widget.patient == null) {
          await _firestoreService.addPatient(patient);
        } else {
          await _firestoreService.updatePatient(widget.patient!.id!, patient);
        }

        if (mounted) {
          Navigator.pop(context, true); 
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.patient != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Patient Profile' : 'Add New Patient'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Patient'),
                    content: Text(
                      'Are you sure you want to delete ${_nameController.text}?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  try {
                    await _firestoreService.deletePatient(widget.patient!.id!);
                    Navigator.pop(context, true);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- القسم الأول: البيانات الديموغرافية ---
              const Text(
                'Patient Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today, size: 20),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Required';
                        final age = int.tryParse(value);
                        if (age == null || age < 0 || age > 150) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.wc, size: 20),
                      ),
                        items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const Divider(height: 32, thickness: 1),

              // --- القسم الجديد: الشكوى الرئيسية ---
              const Text(
                'Chief Complaint',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _chiefComplaintController,
                decoration: const InputDecoration(
                  labelText: 'Chief Complaint',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const Divider(height: 32, thickness: 1),

              // --- القسم الثاني: التاريخ الطبي والفحوصات ---
              const Text(
                'Clinical Data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _historyController,
                decoration: const InputDecoration(
                  labelText: 'Medical History',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _investigationController,
                decoration: const InputDecoration(
                  labelText: 'Investigation and Imaging Results',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const Divider(height: 32, thickness: 1),

              // --- القسم الثالث: التشخيص ---
              const Text(
                'Diagnosis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _diffDiagnosisController,
                decoration: const InputDecoration(
                  labelText: 'Differential Diagnosis',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 2,
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _finalDiagnosisController,
                decoration: const InputDecoration(
                  labelText: 'Final Diagnosis',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 2,
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const Divider(height: 32, thickness: 1),

              // --- القسم الرابع: العلاج ---
              const Text(
                'Management',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _treatmentController,
                decoration: const InputDecoration(
                  labelText: 'Treatments (First Treatment Plan)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 32),

              // زر الحفظ بتصميم بارز
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isEditing ? 'Update Patient Profile' : 'Save Patient Profile',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
