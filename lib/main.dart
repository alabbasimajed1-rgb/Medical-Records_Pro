import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// تأكد من وجود ملف firebase_options.dart إذا كنت قد استخدمت flutterfire configure
// إذا لم تستخدمه، سنعتمد على google-services.json تلقائياً
import 'firebase_options.dart'; 
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // نستخدم try-catch لاكتشاف أي خطأ في الاتصال فوراً
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase Error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medical Records',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // إضافة معالجة لحالة الخطأ في الـ Stream
          if (snapshot.hasError) {
             return const Scaffold(body: Center(child: Text("Error connecting to Auth")));
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
