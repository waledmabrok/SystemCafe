import 'package:flutter/material.dart';
import '../../db_helper.dart';

class ManageUsersScreen extends StatefulWidget {
  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await DBHelper.getAllUsers();
    setState(() => users = rows);
  }

  void _showForm({Map<String, dynamic>? edit}) {
    final userCtl = TextEditingController(text: edit?['username'] ?? '');
    final passCtl = TextEditingController(text: edit?['password'] ?? '');
    String role = edit?['role'] ?? 'staff';

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(edit == null ? 'إضافة مستخدم' : 'تعديل مستخدم'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: userCtl,
                  decoration: InputDecoration(labelText: 'اسم المستخدم'),
                ),
                TextField(
                  controller: passCtl,
                  decoration: InputDecoration(labelText: 'كلمة المرور'),
                ),
                DropdownButton<String>(
                  value: role,
                  items:
                      ['admin', 'staff']
                          .map(
                            (r) => DropdownMenuItem(value: r, child: Text(r)),
                          )
                          .toList(),
                  onChanged: (v) {
                    if (v != null) role = v;
                  },
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
                  final u = userCtl.text.trim();
                  final p = passCtl.text.trim();
                  if (edit == null) {
                    await DBHelper.insertUser({
                      'username': u,
                      'password': p,
                      'role': role,
                    });
                  } else {
                    // update not implemented fully (simple approach: delete+insert)
                    final db =
                        await DBHelper.database; // <-- getter اللي عملناه
                    await db.update(
                      'users',
                      {'password': p, 'role': role},
                      where: 'id=?',
                      whereArgs: [edit['id']],
                    );
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
      appBar: AppBar(title: Text('إدارة المستخدمين')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (_, i) {
                final u = users[i];
                return ListTile(
                  title: Text(u['username']),
                  subtitle: Text('الدور: ${u['role']}'),
                  trailing: IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _showForm(edit: u),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () => _showForm(),
              icon: Icon(Icons.add),
              label: Text('إضافة مستخدم'),
            ),
          ),
        ],
      ),
    );
  }
}
