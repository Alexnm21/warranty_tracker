import 'package:flutter/widgets.dart';

extension WidgetExtensions on Widget {
  Widget withPadding(EdgeInsetsGeometry padding) {
    return Padding(padding: padding, child: this);
  }
}
