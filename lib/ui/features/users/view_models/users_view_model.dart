import 'package:flutter/material.dart';
import '../../../../data/models/user.dart';

class UsersViewModel extends ChangeNotifier {
  final List<User> _users = [];

  List<User> get users => List.unmodifiable(_users);

  void addUser(User user) {
    _users.add(user);
    notifyListeners();
  }

  void removeUser(User user) {
    _users.remove(user);
    notifyListeners();
  }

  void updateUser(User updatedUser) {
    final index = _users.indexWhere((u) => u.id == updatedUser.id);
    if (index != -1) {
      _users[index] = updatedUser;
      notifyListeners();
    }
  }
}
