import 'package:flutter/material.dart';
import '../../db_helper.dart';
import '../../models.dart';

class ManageDrinksScreen extends StatefulWidget {
  @override
  State<ManageDrinksScreen> createState() => _ManageDrinksScreenState();
}

class _ManageDrinksScreenState extends State<ManageDrinksScreen> {
  List<DrinkModel> drinks = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await DBHelper.getAllDrinks();
    setState(() => drinks = rows.map((r) => DrinkModel.fromMap(r)).toList());
  }

  void _showForm({DrinkModel? edit}) {
    final nameCtl = TextEditingController(text: edit?.name ?? '');
    final priceCtl = TextEditingController(
      text: edit != null ? edit.price.toString() : '',
    );
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(edit == null ? 'إضافة مشروب' : 'تعديل مشروب'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtl,
                  decoration: InputDecoration(labelText: 'اسم المشروب'),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: priceCtl,
                  decoration: InputDecoration(labelText: 'السعر'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final n = nameCtl.text.trim();
                  final p = double.tryParse(priceCtl.text.trim()) ?? 0;
                  if (edit == null) {
                    await DBHelper.insertDrink(DrinkModel(name: n, price: p));
                  } else {
                    edit.name = n;
                    edit.price = p;
                    await DBHelper.updateDrink(edit);
                  }
                  Navigator.pop(context);
                  _load();
                },
                child: Text('حفظ'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('إدارة المشروبات')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            drinks.isEmpty
                ? Center(
                  child: Text(
                    'لا توجد مشروبات حالياً',
                    style: TextStyle(fontSize: 16),
                  ),
                )
                : ListView.builder(
                  itemCount: drinks.length,
                  itemBuilder: (_, i) {
                    final c = drinks[i];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent.withOpacity(0.2),
                          child: Text(
                            c.name[0].toUpperCase(),
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          c.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'السعر: ${c.price.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 14),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: Colors.orangeAccent,
                              ),
                              onPressed: () => _showForm(edit: c),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () async {
                                await DBHelper.deleteDrink(c.id!);
                                _load();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        label: Text('إضافة مشروب'),
        icon: Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }
}
