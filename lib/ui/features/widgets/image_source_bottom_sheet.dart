import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';

class ImageSourceBottomSheet {
  static Future<ImageSource?> show(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF261D16) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2)),
            ),
            Text(
              'Seleccionar Origen de Imagen', 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.secondaryColor)
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOption(context, Icons.camera_alt_rounded, 'Cámara', AppTheme.primaryColor, ImageSource.camera),
                _buildOption(context, Icons.photo_library_rounded, 'Galería', Colors.blue, ImageSource.gallery),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
      },
    );
  }

  static Widget _buildOption(BuildContext context, IconData icon, String label, Color color, ImageSource source) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, source),
      child: Column(
        children: [
          CircleAvatar(radius: 28, backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}