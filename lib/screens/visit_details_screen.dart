import 'package:flutter/material.dart';
import '../models/visit.dart';
import '../services/firestore_service.dart';

class VisitDetailsScreen extends StatefulWidget {
  final Visit visit;

  const VisitDetailsScreen({super.key, required this.visit});

  @override
  State<VisitDetailsScreen> createState() => _VisitDetailsScreenState();
}

class _VisitDetailsScreenState extends State<VisitDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isEditing = false;

  late TextEditingController _procedureController;
  late TextEditingController _investigationsController;
  late TextEditingController _treatmentsController;
  late TextEditingController _advicesController;

  @override
  void initState() {
    super.initState();
    _procedureController = TextEditingController(text: widget.visit.procedure);
    _investigationsController = TextEditingController(text: widget.visit.investigations);
    _treatmentsController = TextEditingController(text: widget.visit.treatments);
    _advicesController = TextEditingController(text: widget.visit.advices);
  }

  Future<void> _saveChanges() async {
    Visit updatedVisit = Visit(
      id: widget.visit.id,
      patientId: widget.visit.patientId,
      visitDate: widget.visit.visitDate,
      procedure: _procedureController.text,
      investigations: _investigationsController.text,
      treatments: _treatmentsController.text,
      advices: _advicesController.text,
      nextVisitDate: widget.visit.nextVisitDate,
    );

    await _firestoreService.updateVisit(updatedVisit);
    setState(() => _isEditing = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visit updated successfully!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visit Details'),
        backgroundColor: const Color(0xFF1E3A8A),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildField('Procedure', _procedureController),
            _buildField('Investigations', _investigationsController),
            _buildField('Treatments', _treatmentsController),
            _buildField('Advices', _advicesController),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        enabled: _isEditing,
        maxLines: null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: !_isEditing,
          fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
        ),
      ),
    );
  }
}
