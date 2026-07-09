import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart'; // تأكد من اسم ملف الشاشة الرئيسية لديك
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String statusText = "Connecting to Database..."; 
  bool isError = false;

  @override
  void initState() {
    super.initState();
    _initializeAndCheckAuth(); 
  }

  Future<void> _initializeAndCheckAuth() async {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyC5MHDAaguF81KaUV_JO_WD4ScTs1HD7fA",
          appId: "1:104334827144:android:7925c2cb0dc2171c9e493d",
          messagingSenderId: "104334827144",
          projectId: "medical-records-pro",
          storageBucket: "medical-records-pro.firebasestorage.app",
        ),
      );
      
      setState(() {
        statusText = "Connected Successfully!";
      });

      // انتظار ثانية واحدة لتظهر رسالة النجاح للمستخدم
      await Future.delayed(const Duration(seconds: 1));

      // فحص حالة تسجيل الدخول وتوجيه المستخدم تلقائياً
      if (mounted) {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // المستخدم مسجل دخوله مسبقاً -> الذهاب للشاشة الرئيسية
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()), // استبدل HomeScreen باسم شاشتك
          );
        } else {
          // لا يوجد مستخدم مسجل -> الذهاب لشاشة الدخول
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      setState(() {
        isError = true;
        statusText = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.medical_services, size: 100, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                'Medical-Records_Pro',
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              Text(
                statusText,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // سيظل مؤشر التحميل يدور حتى يتم الانتقال التلقائي
              if (!isError)
                const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
