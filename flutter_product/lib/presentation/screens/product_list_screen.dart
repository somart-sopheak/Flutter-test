import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _ProductListScreenState extends State<ProductListScreen>
    with TickerProviderStateMixin {
  // Needed for animation
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();

  // --- NEW: State variable to control button visibility ---
  bool _showScrollTopButton = false;

  void _showTopNotification(
    String message,
    Color backgroundColor,
    IconData iconData,
  ) {
    final overlay = Overlay.of(context);
    OverlayEntry? overlayEntry;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350), // Slide-in duration
    );

    final animation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: const Offset(0.0, 0.0),
    ).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic),
    );

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16.0, // Status bar + 16
              left: 16.0, // Horizontal space
              right: 16.0, // Horizontal space
            ),
            child: SlideTransition(
              position: animation,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(
                      12,
                    ), // Professional rounded corners
                    boxShadow: const [
                      BoxShadow(
                        // Professional shadow
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(iconData, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(overlayEntry);
    controller.forward();

    Timer(const Duration(seconds: 3), () {
      controller.reverse().then((_) {
        overlayEntry?.remove();
        controller.dispose();
      });
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
    _scrollController.addListener(_onScroll);
    // --- NEW: Add listener for the scroll-to-top button ---
    _scrollController.addListener(_updateScrollTopButtonVisibility);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    // --- NEW: Remove listener ---
    _scrollController.removeListener(_updateScrollTopButtonVisibility);
    _scrollController.dispose();
    super.dispose();
  }

  // --- NEW: Function to show/hide the button based on scroll offset ---
  void _updateScrollTopButtonVisibility() {
    // Show button if scrolled down more than 300 pixels
    if (_scrollController.offset > 300 && !_showScrollTopButton) {
      setState(() {
        _showScrollTopButton = true;
      });
    } else if (_scrollController.offset <= 300 && _showScrollTopButton) {
      setState(() {
        _showScrollTopButton = false;
      });
    }
  }

  void _onScroll() {
    final prov = Provider.of<ProductProvider>(context, listen: false);
    // This logic is for pagination
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

    final _priceMinCtrl = TextEditingController(
      text: tempMin.toStringAsFixed(2),
    );
    final _priceMaxCtrl = TextEditingController(
      text: tempMax.toStringAsFixed(2),
    );
    final _stockMinCtrl = TextEditingController(text: tempStockMin.toString());
    final _stockMaxCtrl = TextEditingController(text: tempStockMax.toString());

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
                                  setState(() {
                                    _priceMinCtrl.text = prov.minPrice
                                        .toStringAsFixed(2);
                                    _priceMaxCtrl.text = prov.maxPrice
                                        .toStringAsFixed(2);
                                    _stockMinCtrl.text =
                                        prov.minStock.toString();
                                    _stockMaxCtrl.text =
                                        prov.maxStock.toString();
                                    priceRange = RangeValues(
                                      prov.minPrice,
                                      prov.maxPrice,
                                    );
                                    stockRange = RangeValues(
                                      prov.minStock.toDouble(),
                                      prov.maxStock.toDouble(),
                                    );
                                    pickedDateRange = null;
                                  });
                                  prov.clearFilters();
                                  Navigator.of(context).pop();
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                                child: const Text('Clear All'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text('Price Range'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _priceMinCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+\.?\d{0,2}'),
                                    ),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Min',
                                    prefixText: '\$ ',
                                    isDense: true,
                                  ),
                                  onChanged: (value) {
                                    final pMin = double.tryParse(value);
                                    if (pMin != null &&
                                        pMin >= prov.minPrice &&
                                        pMin <= priceRange.end) {
                                      setState(() {
                                        priceRange = RangeValues(
                                          pMin,
                                          priceRange.end,
                                        );
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _priceMaxCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+\.?\d{0,2}'),
                                    ),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Max',
                                    prefixText: '\$ ',
                                    isDense: true,
                                  ),
                                  onChanged: (value) {
                                    final pMax = double.tryParse(value);
                                    if (pMax != null &&
                                        pMax <= prov.maxPrice &&
                                        pMax >= priceRange.start) {
                                      setState(() {
                                        priceRange = RangeValues(
                                          priceRange.start,
                                          pMax,
                                        );
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
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
                            onChanged:
                                (v) => setState(() {
                                  priceRange = v;
                                  _priceMinCtrl.text = v.start.toStringAsFixed(
                                    2,
                                  );
                                  _priceMaxCtrl.text = v.end.toStringAsFixed(2);
                                }),
                          ),
                          const SizedBox(height: 12),
                          const Text('Stock Range'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _stockMinCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Min',
                                    isDense: true,
                                  ),
                                  onChanged: (value) {
                                    final sMin = int.tryParse(value);
                                    if (sMin != null &&
                                        sMin >= prov.minStock &&
                                        sMin <= stockRange.end) {
                                      setState(() {
                                        stockRange = RangeValues(
                                          sMin.toDouble(),
                                          stockRange.end,
                                        );
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _stockMaxCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Max',
                                    isDense: true,
                                  ),
                                  onChanged: (value) {
                                    final sMax = int.tryParse(value);
                                    if (sMax != null &&
                                        sMax <= prov.maxStock &&
                                        sMax >= stockRange.start) {
                                      setState(() {
                                        stockRange = RangeValues(
                                          stockRange.start,
                                          sMax.toDouble(),
                                        );
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
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
                            onChanged:
                                (v) => setState(() {
                                  stockRange = v;
                                  _stockMinCtrl.text =
                                      v.start.toInt().toString();
                                  _stockMaxCtrl.text = v.end.toInt().toString();
                                }),
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

    _priceMinCtrl.dispose();
    _priceMaxCtrl.dispose();
    _stockMinCtrl.dispose();
    _stockMaxCtrl.dispose();
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV saved to Downloads/$fileName'),
          duration: Duration(seconds: 5),

          //   action: SnackBarAction(
          //     label: 'OPEN',
          //     onPressed: () {
          //       OpenFilex.open(path);
          //     },
          //   ),
          // ),
          backgroundColor: Colors.blue,
          action: SnackBarAction(
            backgroundColor: Colors.white,
            label: 'OPEN',
            textColor: const Color.fromARGB(255, 56, 12, 176),
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
      final PdfDocument doc = PdfDocument();
      final PdfPage page = doc.pages.add();
      final Size pageSize = page.getClientSize();
      page.graphics.drawString(
        'Product Report',
        PdfStandardFont(PdfFontFamily.helvetica, 20, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(0, 0, pageSize.width, 30),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      page.graphics.drawString(
        'Generated on: ${DateFormat.yMd().add_Hms().format(DateTime.now())}',
        PdfStandardFont(PdfFontFamily.helvetica, 12),
        bounds: Rect.fromLTWH(0, 30, pageSize.width, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      final PdfGrid grid = PdfGrid();
      grid.columns.add(count: 5);
      grid.headers.add(1);
      final PdfGridRow header = grid.headers[0];
      header.cells[0].value = 'ID';
      header.cells[1].value = 'Name';
      header.cells[2].value = 'Price';
      header.cells[3].value = 'Stock';
      header.cells[4].value = 'Created At';
      final PdfGridCellStyle headerStyle = PdfGridCellStyle(
        backgroundBrush: PdfSolidBrush(PdfColor(37, 99, 235)),
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
      final PdfGridCellStyle evenRowStyle = PdfGridCellStyle(
        backgroundBrush: PdfSolidBrush(PdfColor(248, 250, 252)),
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
        if (items.indexOf(p) % 2 == 0) {
          r.style = evenRowStyle;
        }
        r.cells[0].stringFormat = centerAlign;
        r.cells[2].stringFormat = rightAlign;
        r.cells[3].stringFormat = centerAlign;
        r.cells[4].stringFormat = centerAlign;
      }
      grid.columns[0].width = 40;
      grid.columns[1].width = 150;
      grid.columns[2].width = 80;
      grid.columns[3].width = 60;
      final PdfLayoutResult? gridResult = grid.draw(
        page: page,
        bounds: Rect.fromLTWH(0, 60, pageSize.width, pageSize.height - 60),
        format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate),
      );
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
      final bytes = await doc.save();
      doc.dispose();
      final downloadsPath = await _getDownloadsPath();
      final fileName = 'products_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final path = '$downloadsPath/$fileName';
      final file = File(path);
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF saved to Downloads/$fileName',
            style: const TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.blue,
          action: SnackBarAction(
            backgroundColor: Colors.white,
            label: 'OPEN',
            textColor: const Color.fromARGB(255, 56, 12, 176),
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
            if (prov.isInitialLoading && prov.products.isEmpty) {
              return ListView.builder(
                itemCount: 8,
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
                        Consumer<ProductProvider>(
                          builder: (context, prov, child) {
                            final bool filtersActive = prov.areFiltersActive;
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
                            return child!;
                          },
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
                      ],
                    ),
                  ),
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
                                    final dynamic result = await Navigator.of(
                                      context,
                                    ).push(
                                      MaterialPageRoute(
                                        builder:
                                            (_) => AddEditProductScreen(
                                              product: prod,
                                            ),
                                      ),
                                    );
                                    if (!mounted) return;

                                    if (result == true) {
                                      _showTopNotification(
                                        'Product updated successfully!',
                                        Colors.green,
                                        Icons.check_circle_outline,
                                      );
                                    } else if (result == 'nothing_changed') {
                                      _showTopNotification(
                                        'Nothing changed',
                                        Colors.grey,
                                        Icons.info_outline,
                                      );
                                    }
                                  },
                                  onDelete: (prod) async {
                                    final ok =
                                        await Provider.of<ProductProvider>(
                                          context,
                                          listen: false,
                                        ).deleteProduct(prod.id!);

                                    if (!mounted) return;

                                    if (ok) {
                                      _showTopNotification(
                                        'Product deleted successfully!',
                                        Colors.red,
                                        Icons.check_circle_outline,
                                      );
                                    } else {
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
      // --- MODIFIED: This is the new FAB structure ---
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // --- NEW: Conditionally build the "Scroll to Top" button ---
          if (_showScrollTopButton)
            Column(
              children: [
                FloatingActionButton(
                  onPressed: () {
                    _scrollController.animateTo(
                      0.0, // Scroll to the top
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Icon(Icons.arrow_upward),
                ),
                const SizedBox(height: 16),
              ],
            ),
          // --- END NEW ---

          // The original "New Product" FAB
          FloatingActionButton.extended(
            onPressed: () async {
              final dynamic result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
              );
              if (result == true && mounted) {
                _showTopNotification(
                  'Product created successfully!',
                  Colors.green,
                  Icons.check_circle_outline,
                );
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('New Product'),
          ),
        ],
      ),
      // --- END MODIFICATION ---
    );
  }
}
