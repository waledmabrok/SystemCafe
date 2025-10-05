import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../db_helper.dart';

class InvoiceScreen extends StatefulWidget {
  final int invoiceId;
  InvoiceScreen({required this.invoiceId});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  Map<String, dynamic>? invoice;
  List<Map<String, dynamic>> items = [];
  Map<int, TextEditingController> qtyControllers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await DBHelper.database;
    final dbInv = await db.query(
      'invoices',
      where: 'id=?',
      whereArgs: [widget.invoiceId],
      limit: 1,
    );

    final inv = dbInv.first;
    final its = await DBHelper.getItemsForInvoice(widget.invoiceId);

    // تحويل كل عنصر لنسخة قابلة للتعديل
    final editableItems = its.map((e) => Map<String, dynamic>.from(e)).toList();

    // إنشاء controllers لكل مشروب
    for (var it in editableItems) {
      qtyControllers[it['id'] as int] = TextEditingController(
        text: '${it['qty']}',
      );
    }

    setState(() {
      invoice = inv;
      items = editableItems;
    });
  }

  double get totalCost {
    double device = (invoice?['device_cost'] ?? 0).toDouble();
    double drinks = items.fold(
      0,
      (sum, it) => sum + ((it['total'] as num).toDouble()),
    );
    return device + drinks;
  }

  double totalDrinksCost = 0;
  void _removeItem(int itemId) async {
    // مسح من قاعدة البيانات
    await DBHelper.deleteInvoiceItem(itemId);

    // مسح من القائمة المحلية وتحديث المجموع
    setState(() {
      items.removeWhere((it) => it['id'] == itemId);
      totalDrinksCost = items.fold(
        0,
        (sum, it) => sum + (it['total'] as num).toDouble(),
      );
    });
  }

  void _updateItemQty(int itemId) {
    final controller = qtyControllers[itemId]!;
    int newQty = int.tryParse(controller.text) ?? 1;
    if (newQty < 1) newQty = 1;

    final index = items.indexWhere((it) => it['id'] == itemId);
    final itemCopy = Map<String, dynamic>.from(items[index]);
    final price = (itemCopy['drink_price'] as num).toDouble();
    itemCopy['qty'] = newQty;
    itemCopy['total'] = price * newQty;

    setState(() {
      items[index] = itemCopy;
    });

    // استخدم itemCopy مباشرة هنا
    DBHelper.updateInvoiceItemQty(
      itemId,
      newQty,
      (itemCopy['total'] as num).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = items.fold(
      0.0,
      (sum, it) => sum + (it['total'] as num).toDouble(),
    );
    if (invoice == null)
      return Scaffold(body: Center(child: CircularProgressIndicator()));

    final start =
        invoice!['start_time'] != null
            ? DateTime.parse(invoice!['start_time'])
            : null;
    final end =
        invoice!['end_time'] != null
            ? DateTime.parse(invoice!['end_time'])
            : null;
    final df = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(title: Text('فاتورة #${invoice!['id']}')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            ListTile(
              title: Text('Console ID'),
              trailing: Text('${invoice!['console_id']}'),
            ),
            ListTile(
              title: Text('Start'),
              trailing: Text(start != null ? df.format(start) : '-'),
            ),
            ListTile(
              title: Text('End'),
              trailing: Text(end != null ? df.format(end) : '-'),
            ),
            const Divider(),
            Text('المشروبات:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final it = items[i];
                  return ListTile(
                    title: Text('${it['drink_name']}'),
                    subtitle: Row(
                      children: [
                        Text('السعر: ${it['drink_price'].toStringAsFixed(2)}'),
                        SizedBox(width: 16),
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: qtyControllers[it['id']],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'كمية',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                            onChanged: (_) => _updateItemQty(it['id'] as int),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeItem(it['id'] as int),
                        ),
                      ],
                    ),
                    trailing: Text(
                      '${(it['total'] as num).toDouble().toStringAsFixed(2)}',
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              title: Text('تكلفة الجهاز'),
              trailing: Text(
                '${(invoice!['device_cost'] ?? 0).toStringAsFixed(2)}',
              ),
            ),
            ListTile(
              title: Text('تكلفة المشروبات'),
              trailing: Text(total.toStringAsFixed(2)),
            ),
            const Divider(thickness: 2),
            ListTile(
              tileColor: Colors.deepPurple.shade50,
              title: Text(
                'المجموع',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                totalCost.toStringAsFixed(2),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.deepPurple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
