import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/patient.dart';
import '../models/visit.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ========= المرضى =========
  Stream<List<Patient>> getPatients() {
    return _db.collection('patients').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Patient.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> addPatient(Patient patient) {
    return _db.collection('patients').add(patient.toMap());
  }

  Future<void> updatePatient(String id, Patient patient) {
    return _db.collection('patients').doc(id).update(patient.toMap());
  }

  Future<void> deletePatient(String id) {
    return _db.collection('patients').doc(id).delete();
  }

  // ========= الزيارات =========
  Stream<List<Visit>> getVisitsForPatient(String patientId) {
    return _db
        .collection('visits')
        .where('patientId', isEqualTo: patientId)
        .orderBy('visitDate', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Visit.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> addVisit(Visit visit) {
    return _db.collection('visits').add(visit.toMap());
  }

  Future<void> updateVisit(String id, Visit visit) {
    return _db.collection('visits').doc(id).update(visit.toMap());
  }

  // ========= رفع الصور =========
  Future<String> uploadImage(File imageFile, String folder) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('$folder/$fileName');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }
}
