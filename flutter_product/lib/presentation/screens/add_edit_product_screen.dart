import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;
  const AddEditProductScreen({Key? key, this.product}) : super(key: key);

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _stockCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product?.name ?? '');
    _priceCtrl = TextEditingController(
      text: widget.product?.price.toString() ?? '',
    );
    _stockCtrl = TextEditingController(
      text: widget.product?.stock.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameCtrl.text.trim();
    final price = double.parse(_priceCtrl.text.trim());
    final stock = int.parse(_stockCtrl.text.trim());
    final prov = Provider.of<ProductProvider>(context, listen: false);
    bool ok;
    if (widget.product == null) {
      // Confirm before creating
      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Confirm Create'),
              content: Text(
                "Create product \"$name\" with \$${price.toStringAsFixed(2)} and $stock units?",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Create'),
                ),
              ],
            ),
      );
      if (confirm != true) return;

      ok = await prov.addProduct(
        Product(
          name: name,
          price: price,
          stock: stock,
          createdAt: DateTime.now(),
        ),
      );
    } else {
      final updated = widget.product!.copyWith(
        name: name,
        price: price,
        stock: stock,
      );
      ok = await prov.updateProduct(updated);
    }
    if (ok) {
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Action failed: ${prov.error}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add New Product'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isEditing
                              ? Icons.edit_outlined
                              : Icons.add_circle_outline,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isEditing
                              ? 'Update Product Details'
                              : 'Create New Product',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEditing
                              ? 'Modify the product information'
                              : 'Fill in the product details below',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Product Name Field
                  Text(
                    'Product Name',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Enter product name',
                      prefixIcon: const Icon(Icons.shopping_bag_outlined),
                      hintText: 'e.g., Laptop, Phone, etc.',
                    ),
                    validator:
                        (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Enter name'
                                : null,
                  ),
                  const SizedBox(height: 24),

                  // Price Field
                  Text('Price', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _priceCtrl,
                    decoration: InputDecoration(
                      labelText: 'Enter price',
                      prefixIcon: const Icon(Icons.attach_money),
                      hintText: '0.00',
                      prefixText: '\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter price';
                      final p = double.tryParse(v);
                      if (p == null || p < 0) return 'Enter valid price';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Stock Field
                  Text(
                    'Stock Quantity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _stockCtrl,
                    decoration: InputDecoration(
                      labelText: 'Enter stock quantity',
                      prefixIcon: const Icon(Icons.inventory_2_outlined),
                      hintText: '0',
                      suffixText: 'units',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter stock';
                      final s = int.tryParse(v);
                      if (s == null || s < 0) return 'Enter valid stock';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Type Field
                  // Type field removed as requested
                  const SizedBox(height: 8),
                  const SizedBox(height: 32),

                  // Submit Button
                  Consumer<ProductProvider>(
                    builder: (context, prov, _) {
                      return SizedBox(
                        width: double.infinity,
                        child:
                            prov.loading
                                ? Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                )
                                : ElevatedButton.icon(
                                  onPressed: _submit,
                                  icon: Icon(
                                    isEditing ? Icons.save : Icons.check,
                                  ),
                                  label: Text(
                                    isEditing
                                        ? 'Save Changes'
                                        : 'Create Product',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
