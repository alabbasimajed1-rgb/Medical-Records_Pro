import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medical_app/l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.settings)),
      body: ListView(
        children: [
          ListTile(
            title: Text(loc.language),
            trailing: DropdownButton<String>(
              value: Localizations.localeOf(context).languageCode,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
              ],
              onChanged: (val) {
                // تغيير لغة التطبيق يتطلب إعادة بناء MaterialApp بالكامل
                // يمكن استخدام حزمة `easy_localization` أو State Management
                // هنا أبسط طريقة: أعد تشغيل التطبيق مع حفظ اللغة في SharedPreferences
                // اكتفي بالإشارة لهذا المبدأ.
              },
            ),
          ),
          ListTile(
            title: Text(loc.logout),
            onTap: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
    );
  }
}
