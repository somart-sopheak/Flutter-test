import 'dart:async'; // For StreamSubscription
import 'package:connectivity_plus/connectivity_plus.dart'; // Import the package
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

enum SortBy { none, price, stock }

class ProductProvider extends ChangeNotifier {
  final ApiService api;
  List<Product> _products = [];
  bool _isInitialLoading = false; // For initial fetch/refresh
  String? error;

  // Search, Sort, and Filter state
  String searchTerm = '';
  SortBy sortBy = SortBy.none;
  bool sortAsc = true;
  double? priceMinFilter;
  double? priceMaxFilter;
  int? stockMinFilter;
  int? stockMaxFilter;
  DateTime? dateFromFilter;
  DateTime? dateToFilter;

  // Server-side Pagination State
  final int _limit = 10;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _isCudLoading = false;
  bool _isExporting = false;

  // --- Connectivity and Retry State ---
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _lastFetchFailedDueToNetwork = false;
  Timer? _retryTimer;
  int _currentRetryDelayInSeconds = 5;
  static const int _maxRetryDelayInSeconds = 60;
  // --- End Connectivity State ---

  ProductProvider({ApiService? apiService}) : api = apiService ?? ApiService() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
  }

  // Public Getters
  List<Product> get products => _products;
  bool get isInitialLoading => _isInitialLoading;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  bool get loading => _isCudLoading;
  bool get isExporting => _isExporting;

  // --- New Getter to check if filters are active ---
  bool get areFiltersActive {
    return priceMinFilter != null ||
        priceMaxFilter != null ||
        stockMinFilter != null ||
        stockMaxFilter != null ||
        dateFromFilter != null ||
        dateToFilter != null;
  }
  // --- End New Getter ---

  // Static min/max for filters
  double get minPrice => 0.0;
  double get maxPrice => 10000.0;
  int get minStock => 0;
  int get maxStock => 1000;
  DateTime? get earliestDate => DateTime(2000);
  DateTime? get latestDate => DateTime.now();

  // --- Connectivity and Retry Logic ---

  void _handleConnectivityChange(List<ConnectivityResult> result) {
    final bool isOnline = result.any((r) => r != ConnectivityResult.none);
    if (isOnline && _lastFetchFailedDueToNetwork) {
      print("Network connection restored. Retrying fetching products...");
      _stopRetryTimer(); // Stop any existing timers
      fetchProducts(); // And retry immediately
    }
  }

  bool _isNetworkError(dynamic e) {
    final errorString = e.toString().toLowerCase();
    return errorString.contains('socketexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('connection refused') ||
        errorString.contains('network is unreachable');
  }

  /// Stops any pending retry timer.
  void _stopRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _currentRetryDelayInSeconds = 5; // Reset delay
  }

  /// Schedules the next retry attempt with exponential backoff.
  void _startRetryTimer() {
    _stopRetryTimer(); // Cancel any existing timer first
    print(
      "Network error. Attempting to reconnect in $_currentRetryDelayInSeconds seconds...",
    );
    _retryTimer = Timer(Duration(seconds: _currentRetryDelayInSeconds), () {
      fetchProducts(); // This is the retry attempt
    });

    // Increase delay for the *next* potential failure
    _currentRetryDelayInSeconds = (_currentRetryDelayInSeconds * 2).clamp(
      5,
      _maxRetryDelayInSeconds,
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _stopRetryTimer(); // Ensure timer is cancelled on dispose
    super.dispose();
  }

  // --- Filter Setters ---
  // These are user-initiated, so they should stop any retry loops
  // and start a fresh fetch.
  void setPriceFilter(double? min, double? max) {
    priceMinFilter = min;
    priceMaxFilter = max;
    fetchProducts();
  }

  void setStockFilter(int? min, int? max) {
    stockMinFilter = min;
    stockMaxFilter = max;
    fetchProducts();
  }

  void setDateFilter(DateTime? from, DateTime? to) {
    dateFromFilter = from;
    dateToFilter = to;
    fetchProducts();
  }

  // --- New: Method to clear all filters ---
  void clearFilters() {
    priceMinFilter = null;
    priceMaxFilter = null;
    stockMinFilter = null;
    stockMaxFilter = null;
    dateFromFilter = null;
    dateToFilter = null;
    fetchProducts(); // Refresh the list
  }
  // --- End New Method ---

  void setSearchTerm(String term) {
    searchTerm = term;
    fetchProducts();
  }

  void setSort(SortBy by, {bool ascending = true}) {
    sortBy = by;
    sortAsc = ascending;
    fetchProducts();
  }

  // --- Data Fetching Methods (Modified) ---

  Future<void> fetchProducts() async {
    _isInitialLoading = true;
    error = null;
    _currentPage = 1;
    _hasMore = true;
    _stopRetryTimer(); // Stop any retries if user manually refreshes
    notifyListeners();

    try {
      final response = await api.fetchProductsPage(
        page: 1,
        limit: _limit,
        searchTerm: searchTerm,
        sortBy: sortBy,
        sortAsc: sortAsc,
        priceMin: priceMinFilter,
        priceMax: priceMaxFilter,
        stockMin: stockMinFilter,
        stockMax: stockMaxFilter,
        dateFrom: dateFromFilter,
        dateTo: dateToFilter,
      );

      final List<dynamic> data = response['data'];
      _products = data.map((e) => Product.fromJson(e)).toList();
      _hasMore = response['pagination']['hasNextPage'];
      _currentPage = 1;
      _lastFetchFailedDueToNetwork = false;
      _stopRetryTimer(); // <-- Success: stop all retries
    } catch (e) {
      error = e.toString();
      _lastFetchFailedDueToNetwork = _isNetworkError(e);
      if (_lastFetchFailedDueToNetwork) {
        _startRetryTimer(); // <-- Failure: schedule a retry
      }
    }
    _isInitialLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _isInitialLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = await api.fetchProductsPage(
        page: nextPage,
        limit: _limit,
        // ... (all filter params)
        searchTerm: searchTerm,
        sortBy: sortBy,
        sortAsc: sortAsc,
        priceMin: priceMinFilter,
        priceMax: priceMaxFilter,
        stockMin: stockMinFilter,
        stockMax: stockMaxFilter,
        dateFrom: dateFromFilter,
        dateTo: dateToFilter,
      );

      final List<dynamic> data = response['data'];
      final newProducts = data.map((e) => Product.fromJson(e)).toList();

      _products.addAll(newProducts);
      _hasMore = response['pagination']['hasNextPage'];
      _currentPage = nextPage;
      _lastFetchFailedDueToNetwork = false;
    } catch (e) {
      error = "Failed to load more: $e";
      _lastFetchFailedDueToNetwork = _isNetworkError(e);
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<List<Product>> fetchAllForExport() async {
    _isExporting = true;
    notifyListeners();
    try {
      final allProducts = await api.fetchAllProductsForExport(
        // ... (all filter params)
        searchTerm: searchTerm,
        sortBy: sortBy,
        sortAsc: sortAsc,
        priceMin: priceMinFilter,
        priceMax: priceMaxFilter,
        stockMin: stockMinFilter,
        stockMax: stockMaxFilter,
        dateFrom: dateFromFilter,
        dateTo: dateToFilter,
      );
      _isExporting = false;
      _lastFetchFailedDueToNetwork = false;
      notifyListeners();
      return allProducts;
    } catch (e) {
      error = "Export failed: $e";
      _isExporting = false;
      _lastFetchFailedDueToNetwork = _isNetworkError(e);
      notifyListeners();
      return [];
    }
  }

  // --- CUD Operations (Modified) ---
  // These should NOT trigger the auto-retry loop.
  // They just set the flag for the connectivity listener.

  Future<bool> addProduct(Product p) async {
    _isCudLoading = true;
    notifyListeners();
    try {
      final createdProduct = await api.createProduct(p);
      _products.insert(0, createdProduct);
      _isCudLoading = false;
      _lastFetchFailedDueToNetwork = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      _isCudLoading = false;
      _lastFetchFailedDueToNetwork = _isNetworkError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(Product p) async {
    _isCudLoading = true;
    notifyListeners();
    try {
      final updatedProduct = await api.updateProduct(p);
      final idx = _products.indexWhere((e) => e.id == updatedProduct.id);
      if (idx != -1) {
        _products[idx] = updatedProduct;
      }
      _isCudLoading = false;
      _lastFetchFailedDueToNetwork = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      _isCudLoading = false;
      _lastFetchFailedDueToNetwork = _isNetworkError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    _isCudLoading = true;
    notifyListeners();
    try {
      await api.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      _isCudLoading = false;
      _lastFetchFailedDueToNetwork = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      _isCudLoading = false;
      _lastFetchFailedDueToNetwork = _isNetworkError(e);
      notifyListeners();
      return false;
    }
  }
}
