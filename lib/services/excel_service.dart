import 'dart:io';
import 'package:excel/excel.dart';
import '../models/product.dart';

class ExcelService {
  Future<List<Product>> readProductsFromExcel(File file) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final List<Product> products = [];

    for (var table in excel.tables.keys) {
      final rows = excel.tables[table]!.rows;
      // Skip header row
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row[0]?.value == null) continue;

        try {
          final product = Product(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: row[0]?.value.toString() ?? '',
            description: row[1]?.value.toString() ?? '',
            price: double.tryParse(row[2]?.value.toString() ?? '0') ?? 0.0,
            imageUrl: row[3]?.value.toString() ?? '',
            stock: int.tryParse(row[4]?.value.toString() ?? '0') ?? 0,
            category: row[5]?.value.toString() ?? '',
            createdAt: DateTime.now(),
          );
          products.add(product);
        } catch (e) {
          print('Error parsing row $i: $e');
          continue;
        }
      }
    }

    return products;
  }

  Future<File> createProductsExcel(List<Product> products) async {
    final excel = Excel.createExcel();
    final sheet = excel.sheets.values.first;

    // Add headers
    sheet.appendRow([
      'Name',
      'Description',
      'Price',
      'Image URL',
      'Stock',
      'Category',
    ]);

    // Add products
    for (var product in products) {
      sheet.appendRow([
        product.name,
        product.description,
        product.price.toString(),
        product.imageUrl,
        product.stock.toString(),
        product.category,
      ]);
    }

    // Save the file
    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Failed to encode Excel file');
    }

    final file = File('products_export_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    await file.writeAsBytes(bytes);
    return file;
  }
} 