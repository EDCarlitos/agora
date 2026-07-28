import 'package:flutter/material.dart';
import '../../../../data/models/user.dart';
import '../../../core/theme.dart';
import '../../widgets/custom_empty_state.dart';
import '../../widgets/user_card.dart';
import '../view_models/users_view_model.dart';
import '../widgets/admin_search_filter_bar.dart';
import '../widgets/admin_user_dialogs.dart';

class UsersView extends StatefulWidget {
  final User? currentUser;
  final UsersViewModel viewModel;
  final VoidCallback onLogout;

  const UsersView({
    super.key,
    this.currentUser,
    required this.viewModel,
    required this.onLogout,
  });

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  String _searchQuery = '';
  UserRole? _selectedRoleFilter;

  static const List<UserRole> _officialRoles = [
    UserRole.estudiante,
    UserRole.sistemas,
    UserRole.administrador,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadUsers();
    });
  }

  void _triggerSearch(String query) {
    setState(() => _searchQuery = query);
    widget.viewModel.loadUsers(
      search: query.trim().isNotEmpty ? query.trim() : null,
      role: _selectedRoleFilter,
    );
  }

  void _triggerFilter(UserRole? role) {
    setState(() => _selectedRoleFilter = role);
    widget.viewModel.loadUsers(
      search: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
      role: role,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                          'Consulta y gestiona las cuentas conectadas a agora (Roles: Estudiante, Sistemas, Admin).',
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
                    onPressed: () => _triggerSearch(_searchQuery),
                  ),
                ],
              ),
            ),

            // Buscador por Texto y Filtros por Chips
            AdminSearchFilterBar<UserRole>(
              searchQuery: _searchQuery,
              searchHint: 'Buscar por nombre o correo...',
              onSearchChanged: _triggerSearch,
              onClearSearch: () => _triggerSearch(''),
              filterOptions: _officialRoles,
              selectedFilter: _selectedRoleFilter,
              onFilterSelected: _triggerFilter,
              getLabel: (role) => role.displayName,
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

                  final users = widget.viewModel.users;

                  if (users.isEmpty) {
                    return const CustomEmptyState(
                      icon: Icons.person_search_outlined,
                      message: 'No se encontraron usuarios en la base de datos.',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => widget.viewModel.loadUsers(
                      search: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
                      role: _selectedRoleFilter,
                    ),
                    color: AppTheme.primaryColor,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return UserCard(
                          user: user,
                          onEdit: () => AdminUserDialogs.showEditUserDialog(context, user, widget.viewModel),
                          onDelete: () => AdminUserDialogs.showDeleteConfirmationDialog(context, user, widget.viewModel),
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
        onPressed: () => AdminUserDialogs.showAddUserDialog(context, widget.viewModel),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Nuevo Usuario', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}