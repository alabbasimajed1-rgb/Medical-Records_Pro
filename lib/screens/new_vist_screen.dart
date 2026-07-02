import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/visit.dart';
import '../models/treatment.dart';
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

  // متحكمات النصوص
  final TextEditingController _procedureController = TextEditingController();
  final TextEditingController _recommendationsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // قائمة العلاجات
  final List<Treatment> _treatments = [];

  // قائمة الصور الملتقطة
  final List<File> _imagesToUpload = [];
  final List<String> _imageDescriptions = [];

  // أداة التقاط الصور
  final ImagePicker _picker = ImagePicker();

  // تاريخ الزيارة
  DateTime _visitDate = DateTime.now();

  // حالة الحفظ
  bool _isSaving = false;

  @override
  void dispose() {
    _procedureController.dispose();
    _recommendationsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // إضافة علاج جديد
  void _addTreatment() {
    setState(() {
      _treatments.add(Treatment(
        medicineName: '',
        dose: '',
        duration: '',
      ));
    });
  }

  // حذف علاج
  void _removeTreatment(int index) {
    setState(() {
      _treatments.removeAt(index);
    });
  }

  // اختيار تاريخ الزيارة
  Future<void> _selectDate() async {
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

  // التقاط صورة من الكاميرا أو المعرض
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image != null) {
        // طلب وصف للصورة
        final description = await _showDescriptionDialog();
        setState(() {
          _imagesToUpload.add(File(image.path));
          _imageDescriptions.add(description ?? '');
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  // نافذة وصف الصورة
  Future<String?> _showDescriptionDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Description'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g., X-ray, Lab report...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // حذف صورة
  void _removeImage(int index) {
    setState(() {
      _imagesToUpload.removeAt(index);
      _imageDescriptions.removeAt(index);
    });
  }

  // حفظ الزيارة
  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      // التحقق من وجود علاجات مكتملة
      for (var treatment in _treatments) {
        if (treatment.medicineName.isEmpty ||
            treatment.dose.isEmpty ||
            treatment.duration.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please complete all treatment fields'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      setState(() {
        _isSaving = true;
      });

      try {
        // رفع الصور أولاً
        List<Attachment> attachments = [];
        for (int i = 0; i < _imagesToUpload.length; i++) {
          final url = await _firestoreService.uploadImage(
            _imagesToUpload[i],
            'visits/${widget.patientId}',
          );
          attachments.add(Attachment(
            type: 'photo',
            description: _imageDescriptions[i],
            fileUrl: url,
          ));
        }

        // إنشاء كائن الزيارة
        final visit = Visit(
          patientId: widget.patientId,
          visitDate: _visitDate,
          procedure: _procedureController.text.trim(),
          recommendations: _recommendationsController.text.trim(),
          treatments: _treatments,
          notes: _notesController.text.trim(),
          attachments: attachments,
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
        title: const Text('New Visit'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
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
                    'Save',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // تاريخ الزيارة
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.blue),
                  title: const Text('Visit Date'),
                  subtitle: Text(
                    '${_visitDate.year}-${_visitDate.month.toString().padLeft(2, '0')}-${_visitDate.day.toString().padLeft(2, '0')}',
                  ),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: _selectDate,
                ),
              ),
              const SizedBox(height: 16),

              // الإجراء الطبي
              TextFormField(
                controller: _procedureController,
                decoration: const InputDecoration(
                  labelText: 'Procedure *',
                  hintText: 'e.g., Tooth extraction, Blood test...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_services),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the procedure';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // التوصيات
              TextFormField(
                controller: _recommendationsController,
                decoration: const InputDecoration(
                  labelText: 'Recommendations',
                  hintText: 'e.g., Rest for 2 days...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lightbulb),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // قسم العلاجات
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Treatments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addTreatment,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Treatment'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // قائمة العلاجات
              ..._treatments.asMap().entries.map((entry) {
                final index = entry.key;
                final treatment = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Treatment ${index + 1}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeTreatment(index),
                              iconSize: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Medicine Name *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.medication),
                            isDense: true,
                          ),
                          onChanged: (value) => treatment.medicineName = value,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Dose *',
                            hintText: 'e.g., 500mg, 2 tablets',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.format_list_numbered),
                            isDense: true,
                          ),
                          onChanged: (value) => treatment.dose = value,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Duration *',
                            hintText: 'e.g., 3 days, 1 week',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.timer),
                            isDense: true,
                          ),
                          onChanged: (value) => treatment.duration = value,
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),

              // الملاحظات
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes',
                  hintText: 'Any extra observations...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // المرفقات
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Attachments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        tooltip: 'Take Photo',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue.shade50,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        tooltip: 'Pick from Gallery',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green.shade50,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // عرض الصور الملتقطة
              if (_imagesToUpload.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _imagesToUpload.asMap().entries.map((entry) {
                    final index = entry.key;
                    final image = entry.value;
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              image,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        if (_imageDescriptions[index].isNotEmpty)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              color: Colors.black54,
                              child: Text(
                                _imageDescriptions[index],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
