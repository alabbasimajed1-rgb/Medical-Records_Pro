import 'package:flutter/material.dart';
import '../models/visit.dart';
import '../services/firestore_service.dart';

class NewVisitScreen extends StatefulWidget {
  final String patientId;

  const NewVisitScreen({super.key, required this.patientId});

  @override
  State<NewVisitScreen> createState() => _NewVisitScreenState();
}

class _NewVisitScreenState extends State<NewVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  // متحكمات النصوص السريرية
  final TextEditingController _procedureController = TextEditingController();
  final TextEditingController _investigationsController = TextEditingController();
  final TextEditingController _treatmentsController = TextEditingController();
  final TextEditingController _advicesController = TextEditingController();

  // التواريخ
  DateTime _visitDate = DateTime.now();
  DateTime? _nextVisitDate; // اختياري

  // حالة الحفظ
  bool _isSaving = false;

  @override
  void dispose() {
    _procedureController.dispose();
    _investigationsController.dispose();
    _treatmentsController.dispose();
    _advicesController.dispose();
    super.dispose();
  }

  // اختيار تاريخ الزيارة الحالية
  Future<void> _selectVisitDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _visitDate = picked;
      });
    }
  }

  // اختيار تاريخ الزيارة القادمة (المراجعة)
  Future<void> _selectNextVisitDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextVisitDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(), // المراجعة يجب أن تكون في المستقبل
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _nextVisitDate = picked;
      });
    }
  }

  // حفظ الزيارة
  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        // إنشاء كائن الزيارة بالهيكلة الطبية الجديدة
        final visit = Visit(
          patientId: widget.patientId,
          visitDate: _visitDate,
          procedure: _procedureController.text.trim(),
          investigations: _investigationsController.text.trim(),
          treatments: _treatmentsController.text.trim(),
          advices: _advicesController.text.trim(),
          nextVisitDate: _nextVisitDate,
        );

        // حفظ الزيارة في Firestore
        await _firestoreService.addVisit(visit);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Visit saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Visit'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- تاريخ الزيارة ---
              Card(
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.blue),
                  title: const Text('Visit Date', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${_visitDate.year}-${_visitDate.month.toString().padLeft(2, '0')}-${_visitDate.day.toString().padLeft(2, '0')}',
                  ),
                  trailing: const Icon(Icons.edit, color: Colors.grey),
                  onTap: _selectVisitDate,
                ),
              ),
              const SizedBox(height: 16),

              // --- الشكوى الجديدة ---
              TextFormField(
                controller: _procedureController,
                decoration: const InputDecoration(
                  labelText: 'New complaint *',
                  hintText: 'e.g., Follow up, Routine check...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_services),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the new complaint';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- الفحوصات الجديدة ---
              TextFormField(
                controller: _investigationsController,
                decoration: const InputDecoration(
                  labelText: 'New Investigations & Imaging',
                  hintText: 'Results of new tests for this visit...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.biotech),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // --- العلاجات المضافة ---
              TextFormField(
                controller: _treatmentsController,
                decoration: const InputDecoration(
                  labelText: 'Treatments Prescribed',
                  hintText: 'Write medicines and doses here...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medication),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              // --- النصائح / إيقاف الأدوية ---
              TextFormField(
                controller: _advicesController,
                decoration: const InputDecoration(
                  labelText: 'Advices (e.g., Stop medication X)',
                  hintText: 'Diet, precautions, or stopped meds...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lightbulb),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // --- موعد الزيارة القادمة ---
              Card(
                elevation: 2,
                color: Colors.blue.shade50,
                child: ListTile(
                  leading: const Icon(Icons.event_available, color: Colors.blue),
                  title: const Text('Next Visit Date (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    _nextVisitDate != null 
                        ? '${_nextVisitDate!.year}-${_nextVisitDate!.month.toString().padLeft(2, '0')}-${_nextVisitDate!.day.toString().padLeft(2, '0')}'
                        : 'Not Scheduled',
                    style: TextStyle(color: _nextVisitDate != null ? Colors.black : Colors.grey),
                  ),
                  trailing: _nextVisitDate != null 
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.red),
                          onPressed: () => setState(() => _nextVisitDate = null),
                        )
                      : const Icon(Icons.add_circle, color: Colors.blue),
                  onTap: _selectNextVisitDate,
                ),
              ),
              const SizedBox(height: 32),

              // --- زر الحفظ ---
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // لون بارز
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Visit Record',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
