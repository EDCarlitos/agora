import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterPressed;
  final String hintText;

  const SearchBarWidget({
    super.key,
    this.controller,
    this.onChanged,
    this.onFilterPressed,
    this.hintText =
        'Buscar por ID, aula, categoría o usuario...',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
            ),
          ),
        ),

        const SizedBox(width: 12),

        Material(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onFilterPressed,
            child: const SizedBox(
              width: 56,
              height: 56,
              child: Icon(
                Icons.tune,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}