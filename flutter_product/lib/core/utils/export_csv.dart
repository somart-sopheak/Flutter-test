import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter_product/models/product.dart';
import 'package:path_provider/path_provider.dart';


class ExportCsv {
  static Future<String> save(List<Product> items) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/products_${DateTime.now().millisecondsSinceEpoch}.csv';

    final rows = [
      ['ID', 'Name', 'Price', 'Stock', 'CreatedAt'],
      ...items.map((p) => [
            p.id,
            p.name,
            p.price.toStringAsFixed(2),
            p.stock,
            p.createdAt?.toIso8601String() ?? '',
          ])
    ];

    final csv = const ListToCsvConverter().convert(rows);
    await File(path).writeAsString(csv);
    return path;
  }
}
