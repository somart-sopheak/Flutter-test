import 'package:flutter/material.dart';
import '../../providers/product_provider.dart';

class SortControls extends StatelessWidget {
  final ProductProvider prov;
  final VoidCallback onShowFilter;
  const SortControls({Key? key, required this.prov, required this.onShowFilter})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            // Wrap chips in Expanded so they can wrap to the next line if needed
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Sort:'),
                  ChoiceChip(
                    label: const Text('None'),
                    selected: prov.sortBy == SortBy.none,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: Colors.grey.shade100,
                    labelStyle:
                        prov.sortBy == SortBy.none
                            ? const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            )
                            : null,
                    onSelected: (_) => prov.setSort(SortBy.none),
                  ),
                  ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Price',
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
                            color: Colors.white70,
                          ),
                      ],
                    ),
                    selected: prov.sortBy == SortBy.price,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: Colors.grey.shade100,
                    onSelected:
                        (_) => prov.setSort(
                          SortBy.price,
                          ascending:
                              prov.sortBy == SortBy.price
                                  ? !prov.sortAsc
                                  : true,
                        ),
                  ),
                  ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Stock',
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
                            color: Colors.white70,
                          ),
                      ],
                    ),
                    selected: prov.sortBy == SortBy.stock,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: Colors.grey.shade100,
                    onSelected:
                        (_) => prov.setSort(
                          SortBy.stock,
                          ascending:
                              prov.sortBy == SortBy.stock
                                  ? !prov.sortAsc
                                  : true,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onShowFilter,
              icon: Icon(
                Icons.filter_list,
                color: Theme.of(context).colorScheme.primary,
              ),
              label: Text(
                'Filters',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
