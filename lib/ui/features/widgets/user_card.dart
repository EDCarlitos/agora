import 'package:flutter/material.dart';
import '../../../../data/models/user.dart';

class UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const UserCard({
    super.key,
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: const Color(0xFFD9CFC4),
                    child: Icon(
                      Icons.person,
                      size: 32,
                      color: const Color(0xFF7A6050),
                    ),
                  ),
                ),
                const Spacer(),
                // Badge de rol
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _badgeColor(user.role),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.role.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _badgeTextColor(user.role),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3D2B1F),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              user.email,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF7A6050),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFEDE8E0)),
            const SizedBox(height: 10),
            Row(
              children: [
                // Editar
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  color: const Color(0xFF7A6050),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                // Eliminar
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  color: const Color(0xFFCC4444),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const Spacer(),
                Text(
                  'Joined ${_formatDate()}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFAA9988),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Color _badgeColor(UserRole role) {
    switch (role) {
      case UserRole.administrador:
        return const Color(0xFFFFE8E8);
      case UserRole.estudiante:
        return const Color(0xFFEAEAEA);
      case UserRole.sistemas:
        return const Color(0xFFE8F0FF);
      case UserRole.limpieza:
        return const Color(0xFFE8F8EE);
      case UserRole.mantenimiento:
        return const Color(0xFFFFF3E0);
    }
  }

  Color _badgeTextColor(UserRole role) {
    switch (role) {
      case UserRole.administrador:
        return const Color(0xFFCC4444);
      case UserRole.estudiante:
        return const Color(0xFF555555);
      case UserRole.sistemas:
        return const Color(0xFF2255CC);
      case UserRole.limpieza:
        return const Color(0xFF226633);
      case UserRole.mantenimiento:
        return const Color(0xFF996600);
    }
  }
}