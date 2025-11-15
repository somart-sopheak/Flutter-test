//   import 'package:flutter/material.dart';
// import 'package:flutter_product/providers/product_provider.dart';

// Widget _buildSortFilterRow(ProductProvider prov) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Card(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         child: Padding(
//           padding: const EdgeInsets.all(8),
//           child: Row(
//             children: [
//               const Text("Sort:"),
//               const SizedBox(width: 8),
//               _buildSortChip(prov, "None", SortBy.none),
//               _buildSortChip(prov, "Price", SortBy.price),
//               _buildSortChip(prov, "Stock", SortBy.stock),
//               const Spacer(),
//               TextButton.icon(
//                 onPressed: _showFilterSheet,
//                 icon: const Icon(Icons.filter_list),
//                 label: const Text("Filters"),
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }