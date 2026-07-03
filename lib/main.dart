import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';

void main() {
  // نقوم بتشغيل واجهة التطبيق فوراً دون انتظار Firebase هنا
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

// حولنا الشاشة إلى StatefulWidget لكي نتمكن من تشغيل كود الاتصال بداخلها
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String statusText = "Connecting to Database..."; // نص حالة الاتصال
  bool isError = false;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase(); // بدء الاتصال بمجرد فتح الشاشة الزرقاء
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      // إذا نجح الاتصال، نظهر زر الدخول
      setState(() {
        isInitialized = true;
        statusText = "Connected Successfully!";
      });
    } catch (e) {
      // إذا فشل الاتصال، نطبع الخطأ على الشاشة لنعرف المشكلة بالضبط!
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
              
              // عرض حالة الاتصال بـ Firebase
              Text(
                statusText,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // عرض دائرة تحميل أثناء محاولة الاتصال
              if (!isInitialized && !isError)
                const CircularProgressIndicator(color: Colors.white),

              // إذا نجح الاتصال، نعرض الزر
              if (isInitialized)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text(
                    "Get Started",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
