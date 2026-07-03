import 'package:flutter/material.dart';
// استدعاء الشاشات الجاهزة الموجودة في مجلدك
import 'patients_list_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // متغير لتتبع الشاشة النشطة حالياً (نبدأ بالشاشة 0 وهي قائمة المرضى)
  int _currentIndex = 0;

  // قائمة الشاشات التي سيتم التنقل بينها
  final List<Widget> _screens = [
    const PatientsListScreen(), // شاشة المرضى
    const ReportsScreen(),      // شاشة التقارير
    const SettingsScreen(),     // شاشة الإعدادات
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // يعرض الشاشة المناسبة بناءً على الزر المضغوط في الأسفل
      body: _screens[_currentIndex],
      
      // شريط التنقل السفلي
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // تحديث الواجهة عند الضغط على أي أيقونة
          });
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
