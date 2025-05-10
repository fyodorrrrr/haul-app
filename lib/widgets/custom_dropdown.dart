import 'package:flutter/material.dart';

class CustomDropdown<T> extends StatelessWidget {
  final T? selectedValue;
  final List<T> items;
  final String hint;
  final ValueChanged<T?> onChanged;

  CustomDropdown({
    required this.items,
    required this.onChanged,
    this.selectedValue,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<T>(
      value: selectedValue,
      hint: Text(hint),
      isExpanded: true,
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(item.toString()),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
