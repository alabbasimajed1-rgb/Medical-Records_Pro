import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // ستحتاج لإضافة هذا في pubspec.yaml إذا أردت تنسيق التاريخ، أو سنستخدم طريقة مبسطة
import '../services/firestore_service.dart';
import 'add_edit_patient_screen.dart';
import 'reports_screen.dart';
import 'login_screen.dart';
// افترض أن لديك شاشة لعرض قائمة المرضى (مثلاً patients_list_screen.dart)، استبدلها بالاسم الصحيح لديك
// import 'patients_list_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  // دوال تسجيل الخروج
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  // --- أداة بناء بطاقات الإحصائيات العائمة ---
  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              count,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- أداة بناء أزرار الوصول السريع ---
  Widget _buildQuickAction(String title, IconData icon, VoidCallback onTap, {bool isPrimary = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: Colors.grey.shade200),
          boxShadow: isPrimary 
            ? [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))]
            : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              size: 32, 
              color: isPrimary ? Colors.white : const Color(0xFF1E3A8A)
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isPrimary ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // الحصول على تاريخ اليوم وتنسيقه
    final now = DateTime.now();
    final dateString = "${now.day} ${_getMonthName(now.month)} ${now.year}";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. الترويسة الفاخرة (Header) ---
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 80), // مساحة سفلية إضافية للبطاقات العائمة
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateString,
                                style: TextStyle(color: Colors.blue.shade200, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Dr. Majid Abbas',
                                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Consultant Anesthesia & Intensive Care',
                                style: TextStyle(color: Colors.blue.shade100, fontSize: 13),
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.logout, color: Colors.white, size: 22),
                              onPressed: _logout,
                              tooltip: 'Logout',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // --- 2. البطاقات الإحصائية العائمة ---
                Positioned(
                  top: 170, // تحديد موقع البطاقات لتطفو بين الترويسة والخلفية
                  left: 24,
                  right: 24,
                  child: Row(
                    children: [
                      // إحصائية المرضى (Real-time)
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('patients').snapshots(),
                        builder: (context, snapshot) {
                          String count = "0";
                          if (snapshot.hasData) count = snapshot.data!.docs.length.toString();
                          return _buildStatCard('Total Patients', count, Icons.people_alt_rounded, const Color(0xFF3B82F6));
                        },
                      ),
                      const SizedBox(width: 16),
                      // إحصائية الزيارات (Real-time)
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('visits').snapshots(),
                        builder: (context, snapshot) {
                          String count = "0";
                          if (snapshot.hasData) count = snapshot.data!.docs.length.toString();
                          return _buildStatCard('Total Visits', count, Icons.monitor_heart_rounded, const Color(0xFF10B981));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // مساحة فارغة لتعويض تداخل البطاقات العائمة
            const SizedBox(height: 120), 

            // --- 3. الإجراءات السريعة (Quick Actions) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    childAspectRatio: 1.3,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildQuickAction(
                        'New Patient', 
                        Icons.person_add_alt_1_rounded, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditPatientScreen())),
                        isPrimary: true, // إبراز هذا الزر بلون مختلف
                      ),
                      _buildQuickAction(
                        'Clinical Reports', 
                        Icons.analytics_rounded, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // دالة بسيطة لتحويل رقم الشهر إلى نص
  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
