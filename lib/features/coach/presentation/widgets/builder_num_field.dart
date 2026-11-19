import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';

class BuilderNumField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDecimal;
  final ValueChanged<String> onChanged;

  const BuilderNumField({
    super.key,
    required this.controller,
    required this.hint,
    required this.isDecimal,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      textAlign: TextAlign.center,
      style: TextStyle(
          fontSize: DT.s4,
          fontWeight: FontWeight.w600,
          color: DT.of(context).textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: DT.of(context).textGrey),
        filled: true,
        fillColor: DT.of(context).bg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.rCardSmall),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(vertical: DT.s2),
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }
}
