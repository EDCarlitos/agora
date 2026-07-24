import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Componente reutilizable para las etiquetas de los formularios
class CustomLabel extends StatelessWidget {
  final String text;

  const CustomLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: AppTheme.secondaryColor,
        ),
      ),
    );
  }
}

/// Componente reutilizable para los campos de texto
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(hintText: hintText),
      validator: validator,
    );
  }
}

/// Componente reutilizable para los menús desplegables
class CustomDropdown<T> extends StatelessWidget {
  final T? value;
  final String hintText;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.hintText,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      hint: Text(hintText),
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }
}