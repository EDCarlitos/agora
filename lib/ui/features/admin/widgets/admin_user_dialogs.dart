import 'package:flutter/material.dart';
import '../../../../data/models/user.dart';
import '../../../core/theme.dart';
import '../../widgets/custom_buttons.dart';
import '../../widgets/custom_form_elements.dart';
import '../view_models/users_view_model.dart';

class AdminUserDialogs {
  static const List<UserRole> _officialRoles = [
    UserRole.estudiante,
    UserRole.sistemas,
    UserRole.administrador,
  ];

  static void showAddUserDialog(BuildContext context, UsersViewModel viewModel) {
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    UserRole selectedRole = UserRole.estudiante;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.person_add_outlined, color: AppTheme.primaryColor),
                  SizedBox(width: 10),
                  Text('Nuevo Usuario'),
                ],
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CustomLabel(text: 'Nombre de Usuario (username)'),
                      CustomTextField(
                        controller: usernameController,
                        hintText: 'Ej. carlos_estudiante',
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'Ingresa el nombre de usuario' : null,
                      ),
                      const SizedBox(height: 14),
                      const CustomLabel(text: 'Correo electrónico'),
                      CustomTextField(
                        controller: emailController,
                        hintText: 'ejemplo@univ.edu',
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Ingresa el correo';
                          if (!val.contains('@')) return 'Correo no válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      const CustomLabel(text: 'Contraseña'),
                      CustomTextField(
                        controller: passwordController,
                        hintText: 'Mínimo 6 caracteres',
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Ingresa la contraseña';
                          if (val.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      const CustomLabel(text: 'Rol en el sistema'),
                      CustomDropdown<UserRole>(
                        value: selectedRole,
                        hintText: 'Selecciona un rol',
                        items: _officialRoles.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(role.displayName),
                          );
                        }).toList(),
                        onChanged: (role) {
                          if (role != null) {
                            setModalState(() => selectedRole = role);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                AgoraSecondaryButton(
                  text: 'Cancelar',
                  onPressed: () => Navigator.pop(ctx),
                ),
                const SizedBox(width: 8),
                AgoraPrimaryButton(
                  text: 'Guardar',
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(ctx);
                      final success = await viewModel.addUser(
                        username: usernameController.text.trim(),
                        email: emailController.text.trim(),
                        password: passwordController.text,
                        role: selectedRole,
                      );

                      if (context.mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Usuario creado exitosamente.'),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${viewModel.errorMessage}'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  static void showEditUserDialog(BuildContext context, User user, UsersViewModel viewModel) {
    final usernameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final passwordController = TextEditingController();
    UserRole selectedRole = _officialRoles.contains(user.role) ? user.role : UserRole.estudiante;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
                  SizedBox(width: 10),
                  Text('Editar Usuario'),
                ],
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CustomLabel(text: 'Nombre de Usuario'),
                      CustomTextField(
                        controller: usernameController,
                        hintText: 'Ej. carlos_estudiante',
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'Ingresa el usuario' : null,
                      ),
                      const SizedBox(height: 14),
                      const CustomLabel(text: 'Correo electrónico'),
                      CustomTextField(
                        controller: emailController,
                        hintText: 'ejemplo@univ.edu',
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Ingresa el correo';
                          if (!val.contains('@')) return 'Correo no válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      const CustomLabel(text: 'Nueva contraseña (Opcional)'),
                      CustomTextField(
                        controller: passwordController,
                        hintText: 'Dejar en blanco para mantener la actual',
                      ),
                      const SizedBox(height: 14),
                      const CustomLabel(text: 'Rol en el sistema'),
                      CustomDropdown<UserRole>(
                        value: selectedRole,
                        hintText: 'Selecciona un rol',
                        items: _officialRoles.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(role.displayName),
                          );
                        }).toList(),
                        onChanged: (role) {
                          if (role != null) {
                            setModalState(() => selectedRole = role);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                AgoraSecondaryButton(
                  text: 'Cancelar',
                  onPressed: () => Navigator.pop(ctx),
                ),
                const SizedBox(width: 8),
                AgoraPrimaryButton(
                  text: 'Actualizar',
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(ctx);
                      final success = await viewModel.updateUser(
                        id: user.id,
                        username: usernameController.text.trim(),
                        email: emailController.text.trim(),
                        password: passwordController.text.isNotEmpty ? passwordController.text : null,
                        role: selectedRole,
                      );

                      if (context.mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Usuario actualizado exitosamente.'),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${viewModel.errorMessage}'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  static void showDeleteConfirmationDialog(BuildContext context, User user, UsersViewModel viewModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor),
            SizedBox(width: 10),
            Text('Eliminar Usuario'),
          ],
        ),
        content: Text('¿Deseas eliminar permanentemente al usuario "${user.name}" (${user.email})?'),
        actions: [
          AgoraSecondaryButton(
            text: 'Cancelar',
            onPressed: () => Navigator.pop(ctx),
          ),
          const SizedBox(width: 8),
          AgoraPrimaryButton(
            text: 'Eliminar',
            backgroundColor: AppTheme.errorColor,
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await viewModel.removeUser(user);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Usuario "${user.name}" eliminado.'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${viewModel.errorMessage}'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
