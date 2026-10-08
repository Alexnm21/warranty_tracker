import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ProductListView extends StatelessWidget {
  const ProductListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('shell.products'.tr()));
  }
}
