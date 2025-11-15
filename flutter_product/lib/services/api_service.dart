// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../providers/product_provider.dart'; // Import for SortBy

class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = 'http://10.0.2.2:3000/api'});
  // For Android emulator use 10.0.2.2 instead of localhost

  /// Helper to build query parameters
  Map<String, String> _buildQueryParams({
    String searchTerm = '',
    SortBy sortBy = SortBy.none,
    bool sortAsc = true,
    double? priceMin,
    double? priceMax,
    int? stockMin,
    int? stockMax,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    final params = <String, String>{};

    if (searchTerm.isNotEmpty) {
      params['q'] = searchTerm;
    }
    if (sortBy != SortBy.none) {
      params['sortBy'] = sortBy.name; // 'price' or 'stock'
      params['sortOrder'] = sortAsc ? 'ASC' : 'DESC';
    }
    if (priceMin != null) {
      params['priceMin'] = priceMin.toString();
    }
    if (priceMax != null) {
      params['priceMax'] = priceMax.toString();
    }
    if (stockMin != null) {
      params['stockMin'] = stockMin.toString();
    }
    if (stockMax != null) {
      params['stockMax'] = stockMax.toString();
    }
    if (dateFrom != null) {
      params['dateFrom'] = dateFrom.toIso8601String();
    }
    if (dateTo != null) {
      params['dateTo'] = dateTo.toIso8601String();
    }
    return params;
  }

  /// Fetches a single page of products from the API
  Future<Map<String, dynamic>> fetchProductsPage({
    required int page,
    required int limit,
    String searchTerm = '',
    SortBy sortBy = SortBy.none,
    bool sortAsc = true,
    double? priceMin,
    double? priceMax,
    int? stockMin,
    int? stockMax,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final params = _buildQueryParams(
      searchTerm: searchTerm,
      sortBy: sortBy,
      sortAsc: sortAsc,
      priceMin: priceMin,
      priceMax: priceMax,
      stockMin: stockMin,
      stockMax: stockMax,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );

    // Add pagination params
    params['page'] = page.toString();
    params['limit'] = limit.toString();

    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: params);
    
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      return body as Map<String, dynamic>; // Returns { success, data, pagination }
    }

    throw Exception('Failed to load products page: ${res.statusCode}');
  }

  /// Fetches ALL products that match the filters (for export)
  Future<List<Product>> fetchAllProductsForExport({
    String searchTerm = '',
    SortBy sortBy = SortBy.none,
    bool sortAsc = true,
    double? priceMin,
    double? priceMax,
    int? stockMin,
    int? stockMax,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final params = _buildQueryParams(
      searchTerm: searchTerm,
      sortBy: sortBy,
      sortAsc: sortAsc,
      priceMin: priceMin,
      priceMax: priceMax,
      stockMin: stockMin,
      stockMax: stockMax,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );

    // Add the 'all=1' parameter to get all results
    params['all'] = '1';

    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: params);
    
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      final List<dynamic> data = body['data'];
      return data.map((e) => Product.fromJson(e)).toList();
    }

    throw Exception('Failed to load all products for export: ${res.statusCode}');
  }

  // This method is now obsolete for the list screen, but we leave it
  // in case other parts of the app use it.
  Future<List<Product>> fetchProducts() async {
    // Note: This will now only fetch the first page (defaulting to 5 items)
    // To fix this, you could add a high limit:
    final res = await http.get(Uri.parse('$baseUrl/products?limit=1000'));

    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      final List<dynamic> data = body['data'];
      return data.map((e) => Product.fromJson(e)).toList();
    }

    throw Exception('Failed to load products: ${res.statusCode}');
  }

  // ... (keep createProduct, updateProduct, deleteProduct)
  // ... (These methods are unchanged)

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
    final res = await http.delete(Uri.parse('$baseUrl/products/${id}'));

    if (res.statusCode == 200 || res.statusCode == 204) return;

    throw Exception('Failed to delete product: ${res.statusCode}');
  }
}