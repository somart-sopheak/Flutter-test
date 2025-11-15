import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

enum SortBy { none, price, stock }

class ProductProvider extends ChangeNotifier {
  final ApiService api;
  List<Product> _products = [];
  bool loading = false;
  String? error;
  String searchTerm = '';
  SortBy sortBy = SortBy.none;
  bool sortAsc = true;
  // Filters
  double? priceMinFilter;
  double? priceMaxFilter;
  int? stockMinFilter;
  int? stockMaxFilter;
  DateTime? dateFromFilter;
  DateTime? dateToFilter;

  // Pagination
  final int itemsPerPage = 20;
  int _currentMax = 20;

  ProductProvider({ApiService? apiService}) : api = apiService ?? ApiService();

  List<Product> get products => _products;

  List<Product> get filteredProducts {
    final term = searchTerm.toLowerCase();
    var list =
        _products.where((p) {
          if (searchTerm.isEmpty) return true;
          return p.name.toLowerCase().contains(term);
        }).toList();

    // Apply price range filter
    if (priceMinFilter != null || priceMaxFilter != null) {
      final low = priceMinFilter ?? double.negativeInfinity;
      final high = priceMaxFilter ?? double.infinity;
      list = list.where((p) => p.price >= low && p.price <= high).toList();
    }

    // Apply stock range filter
    if (stockMinFilter != null || stockMaxFilter != null) {
      final low = stockMinFilter ?? -9223372036854775808;
      final high = stockMaxFilter ?? 9223372036854775807;
      list = list.where((p) => p.stock >= low && p.stock <= high).toList();
    }

    // Apply date range filter
    if (dateFromFilter != null || dateToFilter != null) {
      final from = dateFromFilter ?? DateTime.fromMillisecondsSinceEpoch(0);
      final to = dateToFilter ?? DateTime.now();
      list =
          list.where((p) {
            final d = p.createdAt;
            if (d == null) return false;
            return !(d.isBefore(from) || d.isAfter(to));
          }).toList();
    }

    // Apply sorting
    if (sortBy != SortBy.none) {
      if (sortBy == SortBy.price) {
        list.sort((a, b) => a.price.compareTo(b.price));
      } else if (sortBy == SortBy.stock) {
        list.sort((a, b) => a.stock.compareTo(b.stock));
      }
      if (!sortAsc) list = list.reversed.toList();
    }

    return list;
  }

  // helper getters for filter UI
  // (type field removed) No available types getter

  double get minPrice {
    if (_products.isEmpty) return 0.0;
    return _products.map((p) => p.price).reduce((a, b) => a < b ? a : b);
  }

  double get maxPrice {
    if (_products.isEmpty) return 0.0;
    return _products.map((p) => p.price).reduce((a, b) => a > b ? a : b);
  }

  int get minStock {
    if (_products.isEmpty) return 0;
    return _products.map((p) => p.stock).reduce((a, b) => a < b ? a : b);
  }

  int get maxStock {
    if (_products.isEmpty) return 0;
    return _products.map((p) => p.stock).reduce((a, b) => a > b ? a : b);
  }

  DateTime? get earliestDate {
    final dates =
        _products
            .map((p) => p.createdAt)
            .where((d) => d != null)
            .map((e) => e!)
            .toList();
    if (dates.isEmpty) return null;
    dates.sort();
    return dates.first;
  }

  DateTime? get latestDate {
    final dates =
        _products
            .map((p) => p.createdAt)
            .where((d) => d != null)
            .map((e) => e!)
            .toList();
    if (dates.isEmpty) return null;
    dates.sort();
    return dates.last;
  }

  // filter setters
  void setTypeFilter(String? type) {
    // deprecated: type filter removed
    return;
  }

  void setPriceFilter(double? min, double? max) {
    priceMinFilter = min;
    priceMaxFilter = max;
    resetPagination();
    notifyListeners();
  }

  void setStockFilter(int? min, int? max) {
    stockMinFilter = min;
    stockMaxFilter = max;
    resetPagination();
    notifyListeners();
  }

  void setDateFilter(DateTime? from, DateTime? to) {
    dateFromFilter = from;
    dateToFilter = to;
    resetPagination();
    notifyListeners();
  }

  // Returns a paginated slice of the filtered/sorted products
  List<Product> get paginatedProducts {
    final list = filteredProducts;
    if (_currentMax >= list.length) return list;
    return list.sublist(0, _currentMax);
  }

  bool get hasMore => _currentMax < filteredProducts.length;

  void resetPagination() {
    _currentMax = itemsPerPage;
    notifyListeners();
  }

  void loadMore() {
    _currentMax = (_currentMax + itemsPerPage).clamp(
      0,
      filteredProducts.length,
    );
    notifyListeners();
  }

  Future<void> fetchProducts() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      _products = await api.fetchProducts();
      // reset pagination after fresh fetch
      resetPagination();
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
    // when search term changes reset pagination
    resetPagination();
    notifyListeners();
  }

  void setSort(SortBy by, {bool ascending = true}) {
    sortBy = by;
    sortAsc = ascending;
    resetPagination();
    notifyListeners();
  }
}
