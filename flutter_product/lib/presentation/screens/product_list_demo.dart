import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

// ---------------------------------------------------------------------------
// Product model (null-safe)
// ---------------------------------------------------------------------------
class Product {
  final int id;
  final String name;
  final double price;
  final int stock;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.createdAt,
  });
}

// ---------------------------------------------------------------------------
// Mock repository that simulates paginated server responses locally.
// Use `fetchPage` to request a page with optional search/sort.
// ---------------------------------------------------------------------------
enum SortBy { none, price, stock }

class MockProductRepository {
  final List<Product> _all;

  MockProductRepository({int total = 200})
    : _all = List.generate(total, (i) {
        final price = (10 + (i % 50)) + (i % 10) * 0.5;
        final stock = (i * 7) % 120;
        final daysAgo = i % 365;
        return Product(
          id: i + 1,
          name: 'Product ${(i + 1).toString().padLeft(3, '0')}',
          price: double.parse(price.toStringAsFixed(2)),
          stock: stock,
          createdAt: DateTime.now().subtract(Duration(days: daysAgo)),
        );
      });

  // Simulate network latency and return a page
  Future<List<Product>> fetchPage({
    required int page,
    required int pageSize,
    String? query,
    SortBy sortBy = SortBy.none,
    bool ascending = true,
  }) async {
    // simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    // Filter by query
    var list =
        _all.where((p) {
          if (query == null || query.isEmpty) return true;
          return p.name.toLowerCase().contains(query.toLowerCase());
        }).toList();

    // Sort
    if (sortBy == SortBy.price) {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (sortBy == SortBy.stock) {
      list.sort((a, b) => a.stock.compareTo(b.stock));
    }
    if (!ascending && sortBy != SortBy.none) list = list.reversed.toList();

    // Pagination
    final start = page * pageSize;
    if (start >= list.length) return [];
    final end = (start + pageSize).clamp(0, list.length);
    return list.sublist(start, end);
  }
}

// ---------------------------------------------------------------------------
// ProductListPage - self-contained stateful widget
// - Debounced search (500ms)
// - Sort by price/stock asc/desc
// - Infinite scroll (20 per page)
// - Export visible items to CSV/PDF
// - Professional card-based design
// ---------------------------------------------------------------------------
class ProductListPage extends StatefulWidget {
  const ProductListPage({Key? key}) : super(key: key);

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  // repository and paging config
  final repo = MockProductRepository(total: 300);
  final int _pageSize = 20;

  // UI state
  final List<Product> _items = [];
  int _pageIndex = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isInitial = true;

  // Search + debounce
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';

  // Sorting
  SortBy _sortBy = SortBy.none;
  bool _sortAsc = true;

  // Scroll controller for infinite scroll
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchNextPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // Called when scrolling; triggers page fetch when near bottom
  void _onScroll() {
    if (!_hasMore || _isLoading) return;
    final threshold = 200.0; // px from bottom
    if (_scrollController.position.maxScrollExtent -
            _scrollController.position.pixels <=
        threshold) {
      _fetchNextPage();
    }
  }

  // Debounced search handler (500ms)
  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _query = v.trim();
      _resetAndFetch();
    });
  }

  // Reset paging and load first page
  void _resetAndFetch() {
    setState(() {
      _items.clear();
      _pageIndex = 0;
      _hasMore = true;
      _isInitial = false;
    });
    _fetchNextPage();
  }

  // Fetch next page from repository and append
  Future<void> _fetchNextPage() async {
    if (!_hasMore || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      final page = await repo.fetchPage(
        page: _pageIndex,
        pageSize: _pageSize,
        query: _query,
        sortBy: _sortBy,
        ascending: _sortAsc,
      );
      setState(() {
        _items.addAll(page);
        _pageIndex += 1;
        _hasMore = page.length == _pageSize;
      });
    } catch (e) {
      // In a real app, surface error to user
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Toggle sort field or order
  void _setSort(SortBy by) {
    setState(() {
      if (_sortBy == by) {
        _sortAsc = !_sortAsc; // toggle
      } else {
        _sortBy = by;
        _sortAsc = true;
      }
    });
    _resetAndFetch();
  }

  // Export current visible items (currently loaded items) to CSV
  Future<void> _exportCsv() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/products_${DateTime.now().millisecondsSinceEpoch}.csv';
      final headers = ['ID', 'Name', 'Price', 'Stock', 'CreatedAt'];
      final rows =
          _items
              .map(
                (p) => [
                  p.id,
                  p.name,
                  p.price.toStringAsFixed(2),
                  p.stock,
                  p.createdAt.toIso8601String(),
                ],
              )
              .toList();
      final csvStr = const ListToCsvConverter().convert([headers, ...rows]);
      final file = File(path);
      await file.writeAsString(csvStr);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV saved to: $path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV export failed: $e')));
    }
  }

  // Export current visible items to PDF using syncfusion_flutter_pdf
  Future<void> _exportPdf() async {
    try {
      final PdfDocument doc = PdfDocument();
      final page = doc.pages.add();

      final PdfGrid grid = PdfGrid();
      grid.columns.add(count: 4);
      grid.headers.add(1);
      final PdfGridRow header = grid.headers[0];
      header.cells[0].value = 'ID';
      header.cells[1].value = 'Name';
      header.cells[2].value = 'Price';
      header.cells[3].value = 'Stock';

      for (var p in _items) {
        final r = grid.rows.add();
        r.cells[0].value = p.id.toString();
        r.cells[1].value = p.name;
        r.cells[2].value = '\$${p.price.toStringAsFixed(2)}';
        r.cells[3].value = p.stock.toString();
      }

      final Size pageSize = page.getClientSize();
      grid.draw(
        page: page,
        bounds: Rect.fromLTWH(0, 0, pageSize.width, pageSize.height),
      );

      final bytes = await doc.save();
      doc.dispose();

      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/products_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(path);
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF saved to: $path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF export failed: $e')));
    }
  }

  // Pull-to-refresh
  Future<void> _onRefresh() async {
    setState(() {
      _items.clear();
      _pageIndex = 0;
      _hasMore = true;
    });
    await _fetchNextPage();
  }

  // Build a professional card for a product
  Widget _buildProductCard(Product p) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  p.name.split(' ').last,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '\$${p.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Stock: ${p.stock}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat.yMMMd().format(p.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
                const SizedBox(height: 8),
                IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        elevation: 2,
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'csv') await _exportCsv();
              if (v == 'pdf') await _exportPdf();
            },
            itemBuilder:
                (_) => const [
                  PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
                  PopupMenuItem(value: 'csv', child: Text('Export CSV')),
                ],
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search products...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Sorting controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Text('Sort by:'),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('None'),
                    selected: _sortBy == SortBy.none,
                    onSelected: (_) => _setSort(SortBy.none),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Price'),
                    selected: _sortBy == SortBy.price,
                    onSelected: (_) => _setSort(SortBy.price),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Stock'),
                    selected: _sortBy == SortBy.stock,
                    onSelected: (_) => _setSort(SortBy.stock),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: _sortAsc ? 'Ascending' : 'Descending',
                    onPressed: () {
                      setState(() => _sortAsc = !_sortAsc);
                      _resetAndFetch();
                    },
                    icon: Icon(
                      _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child:
                    _isInitial && _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                          controller: _scrollController,
                          itemCount:
                              _items.length +
                              1, // additional slot for loader / no-more
                          itemBuilder: (context, index) {
                            if (index < _items.length) {
                              return _buildProductCard(_items[index]);
                            }

                            // Footer: loading indicator OR No more products
                            if (_isLoading) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            if (!_hasMore) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    'No more products',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Usage:
// Paste this file into `lib/screens/product_list_demo.dart` and open
// by pushing `ProductListPage()` in your navigator or setting as `home`.
// Ensure `syncfusion_flutter_pdf`, `csv`, and `path_provider` are in pubspec.yaml
// ---------------------------------------------------------------------------
