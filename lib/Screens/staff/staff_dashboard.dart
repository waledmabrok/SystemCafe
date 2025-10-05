import 'package:flutter/material.dart';
import '../../db_helper.dart';
import '../../models.dart';
import 'DrinksInvoiceScreen.dart';
import 'DrinksScreen.dart';
import 'PS_Screen.dart';
import 'add_drinks.dart';
import 'invoice_screen.dart';
import 'package:intl/intl.dart';

class StaffDashboard extends StatefulWidget {
  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  List<ConsoleModel> consoles = [];
  List<Map<String, dynamic>> activeInvoices = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cs = await DBHelper.getAllConsoles();
    final inv = await DBHelper.getActiveInvoices();
    setState(() {
      consoles = cs.map((r) => ConsoleModel.fromMap(r)).toList();
      activeInvoices = inv;
    });
  }

  Future<void> _startSession(ConsoleModel c) async {
    final now = DateTime.now().toIso8601String();
    await DBHelper.createInvoice(c.id!, now);
    await _load();
  }

  Future<void> _endSession(Map<String, dynamic> invoice, ConsoleModel c) async {
    final end = DateTime.now();
    final start = DateTime.parse(invoice['start_time']);
    final duration = end.difference(start).inSeconds / 3600.0; // ساعات
    final deviceCost = duration * c.pricePerHour;
    final drinksCost = await DBHelper.getDrinksCostForInvoice(
      invoice['id'] as int,
    );
    final total = deviceCost + drinksCost;

    await DBHelper.endInvoice(
      invoice['id'] as int,
      end.toIso8601String(),
      deviceCost,
      drinksCost,
    );

    await _load();

    // عرض شاشة الفاتورة
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('الفاتورة النهائية'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الكونسول: ${c.name}'),
                Text('وقت الاستخدام: ${duration.toStringAsFixed(2)} ساعة'),
                Text('تكلفة الكونسول: ${deviceCost.toStringAsFixed(2)}'),
                Text('تكلفة المشروبات: ${drinksCost.toStringAsFixed(2)}'),
                Divider(),
                Text(
                  'الإجمالي: ${total.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('حسناً'),
              ),
            ],
          ),
    );
  }

  Map<int, Map<String, dynamic>> _activeMap() {
    final m = <int, Map<String, dynamic>>{};
    for (final inv in activeInvoices) {
      m[inv['console_id'] as int] = inv;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final activeMap = _activeMap();
    return Scaffold(
      appBar: AppBar(title: Text('الكاشير')),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Container للجلسات/بلايستيشن
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PsScreen()),
                );
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue[300],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.videogame_asset, size: 50, color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'الجلسات / البلايستيشن',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Container للمشروبات
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DrinksscreenDashboard()),
                  // ممكن تغير invoiceId حسب الفاتورة الحالية
                );
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange[300],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.local_drink, size: 50, color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'المشروبات',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      /*RefreshIndicator(
        onRefresh: _load,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: consoles.length,
                itemBuilder: (_, i) {
                  final c = consoles[i];
                  final active = activeMap[c.id];
                  return ListTile(
                    title: Text(c.name),
                    subtitle: Text(
                      'سعر الساعة: ${c.pricePerHour.toStringAsFixed(2)}',
                    ),
                    trailing:
                        active == null
                            ? ElevatedButton(
                              onPressed: () => _startSession(c),
                              child: Text('Start'),
                            )
                            : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => AddDrinksScreen(
                                              invoiceId: active['id'] as int,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Text('Add Drink'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _endSession(active, c),
                                  child: Text('End'),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.receipt),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => InvoiceScreen(
                                              invoiceId: active['id'] as int,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                  );
                },
              ),
            ),
            Expanded(
              child: FutureBuilder(
                future: DBHelper.getAllTables(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();
                  final tables = snapshot.data as List<Map<String, dynamic>>;
                  return ListView.builder(
                    itemCount: tables.length,
                    itemBuilder: (_, i) {
                      final t = tables[i];
                      final activeInvoice = t['active_invoice_id'];
                      return Card(
                        child: ListTile(
                          title: Text(t['name']),
                          subtitle: Text(
                            activeInvoice != null ? 'جاري الآن' : 'فارغة',
                          ),
                          trailing:
                              activeInvoice == null
                                  ? ElevatedButton(
                                    child: Text('فتح جلسة'),
                                    onPressed: () async {
                                      final cashierNameCtrl =
                                          TextEditingController();
                                      await showDialog(
                                        context: context,
                                        builder:
                                            (_) => AlertDialog(
                                              title: Text('اسم الكاشير'),
                                              content: TextField(
                                                controller: cashierNameCtrl,
                                                decoration: InputDecoration(
                                                  labelText: 'اسم الكاشير',
                                                ),
                                              ),
                                              actions: [
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    if (cashierNameCtrl
                                                        .text
                                                        .isNotEmpty) {
                                                      final now =
                                                          DateTime.now()
                                                              .toIso8601String();
                                                      final invoiceId =
                                                          await DBHelper.createInvoice(
                                                            0, // ترابيزات مش consoles
                                                            now,
                                                          );
                                                      await DBHelper.updateTableInvoice(
                                                        t['id'],
                                                        invoiceId,
                                                      );
                                                      Navigator.pop(context);
                                                      setState(() {});
                                                    }
                                                  },
                                                  child: Text('ابدأ'),
                                                ),
                                              ],
                                            ),
                                      );
                                    },
                                  )
                                  : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton(
                                        child: Text('إضافة مشروبات'),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => AddDrinksScreen(
                                                    invoiceId: activeInvoice,
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                      SizedBox(width: 8),
                                      ElevatedButton(
                                        child: Text('إغلاق الجلسة'),
                                        onPressed: () async {
                                          final invoice =
                                              await DBHelper.getAllInvoices(); // أو طريقة لجلب الفاتورة
                                          await DBHelper.endInvoice(
                                            activeInvoice,
                                            DateTime.now().toIso8601String(),
                                            0,
                                            await DBHelper.getDrinksCostForInvoice(
                                              activeInvoice,
                                            ),
                                          );
                                          await DBHelper.updateTableInvoice(
                                            t['id'],
                                            null,
                                          );
                                          setState(() {});
                                        },
                                      ),
                                      SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(Icons.receipt),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => DrinksInvoiceScreen(
                                                    invoiceId: activeInvoice,
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    */
    );
  }
}
