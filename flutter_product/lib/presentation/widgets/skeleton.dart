import 'package:flutter/material.dart';

class ProductTileSkeleton extends StatelessWidget {
  const ProductTileSkeleton({Key? key}) : super(key: key);

  Widget _buildPlaceholder(
    double height, [
    double? width,
    double radius = 8,
  ]) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: _buildPlaceholder(48, 48, 8),
        title: _buildPlaceholder(16, 150),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildPlaceholder(14, 200),
            const SizedBox(height: 6),
            _buildPlaceholder(12, 100),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPlaceholder(24, 24, 6),
            const SizedBox(width: 16),
            _buildPlaceholder(24, 24, 6),
          ],
        ),
      ),
    );
  }
}