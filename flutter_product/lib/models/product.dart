class Product {
  final int? id;
  final String name;
  final double price;
  final int stock;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.stock,
  });

  Product copyWith({int? id, String? name, double? price, int? stock}) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      // FIX: Changed 'id' to 'PRODUCTID'
      id: json['PRODUCTID'] is int
          ? json['PRODUCTID']
          : (json['PRODUCTID'] != null
                ? int.parse(json['PRODUCTID'].toString())
                : null),

      // FIX: Changed 'name' to 'PRODUCTNAME'
      name: json['PRODUCTNAME'] as String? ?? '',

      // FIX: Changed 'price' to 'PRICE'
      price: (json['PRICE'] is num)
          ? (json['PRICE'] as num).toDouble()
          : double.tryParse(json['PRICE'].toString()) ?? 0.0,

      // FIX: Changed 'stock' to 'STOCK'
      stock: (json['STOCK'] is int)
          ? json['STOCK'] as int
          : int.tryParse(json['STOCK'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    // This is already correct! Do not change it.
    // It sends lowercase keys, which our backend fixes now accept.
    final map = <String, dynamic>{'name': name, 'price': price, 'stock': stock};
    if (id != null) map['id'] = id;
    return map;
  }
}
