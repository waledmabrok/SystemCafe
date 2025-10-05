import 'package:flutter/material.dart';
import '../../db_helper.dart';
import '../../models.dart';

class AddDrinksScreen extends StatefulWidget {
  final int invoiceId;
  AddDrinksScreen({required this.invoiceId});

  @override
  State<AddDrinksScreen> createState() => _AddDrinksScreenState();
}

class _AddDrinksScreenState extends State<AddDrinksScreen> {
  List<DrinkModel> drinks = [];
  Map<int, int> qtyMap = {}; // لتخزين كمية كل مشروب قبل الإضافة

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await DBHelper.getAllDrinks();
    setState(() {
      drinks = rows.map((r) => DrinkModel.fromMap(r)).toList();
      for (var d in drinks) qtyMap[d.id!] = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('إضافة مشروبات')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child:
            drinks.isEmpty
                ? Center(child: Text('لا توجد مشروبات'))
                : ListView.builder(
                  itemCount: drinks.length,
                  itemBuilder: (_, i) {
                    final d = drinks[i];
                    final qty = qtyMap[d.id!]!;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 4,
                      ),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'السعر: ${d.price.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    if (qty > 1)
                                      setState(() => qtyMap[d.id!] = qty - 1);
                                  },
                                ),
                                Text(
                                  qty.toString(),
                                  style: TextStyle(fontSize: 16),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add_circle_outline),
                                  onPressed:
                                      () => setState(
                                        () => qtyMap[d.id!] = qty + 1,
                                      ),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    await DBHelper.addInvoiceItem(
                                      widget.invoiceId,
                                      d.id!,
                                      qty,
                                      d.price * qty,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('تمت الإضافة')),
                                    );
                                  },
                                  child: Text('أضف'),
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
    );
  }
}
