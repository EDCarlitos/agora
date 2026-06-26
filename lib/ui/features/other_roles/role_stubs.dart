import 'package:flutter/material.dart';
import '../../../../data/models/user.dart';
import '../../../../data/services/auth_service.dart';

class RoleDashboardStub extends StatelessWidget {
  final User user;
  final VoidCallback onLogout;

  const RoleDashboardStub({
    super.key,
    required this.user,
    required this.onLogout,
  });

  void _handleLogout(BuildContext context) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas salir de tu cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Custom properties based on the role to make them feel unique
    Color roleColor;
    IconData roleIcon;
    String roleDescription;
    List<String> mockTasks;

    switch (user.role) {
      case UserRole.limpieza:
        roleColor = Colors.teal;
        roleIcon = Icons.cleaning_services_outlined;
        roleDescription = 'Panel de Limpieza de Aulas y Áreas Comunes';
        mockTasks = [
          'Limpieza programada - Edificio A, Piso 2 (Pendiente)',
          'Reporte de derrame - Biblioteca (En Proceso)',
          'Limpieza general - Auditorio Principal (Completado)',
        ];
        break;
      case UserRole.mantenimiento:
        roleColor = Colors.orange;
        roleIcon = Icons.build_outlined;
        roleDescription = 'Panel de Mantenimiento de Infraestructura y Equipos';
        mockTasks = [
          'Reparación de aire acondicionado - Laboratorio de Física (Asignado)',
          'Reemplazo de luminarias - Pasillo Edificio C (Completado)',
          'Revisión de cableado eléctrico - Planta Baja (Pendiente)',
        ];
        break;
      case UserRole.sistemas:
        roleColor = Colors.purple;
        roleIcon = Icons.computer_outlined;
        roleDescription = 'Panel de Soporte de Sistemas TI y Redes';
        mockTasks = [
          'Configuración de router - Edificio D (Pendiente)',
          'Actualización de servidor de base de datos (En Proceso)',
          'Restablecimiento de credenciales - Estudiante Carlos (Completado)',
        ];
        break;
      case UserRole.administrador:
        roleColor = Colors.red;
        roleIcon = Icons.admin_panel_settings_outlined;
        roleDescription = 'Panel de Control y Administración General';
        mockTasks = [
          'Auditoría de reportes semanales (Pendiente)',
          'Gestión de usuarios y asignación de roles (Al día)',
          'Configuración de parámetros globales del sistema (Listo)',
        ];
        break;
      default:
        roleColor = theme.colorScheme.primary;
        roleIcon = Icons.dashboard_outlined;
        roleDescription = 'Panel de Control';
        mockTasks = [];
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(roleIcon, color: roleColor),
            const SizedBox(width: 8),
            Text(user.role.displayName),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar Sesión',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon badge
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: roleColor.withOpacity(0.15),
                    child: Icon(roleIcon, size: 40, color: roleColor),
                  ),
                  const SizedBox(height: 24),

                  // Greeting & Info
                  Text(
                    '¡Bienvenido, ${user.name}!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.email,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    roleDescription,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: roleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Mock Tasks Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.assignment_outlined, color: roleColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Tareas y Asignaciones Activas',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          if (mockTasks.isEmpty)
                            const Text('No hay asignaciones en este momento.')
                          else
                            ...mockTasks.map((task) {
                              final isCompleted = task.contains('(Completado)') || task.contains('(Listo)') || task.contains('(Al día)');
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                      size: 18,
                                      color: isCompleted ? Colors.green : roleColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        task,
                                        style: TextStyle(
                                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                                          color: isCompleted ? theme.hintColor : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stub Warning Alert
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.blueGrey.withOpacity(0.2) : Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.blueGrey.withOpacity(0.4) : Colors.blue.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Esta vista es un prototipo. El desarrollo completo de este rol se realizará en fases posteriores.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Secondary Logout Button
                  OutlinedButton.icon(
                    onPressed: () => _handleLogout(context),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Cerrar Sesión'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
