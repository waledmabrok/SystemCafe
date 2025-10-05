import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:xo/db_helper.dart';
import 'package:xo/Screens/staff/staff_dashboard.dart';

import 'Screens/admin/admin.dart';
import 'Screens/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  /* String path = join(await getDatabasesPath(), 'xo_cafe1.db');
  await deleteDatabase(path); // يحذف قاعدة البيانات القديمة
*/
  await DBHelper.initDB();
  runApp(XOCafeApp());
}

class XOCafeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XO Cafe Gaming',
      theme: ThemeData(
        // 🟣 الألوان الأساسية
        primaryColor: Colors.deepPurple,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.deepPurple,
          accentColor: Colors.amber,
        ),

        // 🖋️ الخطوط
        fontFamily: 'Cairo',
        // لو عندك فونت مخصص
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
          displayMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
        ),

        // 🟢 أزرار التطبيق
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.deepPurple, // لون النص داخل الزر
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),

        // ⚪ شريط التطبيق
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurple,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),

        // ⚫ Input fields
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.deepPurple),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.deepPurple, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.deepPurple),
        ),

        // ⚪ Card
        /*    cardTheme: CardThemeData(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: Colors.black26,
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        ),
    */
      ),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // 👈 Force RTL layout
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      home: LoginScreen(),
      routes: {
        '/admin': (_) => AdminDashboard(),
        '/staff': (_) => StaffDashboard(),
      },
    );
  }
}

/*
XO Café Gaming - Flutter + SQLite

تشغيل:
1. flutter pub get
2. flutter run

ميزات مبدئية:
- Login (admin / staff)
- Admin: إدارة الأجهزة، المشروبات، المستخدمين، تقارير بسيطة
- Staff: بدء/إنهاء جلسة، إضافة مشروبات للفواتير، عرض فاتورة
- قاعدة بيانات محلية SQLite (xo_cafe.db)

ملاحظات:
- هذا إصدار MVP (قابل للتطوير). لإضافة: طباعة PDF، نسخ احتياطي للـ DB، تحسين واجهة، صلاحيات متقدمة.
*/
