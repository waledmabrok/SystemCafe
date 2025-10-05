import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> initDB() async {
    if (_db != null) return _db!;
    String path = join(await getDatabasesPath(), 'xo_cafe2.db');
    /*await deleteDatabase(path);*/
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  static Future<Database> get database async {
    if (_db != null) return _db!;
    return await initDB();
  }

  static Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // جدول الترابيزات
      await db.execute('''
  CREATE TABLE tables (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    active_invoice_id INTEGER
  )
''');

      await db.execute('ALTER TABLE invoices ADD COLUMN staff_name TEXT');
    }
  }

  static Future _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      role TEXT CHECK(role IN ('admin','staff')) DEFAULT 'staff'
    )
  ''');
    await db.execute('''
      CREATE TABLE consoles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price_per_hour REAL NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE drinks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL
      )
    ''');
    await db.execute('''
    CREATE TABLE IF NOT EXISTS tables (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      active_invoice_id INTEGER
    )
  ''');
    await db.execute('''
  CREATE TABLE IF NOT EXISTS invoice_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    invoice_id INTEGER,
    drink_id INTEGER,
    qty INTEGER DEFAULT 1,
    total REAL NOT NULL
  )
''');
    await db.execute('''
    CREATE TABLE invoices (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      console_id INTEGER,
      start_time TEXT,
      end_time TEXT,
      device_cost REAL DEFAULT 0,
      drinks_cost REAL DEFAULT 0,
      total_cost REAL DEFAULT 0,
      staff_name TEXT
    )
  ''');

    /* await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        console_id INTEGER,
        start_time TEXT,
        end_time TEXT,
        device_cost REAL DEFAULT 0,
        drinks_cost REAL DEFAULT 0,
        total_cost REAL DEFAULT 0
      )
    ''');*/

    // seed
    await db.insert('users', {
      'username': 'admin',
      'password': '1234',
      'role': 'admin',
    });
    await db.insert('users', {
      'username': 'staff',
      'password': '1234',
      'role': 'staff',
    });
    await db.insert('consoles', {'name': 'PS4_1', 'price_per_hour': 20});
    await db.insert('consoles', {'name': 'PS4_2', 'price_per_hour': 25});
    await db.insert('drinks', {'name': 'Pepsi', 'price': 10});
    await db.insert('drinks', {'name': 'Coffee', 'price': 15});
  }

  // ---------- Users ----------
  static Future<Map<String, dynamic>?> getUser(
    String username,
    String password,
  ) async {
    final db = _db!;
    final res = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

  static Future<int> insertUser(Map<String, dynamic> user) async {
    return await _db!.insert('users', user);
  }

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    return await _db!.query('users');
  }

  // ---------- Consoles ----------
  static Future<int> insertConsole(ConsoleModel c) async {
    return await _db!.insert('consoles', c.toMap());
  }

  static Future<int> updateConsole(ConsoleModel c) async {
    return await _db!.update(
      'consoles',
      c.toMap(),
      where: 'id=?',
      whereArgs: [c.id],
    );
  }

  static Future<int> deleteConsole(int id) async {
    return await _db!.delete('consoles', where: 'id=?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> getAllConsoles() async {
    return await _db!.query('consoles');
  }

  // ---------- Drinks ----------
  static Future<int> insertDrink(DrinkModel d) async {
    return await _db!.insert('drinks', d.toMap());
  }

  static Future<int> updateDrink(DrinkModel d) async {
    return await _db!.update(
      'drinks',
      d.toMap(),
      where: 'id=?',
      whereArgs: [d.id],
    );
  }

  static Future<int> deleteDrink(int id) async {
    return await _db!.delete('drinks', where: 'id=?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> getAllDrinks() async {
    return await _db!.query('drinks');
  }

  // ---------- Invoices ----------
  static Future<int> createInvoice(int consoleId, String startTime) async {
    return await _db!.insert('invoices', {
      'console_id': consoleId,
      'start_time': startTime,
      'end_time': null,
      'device_cost': 0,
      'drinks_cost': 0,
      'total_cost': 0,
    });
  }

  static Future<int> endInvoice(
    int invoiceId,
    String endTime,
    double deviceCost,
    double drinksCost,
  ) async {
    final total = deviceCost + drinksCost;
    return await _db!.update(
      'invoices',
      {
        'end_time': endTime,
        'device_cost': deviceCost,
        'drinks_cost': drinksCost,
        'total_cost': total,
      },
      where: 'id=?',
      whereArgs: [invoiceId],
    );
  }

  static Future<List<Map<String, dynamic>>> getActiveInvoices() async {
    return await _db!.query('invoices', where: 'end_time IS NULL');
  }

  static Future<List<Map<String, dynamic>>> getAllInvoices() async {
    return await _db!.query('invoices');
  }

  // ---------- Invoice items ----------
  static Future<int> addInvoiceItem(
    int invoiceId,
    int drinkId,
    int qty,
    double total,
  ) async {
    final db = _db!;
    // تحقق لو المشروب موجود بالفعل
    final existing = await db.query(
      'invoice_items',
      where: 'invoice_id = ? AND drink_id = ?',
      whereArgs: [invoiceId, drinkId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final currentQty = existing.first['qty'] as int;
      final currentTotal = (existing.first['total'] as num).toDouble();
      final newQty = currentQty + qty;
      final newTotal = currentTotal + total;

      return await db.update(
        'invoice_items',
        {'qty': newQty, 'total': newTotal},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      return await db.insert('invoice_items', {
        'invoice_id': invoiceId,
        'drink_id': drinkId,
        'qty': qty,
        'total': total,
      });
    }
  }

  // داخل DBHelper
  static Future<void> deleteAllInvoices() async {
    final db = await DBHelper.database;
    await db.delete('invoices');
    await db.delete(
      'invoice_items',
    ); // لو عندك جدول للمشروبات المرتبطة بالفواتير
  }

  static Future<List<Map<String, dynamic>>> getItemsForInvoice(
    int invoiceId,
  ) async {
    return await _db!.rawQuery(
      '''
      SELECT ii.*, d.name as drink_name, d.price as drink_price
      FROM invoice_items ii
      LEFT JOIN drinks d ON d.id = ii.drink_id
      WHERE ii.invoice_id = ?
    ''',
      [invoiceId],
    );
  }

  static Future<int> updateInvoiceItemQty(
    int invoiceItemId,
    int newQty,
    double newTotal,
  ) async {
    return await _db!.update(
      'invoice_items',
      {'qty': newQty, 'total': newTotal},
      where: 'id = ?',
      whereArgs: [invoiceItemId],
    );
  }

  static Future<void> deleteInvoiceItem(int itemId) async {
    final db = await database; // افترض أن عندك getter اسمه database
    await db.delete(
      'invoice_items', // اسم جدول المشروبات في الفاتورة
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  static Future<void> clearAllData() async {
    final db = await DBHelper.database;

    // مسح كل الفواتير
    await db.delete('invoices');

    // مسح كل عناصر الفواتير
    await db.delete('invoice_items');

    // مسح كل الترابيزات أو إعادة تهيئتها
    await db.delete('tables');
  }

  // الحصول على كل الترابيزات
  static Future<List<Map<String, dynamic>>> getAllTables() async {
    return await _db!.query('tables');
  }

  // إضافة ترابيزة
  static Future<int> addTable(String name) async {
    return await _db!.insert('tables', {'name': name});
  }

  // تحديث حالة الجلسة (active_invoice_id)
  static Future<int> updateTableInvoice(int tableId, int? invoiceId) async {
    return await _db!.update(
      'tables',
      {'active_invoice_id': invoiceId},
      where: 'id=?',
      whereArgs: [tableId],
    );
  }

  static Future<int> insertTable(String name) async {
    return await _db!.insert('tables', {'name': name});
  }

  static Future<int> updateTableActiveInvoice(
    int tableId,
    int? invoiceId,
  ) async {
    return await _db!.update(
      'tables',
      {'active_invoice_id': invoiceId},
      where: 'id=?',
      whereArgs: [tableId],
    );
  }

  // ---------- Invoice items ----------

  static Future<double> getDrinksCostForInvoice(int invoiceId) async {
    final res = await _db!.rawQuery(
      'SELECT SUM(total) as s FROM invoice_items WHERE invoice_id = ?',
      [invoiceId],
    );
    if (res.isNotEmpty && res.first['s'] != null) {
      return (res.first['s'] as num).toDouble();
    }
    return 0.0;
  }
}
