import 'dart:io';
import 'package:flutter_product/models/product.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';


class ExportPdf {
  static Future<String> save(List<Product> items) async {
    final doc = PdfDocument();
    final grid = PdfGrid()..columns.add(count: 4);

    grid.headers.add(1);
    final header = grid.headers[0];
    header.cells[0].value = 'ID';
    header.cells[1].value = 'Name';
    header.cells[2].value = 'Price';
    header.cells[3].value = 'Stock';

    for (var item in items) {
      final row = grid.rows.add();
      row.cells[0].value = item.id.toString();
      row.cells[1].value = item.name;
      row.cells[2].value = '\$${item.price.toStringAsFixed(2)}';
      row.cells[3].value = item.stock.toString();
    }

    final page = doc.pages.add();
    grid.draw(page: page);

    final bytes = await doc.save();
    doc.dispose();

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/products_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await File(path).writeAsBytes(bytes);

    return path;
  }
}
