import 'package:flutter/material.dart';
import '../../widgets/user_card.dart';
import '../view_models/users_view_model.dart';

class UsersView extends StatefulWidget {
  final UsersViewModel viewModel;
  final VoidCallback onLogout;

  const UsersView({
    super.key,
    required this.viewModel,
    required this.onLogout,
  });

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0E8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF3D2B1F)),
          onPressed: () {},
        ),
        title: Text(
          'Ágora',
          style: TextStyle(
            color: const Color(0xFFB5541A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: widget.onLogout,
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF3D2B1F),
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              'Users',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3D2B1F),
                height: 1.1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              'Manage institutional access, assign specific\nroles, and oversee the Ágora community\necosystem.',
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF7A6050),
                height: 1.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: 'Search by name or email...',
                  hintStyle: TextStyle(color: Color(0xFFAA9988), fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Color(0xFFAA9988)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.viewModel,
              builder: (context, _) {
                final filtered = widget.viewModel.users.where((u) {
                  final q = _searchQuery.toLowerCase();
                  return u.name.toLowerCase().contains(q) ||
                      u.email.toLowerCase().contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No se encontraron usuarios.',
                      style: TextStyle(color: Color(0xFF7A6050)),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    return UserCard(
                      user: user,
                      onEdit: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Editar ${user.name}')),
                      ),
                      onDelete: () => widget.viewModel.removeUser(user),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: registrar nuevo usuario
        },
        backgroundColor: const Color(0xFFB5541A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}