import 'package:flutter/material.dart';
import '../../../../data/models/report.dart';

class ReportCard extends StatelessWidget {
  final Report report;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final String trailingText;
  final bool isDark;

  const ReportCard({
    super.key,
    required this.report,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.trailingText = 'Hace 2h', // Puedes hacerlo dinámico después
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: isDark ? const Color(0xFF261D16) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFEFEBE7),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: report.imageUrl == null ? iconColor.withOpacity(0.12) : null,
            borderRadius: BorderRadius.circular(8),
            image: report.imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(report.imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: report.imageUrl == null ? Icon(icon, color: iconColor) : null,
        ),
        title: Text(
          report.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              report.classroom,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        trailing: Text(
          trailingText,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        onTap: onTap,
      ),
    );
  }
}