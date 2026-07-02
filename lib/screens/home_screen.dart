import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:medical_app/services/firestore_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange? _dateRange;
  final FirestoreService _service = FirestoreService();

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  Future<void> _generateAndUpload() async {
    if (_dateRange == null) return;
    // جلب الزيارات في النطاق (يمكنك استخدام firestore مع where)
    final visitsQuery = await FirebaseFirestore.instance
        .collection('visits')
        .where('visitDate', isGreaterThanOrEqualTo: _dateRange!.start.toIso8601String())
        .where('visitDate', isLessThanOrEqualTo: _dateRange!.end.toIso8601String())
        .get();
    final visits = visitsQuery.docs.map((doc) => Visit.fromMap(doc.id, doc.data())).toList();

    // بناء PDF
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      build: (ctx) => [
        pw.Header(text: 'Collective Report (${_dateRange!.start.toIso8601String()} - ${_dateRange!.end.toIso8601String()})'),
        ...visits.map((v) => pw.Column(
          children: [
            pw.Text('Patient: ${v.patientId}, Procedure: ${v.procedure}'),
            pw.Text('Date: ${v.visitDate.toIso8601String()}'),
            pw.Divider(),
          ],
        )),
      ],
    ));
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/report.pdf');
    await file.writeAsBytes(await pdf.save());

    // رفع إلى Google Drive (تحتاج OAuth)
    final googleSignIn = GoogleSignIn.standard(scopes: [drive.DriveApi.driveFileScope]);
    final googleUser = await googleSignIn.signIn();
    final authHeaders = await googleUser!.authentication;
    final authClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authClient);
    final drive.File driveFile = drive.File();
    driveFile.name = 'Medical_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await driveApi.files.create(driveFile, uploadMedia: drive.Media(file.openRead(), file.lengthSync()));

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report uploaded to Google Drive')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: _selectDateRange, child: const Text('Select Date Range')),
            if (_dateRange != null)
              Text('${_dateRange!.start.toIso8601String()} - ${_dateRange!.end.toIso8601String()}'),
            ElevatedButton(onPressed: _generateAndUpload, child: const Text('Generate & Upload to Drive')),
          ],
        ),
      ),
    );
  }
}
