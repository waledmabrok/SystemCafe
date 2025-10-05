import 'dart:convert';

import 'package:flutter/material.dart';
import '../../db_helper.dart';
import 'DrinksInvoiceScreen.dart';
import 'add_drinks.dart';

import 'package:intl/intl.dart';

class DrinksscreenDashboard extends StatefulWidget {
  @override
  State<DrinksscreenDashboard> createState() => _DrinksscreenDashboardState();
}

class _DrinksscreenDashboardState extends State<DrinksscreenDashboard> {
  List<Map<String, dynamic>> tables = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tbls = await DBHelper.getAllTables();
    final invs = await DBHelper.getAllInvoices();

    // ربط الترابيزات بالفواتير الجارية
    final tablesWithNames =
        tbls.map((t) {
          final activeInvoiceId = t['active_invoice_id'];
          String displayName = t['name'];
          if (activeInvoiceId != null) {
            final invoice = invs.firstWhere(
              (i) => i['id'] == activeInvoiceId,
              orElse: () => {},
            );
            displayName = invoice['staff_name'] ?? t['name'];
          }
          return {...t, 'displayName': displayName};
        }).toList();

    setState(() {
      tables = tablesWithNames;
    });
  }

  Future<void> _startSession(Map<String, dynamic> table) async {
    final customerNameCtrl = TextEditingController();
    final customerName = await showDialog<String>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('اسم العميل'),
            content: TextField(
              controller: customerNameCtrl,
              decoration: InputDecoration(labelText: 'ادخل اسم العميل'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, customerNameCtrl.text),
                child: Text('ابدأ'),
              ),
            ],
          ),
    );

    if (customerName == null || customerName.isEmpty) return;

    final now = DateTime.now().toIso8601String();
    final invoiceId = await DBHelper.createInvoice(0, now); // 0 للترابيزات
    await DBHelper.updateTableInvoice(table['id'], invoiceId);

    // تحديث اسم العميل في الفاتورة
    final db = await DBHelper.database;
    await db.update(
      'invoices',
      {'staff_name': customerName}, // يمكن إعادة تسميتها customer_name
      where: 'id=?',
      whereArgs: [invoiceId],
    );

    _load();
  }

  Future<void> _endSession(Map<String, dynamic> table) async {
    final invoiceId = table['active_invoice_id'];
    if (invoiceId == null) return;

    final invoice = (await DBHelper.getAllInvoices()).firstWhere(
      (i) => i['id'] == invoiceId,
    );

    final start = DateTime.parse(invoice['start_time']);
    final end = DateTime.now();
    final duration = end.difference(start).inSeconds / 3600.0;

    final drinksCost = await DBHelper.getDrinksCostForInvoice(
      invoiceId,
    ); // سعر المشروبات
    final deviceCost = 0; // الترابيزات مش محسوبة وقت
    final total = drinksCost + deviceCost;

    // Dialog تأكيد الدفع
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('تأكيد إغلاق الجلسة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('تكلفة المشروبات: ${drinksCost.toStringAsFixed(2)}'),
                Divider(),
                Text(
                  'الإجمالي: ${total.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
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

    if (confirm != true) return;

    await DBHelper.endInvoice(
      invoiceId,
      end.toIso8601String(),
      deviceCost.toDouble(),
      drinksCost,
    );
    await DBHelper.updateTableInvoice(table['id'], null);
    _load();
  }

  String _searchQuery = '';

  List<Map<String, dynamic>> get filteredTables {
    if (_searchQuery.isEmpty) return tables;
    return tables.where((t) {
      final name = (t['displayName'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery);
    }).toList();
  }

  // لتفريغ كل الترابيزات
  Future<void> _clearAllTables() async {
    for (final t in tables) {
      if (t['active_invoice_id'] != null) {
        await DBHelper.endInvoice(
          t['active_invoice_id'],
          DateTime.now().toIso8601String(),
          0,
          await DBHelper.getDrinksCostForInvoice(t['active_invoice_id']),
        );
        await DBHelper.updateTableInvoice(t['id'], null);
      }
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('لوحة الموظف')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'ابحث عن الترابيزة أو العميل...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.blueAccent,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(width: 10),
                /*Container(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 4,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: _clearAllTables,
                    icon: Icon(Icons.delete_forever),
                    label: Text('تفريغ الكل'),
                  ),
                ),*/
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: GridView.builder(
                padding: EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 5 / 2,
                ),
                itemCount: filteredTables.length,
                itemBuilder: (_, i) {
                  final t = filteredTables[i];
                  final activeInvoice = t['active_invoice_id'];

                  return Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color:
                        activeInvoice != null
                            ? Colors.green[100]
                            : Colors.grey[200],
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            t['displayName'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(activeInvoice != null ? 'محجوزه' : 'فارغة'),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              if (activeInvoice == null)
                                ElevatedButton(
                                  onPressed: () => _startSession(t),
                                  child: Text('فتح'),
                                ),
                              if (activeInvoice != null) ...[
                                IconButton(
                                  icon: Icon(Icons.local_drink),
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
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.red),
                                  onPressed: () => _endSession(t),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
