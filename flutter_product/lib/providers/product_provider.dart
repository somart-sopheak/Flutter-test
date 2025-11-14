import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService api;
  List<Product> _products = [];
  bool loading = false;
  String? error;
  String searchTerm = '';

  ProductProvider({ApiService? apiService}) : api = apiService ?? ApiService();

  List<Product> get products => _products;
  List<Product> get filteredProducts {
    if (searchTerm.isEmpty) return _products;
    final term = searchTerm.toLowerCase();
    return _products.where((p) => p.name.toLowerCase().contains(term)).toList();
  }

  Future<void> fetchProducts() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      _products = await api.fetchProducts();
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> addProduct(Product p) async {
    loading = true;
    notifyListeners();
    try {
      final created = await api.createProduct(p);
      _products.insert(0, created);
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(Product p) async {
    loading = true;
    notifyListeners();
    try {
      final updated = await api.updateProduct(p);
      final idx = _products.indexWhere((e) => e.id == updated.id);
      if (idx >= 0) _products[idx] = updated;
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    loading = true;
    notifyListeners();
    try {
      await api.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }

  void setSearchTerm(String term) {
    searchTerm = term;
    notifyListeners();
  }
}
