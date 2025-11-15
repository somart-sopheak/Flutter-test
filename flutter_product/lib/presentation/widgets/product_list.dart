//   import 'package:flutter/material.dart';
// import 'package:flutter_product/presentation/screens/add_edit_product_screen.dart';
// import 'package:flutter_product/presentation/widgets/product_tile.dart';
// import 'package:flutter_product/providers/product_provider.dart';

// Widget buildProductList(ProductProvider prov) {
//     final items = prov.paginatedProducts;

//     if (items.isEmpty) {
//       return const Center(child: Text("No products found"));
//     }

//     return ListView.builder(
//       controller: _scrollController,
//       itemCount: items.length + (prov.hasMore ? 1 : 0),
//       itemBuilder: (ctx, index) {
//         if (index >= items.length) {
//           return const Padding(
//             padding: EdgeInsets.all(16),
//             child: Center(child: CircularProgressIndicator()),
//           );
//         }

//         final product = items[index];

//         return ProductTile(
//           product: product,
//           onEdit: (p) async {
//             final updated = await Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => AddEditProductScreen(product: p)),
//             );
//             if (updated == true) prov.fetchProducts();
//           },
//           onDelete: (p) async {
//             final success = await prov.deleteProduct(p.id!);
//             if (!success) _showSnack("Delete failed");
//           },
//         );
//       },
//     );
//   }

//   Widget _buildFAB() {
//     return FloatingActionButton.extended(
//       icon: const Icon(Icons.add),
//       label: const Text("New Product"),
//       onPressed: () async {
//         final created = await Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
//         );
//         if (created == true) {
//           context.read<ProductProvider>().fetchProducts();
//         }
//       },
//     );
//   }
// }
