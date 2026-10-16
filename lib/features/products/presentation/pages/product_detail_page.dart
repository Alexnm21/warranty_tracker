import 'package:flutter/material.dart';

/// Placeholder for the product detail screen.
///
/// Currently a stub rendered by the `/products/:id` route; the real
/// implementation (fields, derived warranty status, edit/delete actions)
/// lands in a later step.
class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.productId});

  /// Id of the product to display, taken from the route path parameters.
  final int productId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
  }
}
