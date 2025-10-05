import 'package:flutter/material.dart';
import '../../db_helper.dart';

class DrinksInvoiceScreen extends StatefulWidget {
  final int invoiceId;
  DrinksInvoiceScreen({required this.invoiceId});

  @override
  State<DrinksInvoiceScreen> createState() => _DrinksInvoiceScreenState();
}

class _DrinksInvoiceScreenState extends State<DrinksInvoiceScreen> {
  List<Map<String, dynamic>> items = [];
  double totalDrinksCost = 0;
  final Map<int, TextEditingController> qtyControllers = {};

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    qtyControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadItems() async {
    final its = await DBHelper.getItemsForInvoice(widget.invoiceId);
    items = its.map((e) => Map<String, dynamic>.from(e)).toList();

    totalDrinksCost = items.fold(
      0,
      (sum, it) => sum + (it['total'] as num).toDouble(),
    );

    // إنشاء الـ controllers مرة واحدة فقط
    qtyControllers.clear();
    for (var it in items) {
      qtyControllers[it['id'] as int] = TextEditingController(
        text: it['qty'].toString(),
      );
    }

    setState(() {});
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
      totalDrinksCost = items.fold(
        0,
        (sum, it) => sum + (it['total'] as num).toDouble(),
      );
    });

    DBHelper.updateInvoiceItemQty(
      itemId,
      newQty,
      (itemCopy['total'] as num).toDouble(),
    );
  }

  void _removeItem(int itemId) async {
    await DBHelper.deleteInvoiceItem(itemId);
    setState(() {
      items.removeWhere((it) => it['id'] == itemId);
      qtyControllers[itemId]?.dispose();
      qtyControllers.remove(itemId);
      totalDrinksCost = items.fold(
        0,
        (sum, it) => sum + (it['total'] as num).toDouble(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مشروبات الفاتورة #${widget.invoiceId}'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child:
                  items.isEmpty
                      ? Center(
                        child: Text(
                          'لا توجد مشروبات',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                      : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final it = items[i];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    it['drink_name'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 60,
                                    child: TextField(
                                      controller: qtyControllers[it['id']],
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'كمية',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                      onChanged:
                                          (_) =>
                                              _updateItemQty(it['id'] as int),
                                    ),
                                  ),
                                  Text(
                                    '${(it['total'] as num).toDouble().toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed:
                                        () => _removeItem(it['id'] as int),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.deepPurple[50],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الإجمالي',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    totalDrinksCost.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
