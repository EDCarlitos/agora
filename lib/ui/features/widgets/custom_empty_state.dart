import 'package:flutter/material.dart';

class CustomEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const CustomEmptyState({
    super.key,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              size: 64, 
              color: isDark ? Colors.white24 : Colors.black26
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15, 
                fontWeight: FontWeight.w500, 
                color: isDark ? Colors.white54 : Colors.black54
              ),
            ),
          ],
        ),
      ),
    );
  }
}