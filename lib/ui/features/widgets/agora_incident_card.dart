import 'package:flutter/material.dart';
import '../../../../data/models/report.dart';
import '../../core/theme.dart';
import '../widgets/agora_network_image.dart';

class AgoraIncidentCard extends StatelessWidget {
  final Report report;
  final VoidCallback? onTap;
  final List<Widget>? actions;
  final Color? headerIconColor;

  const AgoraIncidentCard({
    super.key,
    required this.report,
    this.onTap,
    this.actions,
    this.headerIconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = headerIconColor ?? AppTheme.primaryColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: isDark ? AppTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFEFEBE7),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // PARTE SUPERIOR: Diseño Compacto
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Imagen o Icono
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: report.imageUrl != null
                        ? AgoraNetworkImage(
                            imageUrl: report.imageUrl!,
                            borderRadius: BorderRadius.circular(10),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.computer_outlined, color: iconColor, size: 24),
                          ),
                  ),
                  const SizedBox(width: 12),
                  
                  // 2. Título y Ubicación
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                            color: isDark ? Colors.white : AppTheme.secondaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                report.classroom,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 3. Tiempo (timeAgo del ViewModel)
                  Text(
                    report.timeAgo,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            // PARTE INFERIOR: Botones (Solo si la vista inyecta acciones, ej. Sistemas)
            if (actions != null && actions!.isNotEmpty) ...[
              Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFEFEBE7)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: actions!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}