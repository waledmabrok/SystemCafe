import 'package:flutter/material.dart';
import '../../db_helper.dart';
import '../../models.dart';
import 'DrinksInvoiceScreen.dart';
import 'add_drinks.dart';
import 'invoice_screen.dart';
import 'package:intl/intl.dart';

class PsScreen extends StatefulWidget {
  @override
  State<PsScreen> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<PsScreen> {
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
      appBar: AppBar(title: Text('اجهزه')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: consoles.length,
                itemBuilder: (_, i) {
                  final c = consoles[i];
                  final active = activeMap[c.id];

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // اسم الجهاز و السعر
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                c.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${c.pricePerHour.toStringAsFixed(2)} / ساعة',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),

                          // الحالة و الأزرار
                          active == null
                              ? Center(
                                child: ElevatedButton.icon(
                                  onPressed: () => _startSession(c),
                                  icon: Icon(Icons.play_arrow),
                                  label: Text('ابدأ الجلسة'),
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                ),
                              )
                              : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  ElevatedButton.icon(
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
                                    icon: Icon(Icons.local_drink),
                                    label: Text('مشروبات'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _endSession(active, c),
                                    icon: Icon(Icons.stop),
                                    label: Text('إنهاء الجلسة'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.receipt,
                                      color: Colors.deepPurple,
                                    ),
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
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            /*    Expanded(
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
            ),*/
          ],
        ),
      ),
    );
  }
}
