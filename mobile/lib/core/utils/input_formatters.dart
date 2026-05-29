import 'package:flutter/services.dart';

class AcademicYearFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final capped = digits.length > 8 ? digits.substring(0, 8) : digits;
    final formatted = capped.length > 4
        ? '${capped.substring(0, 4)}/${capped.substring(4)}'
        : capped;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
