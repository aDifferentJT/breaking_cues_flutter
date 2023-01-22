extension StringUtils on String {
  String trimLeadingInteger() =>
      RegExp(r'^\d*\s*(.+)$').firstMatch(this)?.group(1) ?? this;
}
