import 'package:flutter/material.dart';
import '../../../../data/models/report.dart';
import '../../core/theme.dart';
import '../widgets/agora_network_image.dart';

class AgoraHorizontalIncidentCard extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;

  const AgoraHorizontalIncidentCard({
    super.key,
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEFEBE7),
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PARTE SUPERIOR: Imagen
            SizedBox(
              height: 90,
              width: double.infinity,
              child: report.imageUrl != null
                  ? AgoraNetworkImage(
                      imageUrl: report.imageUrl!,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: const Icon(Icons.computer, color: AppTheme.primaryColor),
                    ),
            ),
            
            // PARTE INFERIOR: Textos
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 13,
                      color: isDark ? Colors.white : AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          report.classroom,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
