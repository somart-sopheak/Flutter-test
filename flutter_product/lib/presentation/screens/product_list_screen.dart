import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../providers/product_provider.dart';
import '../widgets/product_tile.dart';
import 'add_edit_product_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final prov = Provider.of<ProductProvider>(context, listen: false);
    if (!prov.hasMore) return;
    if (_scrollController.position.maxScrollExtent -
            _scrollController.position.pixels <=
        200) {
      prov.loadMore();
    }
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      Provider.of<ProductProvider>(
        context,
        listen: false,
      ).setSearchTerm(v.trim());
    });
  }

  // Helper method to get the Downloads directory path
  Future<String> _getDownloadsPath() async {
    if (Platform.isAndroid) {
      // For Android, use /storage/emulated/0/Download
      return '/storage/emulated/0/Download';
    } else if (Platform.isIOS) {
      // For iOS, use the app's documents directory (iOS doesn't have a shared Downloads folder)
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    } else {
      // For other platforms (Desktop), use the Downloads directory
      final dir = await getDownloadsDirectory();
      return dir?.path ?? (await getApplicationDocumentsDirectory()).path;
    }
  }

  Future<void> _showFilterSheet() async {
    final prov = Provider.of<ProductProvider>(context, listen: false);
    double tempMin = prov.priceMinFilter ?? prov.minPrice;
    double tempMax = prov.priceMaxFilter ?? prov.maxPrice;
    RangeValues priceRange = RangeValues(tempMin, tempMax);
    int tempStockMin = prov.stockMinFilter ?? prov.minStock;
    int tempStockMax = prov.stockMaxFilter ?? prov.maxStock;
    RangeValues stockRange = RangeValues(
      tempStockMin.toDouble(),
      tempStockMax.toDouble(),
    );
    DateTimeRange? pickedDateRange;

    if (prov.dateFromFilter != null || prov.dateToFilter != null) {
      final from = prov.dateFromFilter ?? prov.earliestDate ?? DateTime.now();
      final to = prov.dateToFilter ?? prov.latestDate ?? DateTime.now();
      pickedDateRange = DateTimeRange(start: from, end: to);
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final mediaH = MediaQuery.of(context).size.height;
            return SafeArea(
              child: SizedBox(
                height: mediaH * 0.75,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Filters',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  prov.setPriceFilter(null, null);
                                  prov.setStockFilter(null, null);
                                  prov.setDateFilter(null, null);
                                  Navigator.of(context).pop();
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Text(
                            'Price Range (\$${priceRange.start.toStringAsFixed(2)} - \$${priceRange.end.toStringAsFixed(2)})',
                          ),
                          RangeSlider(
                            values: priceRange,
                            min: prov.minPrice,
                            max:
                                prov.maxPrice > prov.minPrice
                                    ? prov.maxPrice
                                    : prov.minPrice + 1,
                            divisions: 50,
                            labels: RangeLabels(
                              '\$${priceRange.start.toStringAsFixed(2)}',
                              '\$${priceRange.end.toStringAsFixed(2)}',
                            ),
                            onChanged: (v) => setState(() => priceRange = v),
                          ),
                          const SizedBox(height: 12),

                          Text(
                            'Stock Range (${stockRange.start.toInt()} - ${stockRange.end.toInt()})',
                          ),
                          RangeSlider(
                            values: stockRange,
                            min: prov.minStock.toDouble(),
                            max:
                                prov.maxStock.toDouble() >
                                        prov.minStock.toDouble()
                                    ? prov.maxStock.toDouble()
                                    : prov.minStock.toDouble() + 1,
                            divisions:
                                (prov.maxStock - prov.minStock) > 0
                                    ? (prov.maxStock - prov.minStock)
                                    : 1,
                            labels: RangeLabels(
                              '${stockRange.start.toInt()}',
                              '${stockRange.end.toInt()}',
                            ),
                            onChanged: (v) => setState(() => stockRange = v),
                          ),
                          const SizedBox(height: 12),

                          const Text('Created Date Range'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final picked = await showDateRangePicker(
                                      context: context,
                                      firstDate:
                                          prov.earliestDate ?? DateTime(2000),
                                      lastDate:
                                          prov.latestDate ?? DateTime.now(),
                                      initialDateRange: pickedDateRange,
                                    );
                                    if (picked != null)
                                      setState(() => pickedDateRange = picked);
                                  },
                                  icon: const Icon(Icons.date_range),
                                  label: Text(
                                    pickedDateRange == null
                                        ? 'Select range'
                                        : '${DateFormat.yMd().format(pickedDateRange!.start)} - ${DateFormat.yMd().format(pickedDateRange!.end)}',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed:
                                    () =>
                                        setState(() => pickedDateRange = null),
                                icon: const Icon(Icons.clear),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    prov.setPriceFilter(
                                      priceRange.start,
                                      priceRange.end,
                                    );
                                    prov.setStockFilter(
                                      stockRange.start.toInt(),
                                      stockRange.end.toInt(),
                                    );
                                    if (pickedDateRange != null)
                                      prov.setDateFilter(
                                        pickedDateRange!.start,
                                        pickedDateRange!.end,
                                      );
                                    else
                                      prov.setDateFilter(null, null);
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Apply'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _exportCsv(List items) async {
    try {
      final downloadsPath = await _getDownloadsPath();
      final fileName = 'products_${DateTime.now().millisecondsSinceEpoch}.csv';
      final path = '$downloadsPath/$fileName';
      
      final headers = ['ID', 'Name', 'Price', 'Stock', 'CreatedAt'];
      final rows =
          items
              .map(
                (p) => [
                  p.id ?? '',
                  p.name,
                  (p.price).toStringAsFixed(2),
                  p.stock,
                  p.createdAt?.toIso8601String() ?? '',
                ],
              )
              .toList();
      final csvStr = const ListToCsvConverter().convert([headers, ...rows]);
      final file = File(path);
      await file.writeAsString(csvStr);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text('CSV saved to Downloads/$fileName'),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV export failed: $e')));
    }
  }

  Future<void> _exportPdf(List items) async {
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

      for (var p in items) {
        final r = grid.rows.add();
        r.cells[0].value = (p.id ?? '').toString();
        r.cells[1].value = p.name ?? '';
        r.cells[2].value = '\$${(p.price ?? 0).toStringAsFixed(2)}';
        r.cells[3].value = (p.stock ?? 0).toString();
      }

      final Size pageSize = page.getClientSize();
      grid.draw(
        page: page,
        bounds: Rect.fromLTWH(0, 0, pageSize.width, pageSize.height),
      );

      final bytes = await doc.save();
      doc.dispose();

      final downloadsPath = await _getDownloadsPath();
      final fileName = 'products_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final path = '$downloadsPath/$fileName';
      final file = File(path);
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text('PDF saved to Downloads/$fileName'),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF export failed: $e')));
    }
  }

  Future<void> _refresh() async {
    await Provider.of<ProductProvider>(context, listen: false).fetchProducts();
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
              final prov = Provider.of<ProductProvider>(context, listen: false);
              final items = prov.paginatedProducts;
              if (v == 'csv') await _exportCsv(items);
              if (v == 'pdf') await _exportPdf(items);
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
        child: Consumer<ProductProvider>(
          builder: (context, prov, _) {
            if (prov.loading && prov.products.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (prov.error != null && prov.products.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Error: ${prov.error}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              color: Theme.of(context).primaryColor,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search products...',
                        suffixIcon:
                            _searchController.text.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    Provider.of<ProductProvider>(
                                      context,
                                      listen: false,
                                    ).setSearchTerm('');
                                  },
                                )
                                : null,
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text('None'),
                          checkmarkColor: Colors.white,
                          selected: prov.sortBy == SortBy.none,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          backgroundColor: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.grey.shade400,
                              width: 1,
                            ),
                          ),
                          labelStyle:
                              prov.sortBy == SortBy.none
                                  ? const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  )
                                  : null,
                          onSelected: (_) => prov.setSort(SortBy.none),
                        ),

                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Row(
                            children: [
                              Text(
                                'Price  ',
                                style:
                                    prov.sortBy == SortBy.price
                                        ? const TextStyle(color: Colors.white)
                                        : null,
                              ),
                              if (prov.sortBy == SortBy.price)
                                Icon(
                                  prov.sortAsc
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  size: 16,
                                  color: Colors.white,
                                ),
                            ],
                          ),
                          checkmarkColor: Colors.white,
                          selected: prov.sortBy == SortBy.price,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          backgroundColor: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.grey.shade400,
                              width: 1,
                            ),
                          ),
                          onSelected:
                              (_) => prov.setSort(
                                SortBy.price,
                                ascending:
                                    prov.sortBy == SortBy.price
                                        ? !prov.sortAsc
                                        : true,
                              ),
                        ),

                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Row(
                            children: [
                              Text(
                                'Stock  ',
                                style:
                                    prov.sortBy == SortBy.stock
                                        ? const TextStyle(color: Colors.white)
                                        : null,
                              ),
                              if (prov.sortBy == SortBy.stock)
                                Icon(
                                  prov.sortAsc
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  size: 16,
                                  color: Colors.white,
                                ),
                            ],
                          ),
                          checkmarkColor: Colors.white,
                          selected: prov.sortBy == SortBy.stock,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          backgroundColor: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.grey.shade400,
                              width: 1,
                            ),
                          ),
                          onSelected:
                              (_) => prov.setSort(
                                SortBy.stock,
                                ascending:
                                    prov.sortBy == SortBy.stock
                                        ? !prov.sortAsc
                                        : true,
                              ),
                        ),

                        const Spacer(),
                        TextButton.icon(
                          onPressed: _showFilterSheet,
                          icon: Icon(
                            Icons.filter_list,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          label: Text(
                            'Filters',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child:
                        prov.paginatedProducts.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 64,
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.color,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No products found',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _searchController.text.isNotEmpty
                                        ? 'Try a different search'
                                        : 'Add your first product',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount:
                                  prov.paginatedProducts.length +
                                  (prov.hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                final list = prov.paginatedProducts;
                                if (index >= list.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16.0,
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                final p = list[index];
                                return ProductTile(
                                  product: p,
                                  onEdit: (prod) async {
                                    final changed = await Navigator.of(
                                      context,
                                    ).push<bool>(
                                      MaterialPageRoute(
                                        builder:
                                            (_) => AddEditProductScreen(
                                              product: prod,
                                            ),
                                      ),
                                    );
                                    if (changed == true) {
                                      await Provider.of<ProductProvider>(
                                        context,
                                        listen: false,
                                      ).fetchProducts();
                                    }
                                  },
                                  onDelete: (prod) async {
                                    final ok =
                                        await Provider.of<ProductProvider>(
                                          context,
                                          listen: false,
                                        ).deleteProduct(prod.id!);
                                    if (!ok) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Delete failed: ${prov.error}',
                                          ),
                                          backgroundColor:
                                              Theme.of(
                                                context,
                                              ).colorScheme.error,
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
          );
          if (created == true) {
            await Provider.of<ProductProvider>(
              context,
              listen: false,
            ).fetchProducts();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Product'),
      ),
    );
  }
}