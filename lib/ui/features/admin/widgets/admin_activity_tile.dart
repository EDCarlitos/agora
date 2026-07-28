import 'package:flutter/material.dart';

class AdminActivityTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;
  final bool isDark;

  const AdminActivityTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: iconColor.withValues(alpha: 0.15),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
      ),
      trailing: Text(
        time,
        style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
      ),
    );
  }
}
