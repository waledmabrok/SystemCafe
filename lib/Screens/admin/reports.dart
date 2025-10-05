import 'package:flutter/material.dart';
import '../../db_helper.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Map<String, dynamic>> invoices = [];
  Map<int, List<Map<String, dynamic>>> invoiceItems = {};
  double totalIncome = 0;
  final formatter = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final inv = await DBHelper.getAllInvoices();
    double sum = 0;
    Map<int, List<Map<String, dynamic>>> itemsMap = {};

    for (final i in inv) {
      sum += ((i['total_cost'] ?? 0) as num).toDouble();
      final items = await DBHelper.getItemsForInvoice(i['id']);
      itemsMap[i['id']] = items;
    }

    setState(() {
      invoices = inv;
      invoiceItems = itemsMap;
      totalIncome = sum;
    });
  }

  Future<void> _deleteAllInvoices() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('تأكيد حذف الكل'),
            content: Text('هل أنت متأكد من مسح جميع الفواتير؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('حذف'),
              ),
            ],
          ),
    );
    if (confirm == true) {
      await DBHelper.deleteAllInvoices();
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تقارير مفصلة'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_forever),
            onPressed: _deleteAllInvoices,
            tooltip: 'مسح الكل',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.deepPurple.shade50,
              child: ListTile(
                title: Text(
                  'إجمالي الدخل',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  '${formatter.format(totalIncome)}',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: invoices.length,
                itemBuilder: (_, i) {
                  final inv = invoices[i];
                  final start = DateTime.parse(inv['start_time']);
                  final end =
                      inv['end_time'] != null
                          ? DateTime.parse(inv['end_time'])
                          : null;

                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      title: Text('فاتورة رقم: ${inv['id']}'),
                      subtitle: Text(
                        'الإجمالي: ${formatter.format(inv['total_cost'] ?? 0)}',
                      ),
                      children: [
                        Text(
                          'كونسول: ${inv['console_name'] ?? inv['console_id']}',
                        ),
                        Text(
                          'وقت البداية: ${DateFormat('yyyy-MM-dd HH:mm').format(start)}',
                        ),
                        Text(
                          'وقت النهاية: ${end != null ? DateFormat('yyyy-MM-dd HH:mm').format(end) : "جاري"}',
                        ),
                        Text(
                          'تكلفة الكونسول: ${formatter.format(inv['device_cost'] ?? 0)}',
                        ),
                        Text(
                          'تكلفة المشروبات: ${formatter.format(inv['drinks_cost'] ?? 0)}',
                        ),
                        Divider(),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: DBHelper.getItemsForInvoice(inv['id']),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData)
                              return CircularProgressIndicator();
                            final items = snapshot.data!;
                            if (items.isEmpty) return Text('لا توجد مشروبات');
                            return Column(
                              children:
                                  items
                                      .map(
                                        (item) => ListTile(
                                          title: Text(
                                            '${item['drink_name']} x${item['qty']}',
                                          ),
                                          trailing: Text(
                                            '${item['total'].toStringAsFixed(2)}',
                                          ),
                                        ),
                                      )
                                      .toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
