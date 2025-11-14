import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = 'http://10.0.2.2:3000/api'});
  // For Android emulator use 10.0.2.2 instead of localhost

  Future<List<Product>> fetchProducts() async {
    final res = await http.get(Uri.parse('$baseUrl/products'));

    if (res.statusCode == 200) {
      final body = json.decode(res.body);

      // Backend returns: { success: true, data: [...] }
      final List<dynamic> data = body['data'];

      return data.map((e) => Product.fromJson(e)).toList();
    }

    throw Exception('Failed to load products: ${res.statusCode}');
  }

  Future<Product> createProduct(Product p) async {
    final res = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(p.toJson()),
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      final body = json.decode(res.body);
      return Product.fromJson(body['data']);
    }

    throw Exception('Failed to create product: ${res.statusCode}');
  }

  Future<Product> updateProduct(Product p) async {
    if (p.id == null) throw Exception('Product id required to update');

    final res = await http.put(
      Uri.parse('$baseUrl/products/${p.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(p.toJson()),
    );

    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      return Product.fromJson(body['data']);
    }

    throw Exception('Failed to update product: ${res.statusCode}');
  }

  Future<void> deleteProduct(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/products/$id'));

    if (res.statusCode == 200 || res.statusCode == 204) return;

    throw Exception('Failed to delete product: ${res.statusCode}');
  }
}