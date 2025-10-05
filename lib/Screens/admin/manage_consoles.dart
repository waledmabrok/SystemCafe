import 'package:flutter/material.dart';
import '../../db_helper.dart';
import '../../models.dart';

class ManageConsolesScreen extends StatefulWidget {
  @override
  State<ManageConsolesScreen> createState() => _ManageConsolesScreenState();
}

class _ManageConsolesScreenState extends State<ManageConsolesScreen> {
  List<ConsoleModel> consoles = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await DBHelper.getAllConsoles();
    setState(() => consoles = rows.map((r) => ConsoleModel.fromMap(r)).toList());
  }

  void _showForm({ConsoleModel? edit}) {
    final nameCtl = TextEditingController(text: edit?.name ?? '');
    final priceCtl = TextEditingController(text: edit != null ? edit.pricePerHour.toString() : '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(edit == null ? 'إضافة جهاز' : 'تعديل جهاز'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtl, decoration: InputDecoration(labelText: 'اسم الجهاز')),
          TextField(controller: priceCtl, decoration: InputDecoration(labelText: 'سعر الساعة'), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء')),
          ElevatedButton(
              onPressed: () async {
                final n = nameCtl.text.trim();
                final p = double.tryParse(priceCtl.text.trim()) ?? 0;
                if (edit == null) {
                  await DBHelper.insertConsole(ConsoleModel(name: n, pricePerHour: p));
                } else {
                  edit.name = n;
                  edit.pricePerHour = p;
                  await DBHelper.updateConsole(edit);
                }
                Navigator.pop(context);
                _load();
              },
              child: Text('حفظ'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('إدارة الأجهزة')),
        body: Column(
          children: [
            Expanded(
                child: ListView.builder(
                  itemCount: consoles.length,
                  itemBuilder: (_, i) {
                    final c = consoles[i];
                    return ListTile(
                      title: Text(c.name),
                      subtitle: Text('سعر الساعة: ${c.pricePerHour.toStringAsFixed(2)}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: Icon(Icons.edit), onPressed: () => _showForm(edit: c)),
                        IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () async {
                              await DBHelper.deleteConsole(c.id!);
                              _load();
                            })
                      ]),
                    );
                  },
                )),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(onPressed: () => _showForm(), icon: Icon(Icons.add), label: Text('إضافة جهاز')),
            )
          ],
        ));
  }
}
