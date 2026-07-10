import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/visit.dart';
import '../models/patient.dart';
import '../services/firestore_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange? _dateRange;
  Patient? _selectedPatient;
  bool _isGenerating = false;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700, 
              onPrimary: Colors.white, 
              onSurface: Colors.black, 
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
    setState(() {
      _isGenerating = true;
    });

    try {
      Query visitsQueryRef = FirebaseFirestore.instance.collection('visits');

      if (_dateRange != null) {
        visitsQueryRef = visitsQueryRef
            .where('visitDate', isGreaterThanOrEqualTo: _dateRange!.start.toIso8601String())
            .where('visitDate', isLessThanOrEqualTo: _dateRange!.end.toIso8601String());
      }

      final visitsQuery = await visitsQueryRef.get();

      var visits = visitsQuery.docs
          .map((doc) => Visit.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      if (_selectedPatient != null) {
        visits = visits.where((v) => v.patientId == _selectedPatient!.id).toList();
      }

      if (visits.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No records found for the selected criteria.')),
          );
        }
        setState(() {
          _isGenerating = false;
        });
        return;
      }

      visits.sort((a, b) => b.visitDate.compareTo(a.visitDate));

      // تحميل خط يدعم اللغة العربية
      final arabicFont = await PdfGoogleFonts.cairoRegular();
      final arabicFontBold = await PdfGoogleFonts.cairoBold();

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicFontBold,
        ),
      );
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          // إضافة التوقيع في ذيل الصفحة
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 20.0),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Dr. Majed Abbas', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  pw.Text('Consultant Anesthesia & Intensive Care', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                ]
              )
            );
          },
          build: (ctx) => [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    _selectedPatient != null ? 'PATIENT MEDICAL REPORT' : 'CLINICAL VISITS REPORT', 
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)
                  ),
                  pw.SizedBox(height: 8),
                  // السطر الجديد الذي طلبته
                  pw.Text('To whom it may concern,', style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic, color: PdfColors.grey800)),
                  pw.SizedBox(height: 16),
                  
                  if (_selectedPatient != null) ...[
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        border: pw.Border.all(color: PdfColors.grey400),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                      ),
                      child: pw.Directionality(
                        textDirection: pw.TextDirection.rtl, // لدعم القراءة من اليمين لليسار للعربي
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Directionality(
                              textDirection: pw.TextDirection.ltr,
                              child: pw.Text('Patient Name: ${_selectedPatient!.fullName}  |  Age: ${_selectedPatient!.age}  |  Gender: ${_selectedPatient!.gender}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text('Chief Complaint: ${_selectedPatient!.chiefComplaint}', style: pw.TextStyle(color: PdfColors.grey800)),
                            pw.SizedBox(height: 4),
                            pw.Text('Medical History: ${_selectedPatient!.medicalHistory}', style: pw.TextStyle(color: PdfColors.grey800)),
                          ]
                        ),
                      )
                    ),
                    pw.SizedBox(height: 12),
                  ],

                  if (_dateRange != null)
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
            
            ...visits.map((v) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 15),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Directionality(
                    textDirection: pw.TextDirection.rtl, // لدعم النصوص العربية داخل الزيارات
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Directionality(
                          textDirection: pw.TextDirection.ltr,
                          child: pw.Text('Visit Date: ${v.visitDate.toString().substring(0, 10)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        ),
                        pw.Divider(color: PdfColors.grey300),
                        pw.SizedBox(height: 5),
                        
                        pw.Text('New complaint / Procedure:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                        pw.Text(v.procedure),
                        pw.SizedBox(height: 8),
                        
                        if (v.investigations.isNotEmpty) ...[
                          pw.Text('Investigations:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                          pw.Text(v.investigations),
                          pw.SizedBox(height: 8),
                        ],
                        
                        if (v.treatments.isNotEmpty) ...[
                          pw.Text('Treatments Prescribed:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                          pw.Text(v.treatments),
                          pw.SizedBox(height: 8),
                        ],

                        if (v.advices.isNotEmpty) ...[
                          pw.Text('Advices:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                          pw.Text(v.advices),
                        ],
                      ],
                    ),
                  ),
                )),
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      String fileName = _selectedPatient != null 
          ? 'Report_${_selectedPatient!.fullName.replaceAll(' ', '_')}.pdf'
          : 'Clinical_Report.pdf';
          
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);
      
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics_outlined, size: 80, color: Colors.blue.shade200),
              const SizedBox(height: 16),
              const Text(
                'Generate Clinical Reports',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Select a patient or a date range (or both) to export a comprehensive PDF report.',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: StreamBuilder<List<Patient>>(
                    stream: _firestoreService.getPatients(),
                    builder: (context, snapshot) {
                      List<Patient> patients = snapshot.data ?? [];
                      return DropdownButtonHideUnderline(
                        child: DropdownButton<Patient?>(
                          isExpanded: true,
                          value: _selectedPatient,
                          hint: Row(
                            children: [
                              Icon(Icons.groups, color: Colors.blue.shade700),
                              const SizedBox(width: 16),
                              const Text('All Patients (Global Report)', style: TextStyle(fontWeight: FontWeight.bold)),
                            ]
                          ),
                          items: [
                            DropdownMenuItem<Patient?>(
                              value: null,
                              child: Row(
                                children: [
                                  Icon(Icons.groups, color: Colors.blue.shade700),
                                  const SizedBox(width: 16),
                                  const Text('All Patients (Global)', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            ...patients.map((p) => DropdownMenuItem<Patient?>(
                              value: p,
                              child: Row(
                                children: [
                                  const Icon(Icons.person, color: Colors.grey),
                                  const SizedBox(width: 16),
                                  Text(p.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )),
                          ],
                          onChanged: (val) {
                            setState(() => _selectedPatient = val);
                          },
                        ),
                      );
                    }
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                        ? 'All Time' 
                        : '${_dateRange!.start.toString().substring(0, 10)}  to  ${_dateRange!.end.toString().substring(0, 10)}',
                    style: TextStyle(color: _dateRange == null ? Colors.grey : Colors.blue.shade800),
                  ),
                  trailing: _dateRange != null 
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.red),
                          onPressed: () => setState(() => _dateRange = null),
                        )
                      : const Icon(Icons.edit, size: 20),
                  onTap: _selectDateRange,
                ),
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generatePdf,
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
