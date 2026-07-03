import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/firestore_service.dart';

class AddEditPatientScreen extends StatefulWidget {
  final Patient? patient; // null يعني إضافة جديدة، غير null يعني تعديل

  const AddEditPatientScreen({super.key, this.patient});

  @override
  State<AddEditPatientScreen> createState() => _AddEditPatientScreenState();
}

class _AddEditPatientScreenState extends State<AddEditPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _historyController;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.patient?.fullName ?? '',
    );
    _ageController = TextEditingController(
      text: widget.patient?.age.toString() ?? '',
    );
    _historyController = TextEditingController(
      text: widget.patient?.medicalHistory ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _historyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        // التعديل الأهم: إضافة firstVisitDate بناءً على حالة المريض
        final patient = Patient(
          id: widget.patient?.id, // الحفاظ على الـ ID إذا كنا في وضع التعديل
          fullName: _nameController.text.trim(),
          age: int.parse(_ageController.text.trim()),
          medicalHistory: _historyController.text.trim(),
          // إذا كان المريض موجوداً نأخذ تاريخه القديم، وإذا كان جديداً نأخذ تاريخ اليوم
          firstVisitDate: widget.patient?.firstVisitDate ?? DateTime.now(), 
        );

        if (widget.patient == null) {
          // إضافة مريض جديد
          await _firestoreService.addPatient(patient);
        } else {
          // تعديل مريض موجود
          await _firestoreService.updatePatient(widget.patient!.id!, patient);
        }

        if (mounted) {
          Navigator.pop(context, true); // إرجاع true للإشارة إلى نجاح العملية
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
        title: Text(isEditing ? 'Edit Patient' : 'Add Patient'),
        actions: [
          // زر حذف المريض (يظهر فقط في وضع التعديل)
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Patient'),
                    content: Text(
                      'Are you sure you want to delete ${widget.patient!.fullName}?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
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
              // حقل الاسم
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter patient name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // حقل العمر
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter patient age';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 0 || age > 150) {
                    return 'Please enter a valid age (0-150)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // حقل التاريخ المرضي
              TextFormField(
                controller: _historyController,
                decoration: const InputDecoration(
                  labelText: 'Medical History',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_services),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter medical history';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // زر الحفظ
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // جعلنا لون الزر أزرق ليتناسب مع التطبيق
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEditing ? 'Update Patient' : 'Add Patient',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
