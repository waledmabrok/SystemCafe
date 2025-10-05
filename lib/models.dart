class ConsoleModel {
  int? id;
  String name;
  double pricePerHour;

  ConsoleModel({this.id, required this.name, required this.pricePerHour});

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'price_per_hour': pricePerHour,
  };

  factory ConsoleModel.fromMap(Map<String, dynamic> m) => ConsoleModel(
    id: m['id'],
    name: m['name'],
    pricePerHour: (m['price_per_hour'] as num).toDouble(),
  );
}

class DrinkModel {
  int? id;
  String name;
  double price;

  DrinkModel({this.id, required this.name, required this.price});

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'price': price,
  };

  factory DrinkModel.fromMap(Map<String, dynamic> m) => DrinkModel(
    id: m['id'],
    name: m['name'],
    price: (m['price'] as num).toDouble(),
  );
}
