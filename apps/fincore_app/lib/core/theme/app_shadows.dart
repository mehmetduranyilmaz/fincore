import 'package:flutter/material.dart';

abstract final class AppShadows {
  static const List<BoxShadow> lightCard = [
    BoxShadow(color: Color(0x120F172A), blurRadius: 20, offset: Offset(0, 6)),
  ];

  static const List<BoxShadow> darkCard = [
    BoxShadow(color: Color(0x52000000), blurRadius: 24, offset: Offset(0, 8)),
  ];
}
