import 'package:flutter/material.dart';

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;

  static BorderRadius get smBorderRadius =>
      const BorderRadius.all(Radius.circular(sm));
  static BorderRadius get mdBorderRadius =>
      const BorderRadius.all(Radius.circular(md));
  static BorderRadius get lgBorderRadius =>
      const BorderRadius.all(Radius.circular(lg));
  static BorderRadius get xlBorderRadius =>
      const BorderRadius.all(Radius.circular(xl));
  static BorderRadius get pillBorderRadius =>
      const BorderRadius.all(Radius.circular(pill));
}
