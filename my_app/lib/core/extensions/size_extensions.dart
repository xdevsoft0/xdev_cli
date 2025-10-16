import 'package:flutter/widgets.dart';

extension SizedBoxExt on num {
  SizedBox get h => SizedBox(height: toDouble());
  SizedBox get w => SizedBox(width: toDouble());
}
