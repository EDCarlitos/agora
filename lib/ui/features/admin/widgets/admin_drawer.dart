import 'package:flutter/material.dart';
import '../../../../data/models/user.dart';
import '../../../../data/services/auth_service.dart';
import '../../../core/theme.dart';
import '../../widgets/custom_buttons.dart';

class AdminDrawer extends StatelessWidget {
  final User user;
  final int selectedIndex;
  final ValueChanged<int> onSelectIndex;
  final VoidCallback onLogout;

  const AdminDrawer({
    super.key,
    required this.user,
    required this.selectedIndex,
    required this.onSelectIndex,
    required this.onLogout,
  });

  void _handleLogout(BuildContext context) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas salir del panel de administración?'),
        actions: [
          AgoraTextButton(
            text: 'Cancelar',
            onPressed: () => Navigator.pop(context, false),
          ),
          AgoraPrimaryButton(
            text: 'Cerrar Sesión',
            backgroundColor: theme.colorScheme.error,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().logout();
      onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'A',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            accountName: Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(user.email, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.role.displayName,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _DrawerItem(
            icon: Icons.dashboard_outlined,
            title: 'Resumen General',
            isSelected: selectedIndex == 0,
            onTap: () {
              onSelectIndex(0);
              Navigator.pop(context);
            },
          ),
          _DrawerItem(
            icon: Icons.people_alt_outlined,
            title: 'Gestión de Usuarios',
            isSelected: selectedIndex == 1,
            onTap: () {
              onSelectIndex(1);
              Navigator.pop(context);
            },
          ),
          _DrawerItem(
            icon: Icons.assessment_outlined,
            title: 'Dashboard de Reportes',
            isSelected: selectedIndex == 2,
            onTap: () {
              onSelectIndex(2);
              Navigator.pop(context);
            },
          ),
          _DrawerItem(
            icon: Icons.build_outlined,
            title: 'Dashboard de Incidencias',
            isSelected: selectedIndex == 3,
            onTap: () {
              onSelectIndex(3);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppTheme.errorColor),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.pop(context);
              _handleLogout(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.primaryColor : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.primaryColor : null,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.primaryColor.withValues(alpha: 0.1),
      onTap: onTap,
    );
  }
}
