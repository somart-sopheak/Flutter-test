import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:open_filex/open_filex.dart'; // <-- Import for opening files

import '../../models/product.dart'; // Import the model
import '../../providers/product_provider.dart';
import '../widgets/product_tile.dart';
import '../widgets/skeleton.dart'; // <-- Import the skeleton
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

  Future<String> _getDownloadsPath() async {
    if (Platform.isAndroid) {
      return '/storage/emulated/0/Download';
    } else if (Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    } else {
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
      final from = prov.dateFromFilter ?? prov.earliestDate ?? DateTime(2000);
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
                            max: prov.maxPrice,
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
                            max: prov.maxStock.toDouble(),
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

  Future<void> _exportCsv(List<Product> items) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No products to export')));
      return;
    }
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
                  // "Prettier" CSV data
                  '\$${(p.price).toStringAsFixed(2)}',
                  p.stock,
                  p.createdAt != null
                      ? DateFormat.yMd().add_Hms().format(p.createdAt!)
                      : 'N/A',
                ],
              )
              .toList();
      final csvStr = const ListToCsvConverter().convert([headers, ...rows]);
      final file = File(path);
      await file.writeAsString(csvStr);
      if (!mounted) return;

      // --- New Snackbar with "Open" Button ---
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV saved to Downloads/$fileName'),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: 'OPEN',
            onPressed: () {
              OpenFilex.open(path);
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV export failed: $e')));
    }
  }

  Future<void> _exportPdf(List<Product> items) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No products to export')));
      return;
    }
    try {
      // --- Create "Prettier" PDF ---
      final PdfDocument doc = PdfDocument();
      final PdfPage page = doc.pages.add();
      final Size pageSize = page.getClientSize();

      // 1. Add Title
      page.graphics.drawString(
        'Product Report',
        PdfStandardFont(PdfFontFamily.helvetica, 20, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(0, 0, pageSize.width, 30),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      // 2. Add Subtitle
      page.graphics.drawString(
        'Generated on: ${DateFormat.yMd().add_Hms().format(DateTime.now())}',
        PdfStandardFont(PdfFontFamily.helvetica, 12),
        bounds: Rect.fromLTWH(0, 30, pageSize.width, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      // 3. Create Styled Grid
      final PdfGrid grid = PdfGrid();
      grid.columns.add(count: 5); // Added 'Created At' column
      grid.headers.add(1);
      final PdfGridRow header = grid.headers[0];
      header.cells[0].value = 'ID';
      header.cells[1].value = 'Name';
      header.cells[2].value = 'Price';
      header.cells[3].value = 'Stock';
      header.cells[4].value = 'Created At';

      // 4. Apply Header Style
      final PdfGridCellStyle headerStyle = PdfGridCellStyle(
        backgroundBrush: PdfSolidBrush(PdfColor(37, 99, 235)), // Primary Blue
        textBrush: PdfBrushes.white,
        font: PdfStandardFont(
          PdfFontFamily.helvetica,
          10,
          style: PdfFontStyle.bold,
        ),
        format: PdfStringFormat(
          alignment: PdfTextAlignment.center,
          lineAlignment: PdfVerticalAlignment.middle,
        ),
      );
      for (int i = 0; i < header.cells.count; i++) {
        header.cells[i].style = headerStyle;
      }

      // 5. Populate Rows with Zebra Striping
      final PdfGridCellStyle evenRowStyle = PdfGridCellStyle(
        backgroundBrush: PdfSolidBrush(PdfColor(248, 250, 252)), // Light gray
      );
      final PdfStringFormat rightAlign = PdfStringFormat(
        alignment: PdfTextAlignment.right,
      );
      final PdfStringFormat centerAlign = PdfStringFormat(
        alignment: PdfTextAlignment.center,
      );

      for (var p in items) {
        final r = grid.rows.add();
        r.cells[0].value = (p.id ?? '').toString();
        r.cells[1].value = p.name ?? '';
        r.cells[2].value = '\$${(p.price ?? 0).toStringAsFixed(2)}';
        r.cells[3].value = (p.stock ?? 0).toString();
        r.cells[4].value =
            p.createdAt != null ? DateFormat.yMd().format(p.createdAt!) : 'N/A';

        // Apply zebra stripe
        if (items.indexOf(p) % 2 == 0) {
          r.style = evenRowStyle;
        }

        // *** FIX: Apply stringFormat directly to the cell, not the style ***
        r.cells[0].stringFormat = centerAlign;
        r.cells[2].stringFormat = rightAlign;
        r.cells[3].stringFormat = centerAlign;
        r.cells[4].stringFormat = centerAlign;
      }

      // 6. Set column widths
      grid.columns[0].width = 40; // ID
      grid.columns[1].width = 150; // Name
      grid.columns[2].width = 80; // Price
      grid.columns[3].width = 60; // Stock

      // 7. Draw the grid on the page
      final PdfLayoutResult? gridResult = grid.draw(
        page: page,
        bounds: Rect.fromLTWH(0, 60, pageSize.width, pageSize.height - 60),
        format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate),
      );

      // 8. Add Footer
      if (gridResult != null) {
        page.graphics.drawString(
          'Total Products: ${items.length}',
          PdfStandardFont(
            PdfFontFamily.helvetica,
            10,
            style: PdfFontStyle.bold,
          ),
          bounds: Rect.fromLTWH(
            0,
            gridResult.bounds.bottom + 10,
            pageSize.width - 10,
            20,
          ),
          format: PdfStringFormat(alignment: PdfTextAlignment.right),
        );
      }

      // 9. Save the document
      final bytes = await doc.save();
      doc.dispose();

      // --- End Prettier PDF ---

      final downloadsPath = await _getDownloadsPath();
      final fileName = 'products_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final path = '$downloadsPath/$fileName';
      final file = File(path);
      await file.writeAsBytes(bytes);
      if (!mounted) return;

      // --- New Professional Snackbar ---
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'CSV saved to Downloads/$fileName',
            style: const TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 10),
          backgroundColor: Theme.of(context).colorScheme.primary, // Blue bg
          action: SnackBarAction(
            backgroundColor: Colors.white,
            label: 'OPEN',
            textColor: const Color.fromARGB(255, 56, 12, 176), // White text
            onPressed: () {
              OpenFilex.open(path);
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'CSV export failed: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _refresh() async {
    await Provider.of<ProductProvider>(context, listen: false).fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List Products'),
        elevation: 2,
        actions: [
          Consumer<ProductProvider>(
            builder: (context, prov, _) {
              if (prov.isExporting) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                );
              }
              return PopupMenuButton<String>(
                onSelected: (v) async {
                  final prov = Provider.of<ProductProvider>(
                    context,
                    listen: false,
                  );
                  final List<Product> itemsToExport =
                      await prov.fetchAllForExport();

                  if (itemsToExport.isEmpty && prov.error == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No items to export')),
                    );
                    return;
                  }

                  if (v == 'csv') await _exportCsv(itemsToExport);
                  if (v == 'pdf') await _exportPdf(itemsToExport);
                },
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(
                        value: 'pdf',
                        child: Text('Export PDF (All)'),
                      ),
                      PopupMenuItem(
                        value: 'csv',
                        child: Text('Export CSV (All)'),
                      ),
                    ],
                icon: const Icon(Icons.download_rounded),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<ProductProvider>(
          builder: (context, prov, _) {
            // *** UPDATED: Show Skeleton Loader ***
            if (prov.isInitialLoading && prov.products.isEmpty) {
              return ListView.builder(
                itemCount: 8, // Show 8 skeleton cards
                itemBuilder: (context, index) => const ProductTileSkeleton(),
              );
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
                            prov.searchTerm.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    prov.setSearchTerm('');
                                  },
                                )
                                : null,
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),

                  // Sort and Filter Chips
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
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
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
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
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
                        // --- UPDATED FILTER BUTTON ---
                        // We use a Consumer here to check areFiltersActive
                        Consumer<ProductProvider>(
                          builder: (context, prov, child) {
                            final bool filtersActive = prov.areFiltersActive;

                            // If filters are active, show a "Clear" button
                            if (filtersActive) {
                              return TextButton(
                                onPressed: prov.clearFilters,
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.error,
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.clear, size: 18),
                                    SizedBox(width: 4),
                                    Text('Clear'),
                                  ],
                                ),
                              );
                            }

                            // Otherwise, show the normal "Filters" button
                            // This is the child we passed in
                            return child!;
                          },
                          // This child is the original TextButton.icon
                          // It's passed into the builder so it doesn't rebuild
                          child: TextButton.icon(
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
                        ),

                        // --- END UPDATED FILTER BUTTON ---
                      ],
                    ),
                  ),

                  // The List
                  Expanded(
                    child:
                        prov.products.isEmpty
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
                                        ? 'Try a different search or filters'
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
                                  prov.products.length + (prov.hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                final list = prov.products;
                                if (index >= list.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 24.0,
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
                                    // *** UPDATED: No refresh call needed ***
                                    await Navigator.of(context).push<bool>(
                                      MaterialPageRoute(
                                        builder:
                                            (_) => AddEditProductScreen(
                                              product: prod,
                                            ),
                                      ),
                                    );
                                  },
                                  onDelete: (prod) async {
                                    // *** UPDATED: No refresh call needed ***
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
          // *** UPDATED: No refresh call needed ***
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Product'),
      ),
    );
  }
}
