import 'package:flutter/material.dart';
// تأكد من أن هذا المسار صحيح لشاشة تسجيل الدخول الخاصة بك
import 'screens/login_screen.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), // فصلنا الشاشة لتسهيل الكود
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medical_services, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              'Medical App',
              style: TextStyle(
                fontSize: 30, 
                color: Colors.white, 
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 50), // مسافة فاصلة قبل الزر
            
            // الزر الجديد للانتقال إلى شاشة الدخول
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, // لون الزر
                foregroundColor: Colors.blue, // لون النص
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              onPressed: () {
                // أمر الانتقال إلى شاشة تسجيل الدخول
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text(
                "الدخول للتطبيق", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
