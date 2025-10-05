import 'package:flutter/material.dart';
import '../../db_helper.dart';
import 'manage_consoles.dart';
import 'manage_drinks.dart';
import 'manage_users.dart';
import 'reports.dart';

class AdminDashboard extends StatefulWidget {
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int sessionsCount = 0;
  double incomeToday = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final invoices = await DBHelper.getAllInvoices();
    setState(() {
      sessionsCount = invoices.length;
      incomeToday = invoices.fold(
        0.0,
        (p, e) => p + ((e['total_cost'] ?? 0) as num).toDouble(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          ' XO Café',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder:
                    (_) => AlertDialog(
                      title: Text('تأكيد'),
                      content: Text(
                        'هل تريد مسح كل البيانات (ما عدا المشروبات والأجهزة)؟',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('إلغاء'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('تأكيد'),
                        ),
                      ],
                    ),
              );

              if (confirmed == true) {
                await DBHelper.clearAllData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم مسح جميع البيانات بنجاح!')),
                );
                setState(() {
                  sessionsCount = 0;
                  incomeToday = 0;
                });
              }
            },
            icon: Icon(Icons.delete_forever),
            label: Text('مسح الكل', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade700, Colors.purple.shade300],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      'عدد الجلسات',
                      sessionsCount.toString(),
                      Icons.videogame_asset,
                      Colors.orange,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      'إجمالي الدخل',
                      incomeToday.toStringAsFixed(2),
                      Icons.attach_money,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _actionCard(
                      'إدارة الأجهزة',
                      Icons.videogame_asset,
                      Colors.blue,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ManageConsolesScreen(),
                          ),
                        );
                      },
                    ),
                    _actionCard(
                      'إدارة المشروبات',
                      Icons.local_drink,
                      Colors.teal,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ManageDrinksScreen(),
                          ),
                        );
                      },
                    ),
                    _actionCard(
                      'إدارة المستخدمين',
                      Icons.person,
                      Colors.red,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ManageUsersScreen(),
                          ),
                        );
                      },
                    ),
                    _actionCard('التقارير', Icons.bar_chart, Colors.amber, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ReportsScreen()),
                      );
                    }),
                  ],
                ),
              ),
              // إضافة زر لإضافة ترابيزات
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  color: Colors.blueAccent.withOpacity(0.1),
                  child: ListTile(
                    leading: Icon(
                      Icons.add,
                      color: Colors.blueAccent,
                      size: 32,
                    ),
                    title: Text(
                      'إضافة ترابيزات جديدة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final countCtrl = TextEditingController();
                        await showDialog(
                          context: context,
                          builder:
                              (_) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: Text(
                                  'عدد الترابيزات الجديدة',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                content: TextField(
                                  controller: countCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'أدخل العدد',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('إلغاء'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final count =
                                          int.tryParse(countCtrl.text) ?? 0;
                                      for (int i = 1; i <= count; i++) {
                                        await DBHelper.insertTable(
                                          'ترابيزة $i',
                                        );
                                      }
                                      Navigator.pop(context);
                                    },
                                    child: Text('إضافة'),
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        );
                      },
                      child: Text('إضافة'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, size: 30, color: color),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
                SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 6,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.7), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: Colors.white),
                SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
