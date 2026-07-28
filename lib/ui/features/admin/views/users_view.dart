import 'package:flutter/material.dart';
import '../../../../data/models/user.dart';
import '../../../../data/services/auth_service.dart';
import '../../../core/theme.dart';
import '../../widgets/custom_buttons.dart';
import '../../widgets/custom_empty_state.dart';
import '../../widgets/custom_form_elements.dart';
import '../../widgets/user_card.dart';
import '../view_models/users_view_model.dart';

class UsersView extends StatefulWidget {
  final User? currentUser;
  final UsersViewModel viewModel;
  final VoidCallback onLogout;
  final VoidCallback? onOpenDrawer;

  const UsersView({
    super.key,
    this.currentUser,
    required this.viewModel,
    required this.onLogout,
    this.onOpenDrawer,
  });

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  String _searchQuery = '';
  UserRole? _selectedRoleFilter;

  // Los 3 roles oficiales soportados por la API
  static const List<UserRole> _officialRoles = [
    UserRole.estudiante,
    UserRole.sistemas,
    UserRole.administrador,
  ];

  @override
  void initState() {
    super.initState();
    // Cargar la lista real de usuarios desde la API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadUsers();
    });
  }

  void _showAddUserDialog() {
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
                      const CustomLabel(text: 'Rol (Roles Permitidos: 3)'),
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
                  text: 'Guardar en API',
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(ctx);
                      final success = await widget.viewModel.addUser(
                        username: usernameController.text.trim(),
                        email: emailController.text.trim(),
                        password: passwordController.text,
                        role: selectedRole,
                      );

                      if (mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Usuario creado exitosamente en la API.'),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${widget.viewModel.errorMessage}'),
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

  void _showEditUserDialog(User user) {
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
                  text: 'Actualizar en API',
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(ctx);
                      final success = await widget.viewModel.updateUser(
                        id: user.id,
                        username: usernameController.text.trim(),
                        email: emailController.text.trim(),
                        password: passwordController.text.isNotEmpty ? passwordController.text : null,
                        role: selectedRole,
                      );

                      if (mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Usuario actualizado en la API.'),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${widget.viewModel.errorMessage}'),
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

  void _showDeleteConfirmationDialog(User user) {
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
        content: Text('¿Deseas eliminar permanentemente al usuario "${user.name}" (${user.email}) de la API?'),
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
              final success = await widget.viewModel.removeUser(user);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Usuario "${user.name}" eliminado de la API.'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${widget.viewModel.errorMessage}'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gestión de Usuarios',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Consulta y gestiona las cuentas conectadas a agora(Roles: Estudiante, Sistemas, Admin).',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryColor),
                    tooltip: 'Recargar usuarios de la API',
                    onPressed: () => widget.viewModel.loadUsers(),
                  ),
                ],
              ),
            ),

            // Buscador por Texto
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppTheme.secondaryColor.withValues(alpha: 0.15),
                  ),
                ),
                child: TextField(
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                    widget.viewModel.loadUsers(
                      search: val.trim().isNotEmpty ? val.trim() : null,
                      role: _selectedRoleFilter,
                    );
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o correo...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              setState(() => _searchQuery = '');
                              widget.viewModel.loadUsers(
                                search: null,
                                role: _selectedRoleFilter,
                              );
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),

            // Filtros de Rol (Chips Horizontal - 3 Roles del Sistema)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Todos'),
                    selected: _selectedRoleFilter == null,
                    onSelected: (_) {
                      setState(() => _selectedRoleFilter = null);
                      widget.viewModel.loadUsers(
                        search: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
                        role: null,
                      );
                    },
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  ..._officialRoles.map((role) {
                    final isSelected = _selectedRoleFilter == role;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(role.displayName),
                        selected: isSelected,
                        onSelected: (_) {
                          final newRole = isSelected ? null : role;
                          setState(() => _selectedRoleFilter = newRole);
                          widget.viewModel.loadUsers(
                            search: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
                            role: newRole,
                          );
                        },
                        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                        checkmarkColor: AppTheme.primaryColor,
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Lista Reactiva de Usuarios desde la API
            Expanded(
              child: ListenableBuilder(
                listenable: widget.viewModel,
                builder: (context, _) {
                  if (widget.viewModel.isLoading && widget.viewModel.users.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryColor),
                    );
                  }

                  if (widget.viewModel.errorMessage != null && widget.viewModel.users.isEmpty) {
                    return CustomEmptyState(
                      icon: Icons.error_outline_rounded,
                      message: 'Error al conectar con la API:\n${widget.viewModel.errorMessage}',
                    );
                  }

                  final filteredUsers = widget.viewModel.users.where((u) {
                    final matchesQuery = u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        u.email.toLowerCase().contains(_searchQuery.toLowerCase());
                    final matchesRole = _selectedRoleFilter == null || u.role == _selectedRoleFilter;
                    return matchesQuery && matchesRole;
                  }).toList();

                  if (filteredUsers.isEmpty) {
                    return const CustomEmptyState(
                      icon: Icons.person_search_outlined,
                      message: 'No se encontraron usuarios en la base de datos.',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => widget.viewModel.loadUsers(),
                    color: AppTheme.primaryColor,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return UserCard(
                          user: user,
                          onEdit: () => _showEditUserDialog(user),
                          onDelete: () => _showDeleteConfirmationDialog(user),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Botón Flotante para Agregar Usuario
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Nuevo Usuario', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}