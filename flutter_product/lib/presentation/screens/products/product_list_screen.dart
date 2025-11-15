// import 'dart:async';
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:csv/csv.dart';
// import 'package:syncfusion_flutter_pdf/pdf.dart';

// import '../../providers/product_provider.dart';
// import '../widgets/product_tile.dart';
// import 'add_edit_product_screen.dart';

// class ProductListScreen extends StatefulWidget {
//   const ProductListScreen({Key? key}) : super(key: key);

//   @override
//   State<ProductListScreen> createState() => _ProductListScreenState();
// }

// class _ProductListScreenState extends State<ProductListScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   Timer? _debounce;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback(
//       (_) => context.read<ProductProvider>().fetchProducts(),
//     );
//     _scrollController.addListener(_onScroll);
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _debounce?.cancel();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   // ────────────────────────────────
//   // Pagination
//   // ────────────────────────────────
//   void _onScroll() {
//     final prov = context.read<ProductProvider>();
//     if (!prov.hasMore) return;

//     final atBottom = _scrollController.position.maxScrollExtent -
//             _scrollController.position.pixels <=
//         200;

//     if (atBottom) prov.loadMore();
//   }

//   // ────────────────────────────────
//   // Search (Debounced)
//   // ────────────────────────────────
//   void _onSearchChanged(String value) {
//     _debounce?.cancel();
//     _debounce = Timer(const Duration(milliseconds: 500), () {
//       context.read<ProductProvider>().setSearchTerm(value.trim());
//     });
//   }

//   // ────────────────────────────────
//   // Filter Modal
//   // ────────────────────────────────
//   Future<void> _showFilterSheet() async {
//     final prov = context.read<ProductProvider>();

//     double minPrice = prov.priceMinFilter ?? prov.minPrice;
//     double maxPrice = prov.priceMaxFilter ?? prov.maxPrice;

//     RangeValues priceRange = RangeValues(minPrice, maxPrice);

//     int stockMin = prov.stockMinFilter ?? prov.minStock;
//     int stockMax = prov.stockMaxFilter ?? prov.maxStock;

//     RangeValues stockRange = RangeValues(
//       stockMin.toDouble(),
//       stockMax.toDouble(),
//     );

//     DateTimeRange? dateRange = (prov.dateFromFilter != null ||
//             prov.dateToFilter != null)
//         ? DateTimeRange(
//             start: prov.dateFromFilter!,
//             end: prov.dateToFilter!,
//           )
//         : null;

//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (ctx) {
//         return StatefulBuilder(
//           builder: (context, setState) {
//             return _buildFilterContent(
//               prov,
//               priceRange,
//               (r) => setState(() => priceRange = r),
//               stockRange,
//               (r) => setState(() => stockRange = r),
//               dateRange,
//               (d) => setState(() => dateRange = d),
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildFilterContent(
//     ProductProvider prov,
//     RangeValues priceRange,
//     ValueChanged<RangeValues> onPriceChanged,
//     RangeValues stockRange,
//     ValueChanged<RangeValues> onStockChanged,
//     DateTimeRange? dateRange,
//     ValueChanged<DateTimeRange?> onDateChanged,
//   ) {
//     return SafeArea(
//       child: Container(
//         height: MediaQuery.of(context).size.height * 0.75,
//         padding: const EdgeInsets.all(16),
//         decoration: const BoxDecoration(
//           borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//           color: Colors.white,
//         ),
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               _buildFilterHeader(prov),
//               const SizedBox(height: 12),
//               _buildPriceFilter(prov, priceRange, onPriceChanged),
//               const SizedBox(height: 12),
//               _buildStockFilter(prov, stockRange, onStockChanged),
//               const SizedBox(height: 12),
//               _buildDateFilter(dateRange, onDateChanged),
//               const SizedBox(height: 20),
//               _buildFilterActions(
//                 prov,
//                 priceRange,
//                 stockRange,
//                 dateRange,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildFilterHeader(ProductProvider prov) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//         TextButton(
//           onPressed: () {
//             prov.clearFilters();
//             Navigator.pop(context);
//           },
//           child: const Text('Clear'),
//         )
//       ],
//     );
//   }

//   Widget _buildPriceFilter(
//     ProductProvider prov,
//     RangeValues range,
//     ValueChanged<RangeValues> onChanged,
//   ) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text("Price (\$${range.start.toStringAsFixed(2)} - \$${range.end.toStringAsFixed(2)})"),
//         RangeSlider(
//           values: range,
//           min: prov.minPrice,
//           max: prov.maxPrice,
//           divisions: 50,
//           onChanged: onChanged,
//         ),
//       ],
//     );
//   }

//   Widget _buildStockFilter(
//     ProductProvider prov,
//     RangeValues range,
//     ValueChanged<RangeValues> onChanged,
//   ) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text("Stock (${range.start.toInt()} - ${range.end.toInt()})"),
//         RangeSlider(
//           values: range,
//           min: prov.minStock.toDouble(),
//           max: prov.maxStock.toDouble(),
//           divisions: prov.maxStock - prov.minStock,
//           onChanged: onChanged,
//         ),
//       ],
//     );
//   }

//   Widget _buildDateFilter(
//     DateTimeRange? dateRange,
//     ValueChanged<DateTimeRange?> onChanged,
//   ) {
//     return Row(
//       children: [
//         Expanded(
//           child: ElevatedButton.icon(
//             icon: const Icon(Icons.date_range),
//             label: Text(
//               dateRange == null
//                   ? 'Select Date Range'
//                   : "${DateFormat.yMd().format(dateRange.start)} - ${DateFormat.yMd().format(dateRange.end)}",
//             ),
//             onPressed: () async {
//               final picked = await showDateRangePicker(
//                 context: context,
//                 firstDate: DateTime(2000),
//                 lastDate: DateTime.now(),
//                 initialDateRange: dateRange,
//               );
//               if (picked != null) onChanged(picked);
//             },
//           ),
//         ),
//         IconButton(
//           icon: const Icon(Icons.clear),
//           onPressed: () => onChanged(null),
//         ),
//       ],
//     );
//   }

//   Widget _buildFilterActions(
//     ProductProvider prov,
//     RangeValues priceRange,
//     RangeValues stockRange,
//     DateTimeRange? dateRange,
//   ) {
//     return Row(
//       children: [
//         Expanded(
//           child: OutlinedButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//         ),
//         const SizedBox(width: 10),
//         Expanded(
//           child: ElevatedButton(
//             onPressed: () {
//               prov.applyFilters(
//                 priceRange.start,
//                 priceRange.end,
//                 stockRange.start.toInt(),
//                 stockRange.end.toInt(),
//                 dateRange?.start,
//                 dateRange?.end,
//               );
//               Navigator.pop(context);
//             },
//             child: const Text("Apply"),
//           ),
//         ),
//       ],
//     );
//   }

//   // ────────────────────────────────
//   // CSV Export
//   // ────────────────────────────────
//   Future<void> _exportCsv(List items) async {
//     try {
//       final dir = await getApplicationDocumentsDirectory();
//       final file = File("${dir.path}/products_${DateTime.now().millisecondsSinceEpoch}.csv");

//       final rows = [
//         ['ID', 'Name', 'Price', 'Stock', 'CreatedAt'],
//         ...items.map((p) => [
//               p.id,
//               p.name,
//               p.price.toStringAsFixed(2),
//               p.stock,
//               p.createdAt?.toIso8601String() ?? '',
//             ])
//       ];

//       await file.writeAsString(const ListToCsvConverter().convert(rows));

//       if (!mounted) return;
//       _showSnack("CSV saved: ${file.path}");
//     } catch (e) {
//       _showSnack("CSV export failed: $e");
//     }
//   }

//   // ────────────────────────────────
//   // PDF Export
//   // ────────────────────────────────
//   Future<void> _exportPdf(List items) async {
//     try {
//       final doc = PdfDocument();
//       final page = doc.pages.add();

//       final grid = PdfGrid();
//       grid.columns.add(count: 4);
//       grid.headers.add(1);

//       final header = grid.headers[0];
//       header.cells[0].value = "ID";
//       header.cells[1].value = "Name";
//       header.cells[2].value = "Price";
//       header.cells[3].value = "Stock";

//       for (var p in items) {
//         final row = grid.rows.add();
//         row.cells[0].value = p.id.toString();
//         row.cells[1].value = p.name;
//         row.cells[2].value = "\$${p.price.toStringAsFixed(2)}";
//         row.cells[3].value = p.stock.toString();
//       }

//       final pageSize = page.getClientSize();
//       grid.draw(page: page, bounds: Rect.fromLTWH(0, 0, pageSize.width, pageSize.height));

//       final bytes = await doc.save();
//       doc.dispose();

//       final dir = await getApplicationDocumentsDirectory();
//       final file = File("${dir.path}/products_${DateTime.now().millisecondsSinceEpoch}.pdf");
//       await file.writeAsBytes(bytes);

//       if (!mounted) return;
//       _showSnack("PDF saved: ${file.path}");
//     } catch (e) {
//       _showSnack("PDF export failed: $e");
//     }
//   }

//   void _showSnack(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//   }

//   // ────────────────────────────────
//   // UI
//   // ────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Products"),
//         actions: [
//           PopupMenuButton<String>(
//             icon: const Icon(Icons.download_rounded),
//             onSelected: (v) {
//               final items = context.read<ProductProvider>().paginatedProducts;
//               if (v == 'csv') _exportCsv(items);
//               if (v == 'pdf') _exportPdf(items);
//             },
//             itemBuilder: (ctx) => const [
//               PopupMenuItem(value: "pdf", child: Text("Export PDF")),
//               PopupMenuItem(value: "csv", child: Text("Export CSV")),
//             ],
//           )
//         ],
//       ),
//       body: SafeArea(
//         child: Consumer<ProductProvider>(
//           builder: (context, prov, _) {
//             if (prov.loading && prov.products.isEmpty) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             if (prov.error != null && prov.products.isEmpty) {
//               return _buildError(prov.error!);
//             }

//             return RefreshIndicator(
//               onRefresh: () => prov.fetchProducts(),
//               child: Column(
//                 children: [
//                   _buildSearchField(),
//                   _buildSortFilterRow(prov),
//                   Expanded(child: _buildProductList(prov)),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//       floatingActionButton: _buildFAB(),
//     );
//   }

//   Widget _buildError(String msg) {
//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text("Error: $msg"),
//           ElevatedButton(
//             onPressed: () => context.read<ProductProvider>().fetchProducts(),
//             child: const Text("Retry"),
//           )
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchField() {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: TextField(
//         controller: _searchController,
//         onChanged: _onSearchChanged,
//         decoration: InputDecoration(
//           prefixIcon: const Icon(Icons.search),
//           hintText: "Search products...",
//           suffixIcon: _searchController.text.isNotEmpty
//               ? IconButton(
//                   icon: const Icon(Icons.clear),
//                   onPressed: () {
//                     _searchController.clear();
//                     context.read<ProductProvider>().setSearchTerm('');
//                   },
//                 )
//               : null,
//         ),
//       ),
//     );
//   }



//   Widget _buildSortChip(ProductProvider prov, String label, SortBy sort) {
//     final selected = prov.sortBy == sort;

//     return Padding(
//       padding: const EdgeInsets.only(left: 8),
//       child: ChoiceChip(
//         label: Text(label),
//         selected: selected,
//         onSelected: (_) => prov.setSort(
//           sort,
//           ascending: selected ? !prov.sortAsc : true,
//         ),
//       ),
//     );
//   }
