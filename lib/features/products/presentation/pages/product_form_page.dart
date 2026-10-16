import 'package:flutter/material.dart';

/// Placeholder for the shared product create/edit screen.
///
/// Currently a stub rendered by the `/products/new` and `/products/:id/edit`
/// routes. When [productId] is `null` the form will create a product;
/// otherwise it will edit the existing one. The real form lands in a later step.
class ProductFormPage extends StatelessWidget {
  const ProductFormPage({super.key, this.productId});

  /// Id of the product being edited, or `null` to create a new product.
  final int? productId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
  }
}
