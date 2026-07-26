import 'package:flutter/material.dart';

class AgoraNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadiusGeometry? borderRadius;

  const AgoraNetworkImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        height: height,
        width: width,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: height ?? 150,
            width: width ?? double.infinity,
            color: isDark ? Colors.white10 : Colors.black12,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: height ?? 150,
            width: width ?? double.infinity,
            color: isDark ? Colors.black12 : Colors.grey.shade200,
            child: Icon(
              Icons.image_not_supported_rounded,
              color: Colors.grey.shade400,
              size: 40,
            ),
          );
        },
      ),
    );
  }
}