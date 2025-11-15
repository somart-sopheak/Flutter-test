class Product {
  final int? id;
  final String name;
  final double price;
  final int stock;
  final DateTime? createdAt;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.createdAt,
  });

  Product copyWith({
    int? id,
    String? name,
    double? price,
    int? stock,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      // FIX: Changed 'id' to 'PRODUCTID'
      id:
          json['PRODUCTID'] is int
              ? json['PRODUCTID']
              : (json['PRODUCTID'] != null
                  ? int.parse(json['PRODUCTID'].toString())
                  : null),

      // FIX: Changed 'name' to 'PRODUCTNAME'
      name: json['PRODUCTNAME'] as String? ?? '',

      // FIX: Changed 'price' to 'PRICE'
      price:
          (json['PRICE'] is num)
              ? (json['PRICE'] as num).toDouble()
              : double.tryParse(json['PRICE'].toString()) ?? 0.0,

      // FIX: Changed 'stock' to 'STOCK'
      stock:
          (json['STOCK'] is int)
              ? json['STOCK'] as int
              : int.tryParse(json['STOCK'].toString()) ?? 0,
      // optional createdAt field - accept various formats
      createdAt:
          (() {
            final val =
                json['CREATED_AT'] ?? json['createdAt'] ?? json['created_at'];
            if (val == null) return null;
            if (val is DateTime) return val;
            try {
              return DateTime.parse(val.toString());
            } catch (_) {
              return null;
            }
          })(),
    );
  }

  Map<String, dynamic> toJson() {
    // This is already correct! Do not change it.
    // It sends lowercase keys, which our backend fixes now accept.
    final map = <String, dynamic>{'name': name, 'price': price, 'stock': stock};
    if (id != null) map['id'] = id;
    if (createdAt != null) map['createdAt'] = createdAt!.toIso8601String();
    return map;
  }
}
