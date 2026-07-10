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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // --- بداية الثيم الشامل (Global Theme) ---
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey.shade50, // خلفية التطبيق الفاتحة والمريحة
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), // أزرق داكن (Navy Blue) كطابع طبي احترافي
          secondary: const Color(0xFF0F766E), // أخضر مزرق (Teal) للمسات الثانوية
        ),
        
        // 1. توحيد شكل حقول الإدخال (Text Fields)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade600),
          prefixIconColor: Colors.grey.shade500,
        ),

        // 2. توحيد البطاقات (Cards)
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.15), // ظل ناعم ومنتشر
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // 3. توحيد الأزرار الرئيسية (Elevated Buttons)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: const Color(0xFF1E3A8A).withOpacity(0.5),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // 4. توحيد شريط العناوين (App Bar)
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
        ),
      ),
      // --- نهاية الثيم الشامل ---
      
      home: const SplashScreen(),
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

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()), 
          );
        } else {
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
      body: Container(
        width: double.infinity,
        // إضافة تدرج لوني احترافي لخلفية الشاشة الافتتاحية
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F172A), // لون كحلي غامق
              Color(0xFF1E3A8A), // لون أزرق داكن
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // حاوية دائرية للأيقونة تبرزها بشكل أجمل
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.medical_services, size: 90, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'Medical-Records_Pro',
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              Text(
                statusText,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              if (!isError)
                const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
