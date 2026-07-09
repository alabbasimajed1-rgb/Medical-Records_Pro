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
  bool _isGenerating = false;

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700, // لون الهيدر
              onPrimary: Colors.white, // لون النص في الهيدر
              onSurface: Colors.black, // لون الأيام
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  Future<void> _generatePdf() async {
    if (_dateRange == null) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final visitsQuery = await FirebaseFirestore.instance
          .collection('visits')
          .where('visitDate', isGreaterThanOrEqualTo: _dateRange!.start.toIso8601String())
          .where('visitDate', isLessThanOrEqualTo: _dateRange!.end.toIso8601String())
          .get();

      final visits = visitsQuery.docs
          .map((doc) => Visit.fromMap(doc.id, doc.data()))
          .toList();

      if (visits.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No records found for this period.')),
          );
        }
        setState(() {
          _isGenerating = false;
        });
        return;
      }

      final pdf = pw.Document();
      
      // تصميم ترويسة التقرير بشكل احترافي
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (ctx) => [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('CLINICAL VISITS REPORT', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  pw.SizedBox(height: 8),
                  pw.Text('Dr. Majed Abbas', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Consultant Anesthesia & Intensive Care', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                  pw.SizedBox(height: 12),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                    ),
                    child: pw.Text(
                      'Period: ${_dateRange!.start.toString().substring(0, 10)}  TO  ${_dateRange!.end.toString().substring(0, 10)}',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                ],
              ),
            ),
            
            // جدول الزيارات
            ...visits.map((v) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 15),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Date: ${v.visitDate.toString().substring(0, 10)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          // إذا كان هناك حقل لاسم المريض في موديل الزيارة يمكنك إضافته هنا
                        ],
                      ),
                      pw.Divider(color: PdfColors.grey300),
                      pw.SizedBox(height: 5),
                      pw.Text('Procedure / Complaint:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                      pw.Text(v.procedure),
                      pw.SizedBox(height: 8),
                      if (v.treatments.isNotEmpty) ...[
                        pw.Text('Treatments Prescribed:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                        pw.Text(v.treatments),
                      ],
                    ],
                  ),
                )),
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/Clinical_Report.pdf');
      await file.writeAsBytes(await pdf.save());
      await Printing.sharePdf(bytes: await pdf.save(), filename: 'Clinical_Report_${_dateRange!.start.toString().substring(0, 10)}.pdf');
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics_outlined, size: 100, color: Colors.blue.shade200),
              const SizedBox(height: 24),
              const Text(
                'Generate Clinical Reports',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Select a date range to export a comprehensive PDF report of all patient visits.',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // بطاقة اختيار التاريخ
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Icon(Icons.calendar_month, color: Colors.blue.shade700),
                  ),
                  title: Text(
                    _dateRange == null ? 'Select Date Range' : 'Selected Period',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _dateRange == null 
                        ? 'Tap to pick dates' 
                        : '${_dateRange!.start.toString().substring(0, 10)}  to  ${_dateRange!.end.toString().substring(0, 10)}',
                    style: TextStyle(color: _dateRange == null ? Colors.grey : Colors.blue.shade800),
                  ),
                  trailing: const Icon(Icons.edit, size: 20),
                  onTap: _selectDateRange,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // زر توليد التقرير
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: (_dateRange != null && !_isGenerating) ? _generatePdf : null,
                  icon: _isGenerating 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.picture_as_pdf),
                  label: Text(
                    _isGenerating ? 'Generating...' : 'Generate & Share PDF',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
