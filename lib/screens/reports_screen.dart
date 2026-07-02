import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/visit.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange? _dateRange;

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  Future<void> _generatePdf() async {
    if (_dateRange == null) return;
    
    final visitsQuery = await FirebaseFirestore.instance
        .collection('visits')
        .where('visitDate', isGreaterThanOrEqualTo: _dateRange!.start.toIso8601String())
        .where('visitDate', isLessThanOrEqualTo: _dateRange!.end.toIso8601String())
        .get();
    
    final visits = visitsQuery.docs
        .map((doc) => Visit.fromMap(doc.id, doc.data()))
        .toList();

    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      build: (ctx) => [
        pw.Header(text: 'Medical Report'),
        ...visits.map((v) => pw.Column(
          children: [
            pw.Text('Procedure: ${v.procedure}'),
            pw.Text('Date: ${v.visitDate}'),
            pw.Divider(),
          ],
        )),
      ],
    ));

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/report.pdf');
    await file.writeAsBytes(await pdf.save());
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'report.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _selectDateRange,
              child: const Text('Select Date Range'),
            ),
            if (_dateRange != null)
              Text('${_dateRange!.start} - ${_dateRange!.end}'),
            ElevatedButton(
              onPressed: _generatePdf,
              child: const Text('Generate & Share PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
