import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ar.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
  ];

  // الأزرار والعناوين
  String get appTitle => 'Medical Records';
  String get login => 'Login';
  String get email => 'Email';
  String get password => 'Password';
  String get patientsList => 'Patients List';
  String get addPatient => 'Add Patient';
  String get editPatient => 'Edit Patient';
  String get fullName => 'Full Name';
  String get age => 'Age';
  String get medicalHistory => 'Medical History (Brief)';
  String get save => 'Save';
  String get cancel => 'Cancel';
  String get search => 'Search';
  String get patientDetails => 'Patient Details';
  String get visits => 'Visits';
  String get newVisit => 'New Visit';
  String get procedure => 'Procedure';
  String get recommendations => 'Recommendations';
  String get treatments => 'Treatments';
  String get addTreatment => 'Add Treatment';
  String get medicineName => 'Medicine Name';
  String get dose => 'Dose';
  String get duration => 'Duration';
  String get notes => 'Additional Notes';
  String get attachments => 'Attachments';
  String get takePhoto => 'Take Photo';
  String get pickFromGallery => 'Pick from Gallery';
  String get visitDetails => 'Visit Details';
  String get reports => 'Reports';
  String get generatePdf => 'Generate Report PDF';
  String get uploadToDrive => 'Upload to Google Drive';
  String get settings => 'Settings';
  String get language => 'Language';
  String get logout => 'Logout';
  String get noPatients => 'No patients found';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale.toString()));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ar'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
