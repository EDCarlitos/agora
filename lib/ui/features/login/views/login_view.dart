import 'package:flutter/material.dart';
import '../../../../data/models/user.dart';
import '../../../core/theme.dart';
import '../view_models/login_view_model.dart';

class LoginView extends StatefulWidget {
  final Function(User) onLoginSuccess;

  const LoginView({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _viewModel = LoginViewModel();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text;
      final password = _passwordController.text;
      final user = await _viewModel.login(email, password);
      if (user != null && mounted) {
        widget.onLoginSuccess(user);
      }
    }
  }

  void _quickLogin(String email, String password) async {
    _emailController.text = email;
    _passwordController.text = password;
    final user = await _viewModel.login(email, password);
    if (user != null && mounted) {
      widget.onLoginSuccess(user);
    }
  }

  void _showQuickLoginMenu() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Accesos Rápidos (Desarrollo)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildQuickLoginRow('Estudiante', 'estudiante@univ.edu', Colors.blue),
                _buildQuickLoginRow('Limpieza', 'limpieza@univ.edu', Colors.teal),
                _buildQuickLoginRow('Mantenimiento', 'mantenimiento@univ.edu', Colors.orange),
                _buildQuickLoginRow('Sistemas', 'sistemas@univ.edu', Colors.purple),
                _buildQuickLoginRow('Administrador', 'admin@univ.edu', Colors.red),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickLoginRow(String label, String email, Color color) {
    return ListTile(
      leading: CircleAvatar(radius: 6, backgroundColor: color),
      title: Text(label),
      subtitle: Text(email),
      onTap: () {
        Navigator.pop(context);
        _quickLogin(email, 'password');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark ? Colors.white70 : AppTheme.secondaryColor;
    final mutedColor = isDark ? Colors.white38 : const Color(0xFF786253);

    return Scaffold(
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_viewModel.errorMessage!),
                  backgroundColor: theme.colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
              _viewModel.clearError();
            });
          }

          return Stack(
            children: [
              // Main content
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 20),
                            
                            // University Name Header
                            Text(
                              'UNIVERSIDAD POLITÉCNICA DE QUINTANA ROO',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                color: mutedColor.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Agora Serif Logo
                            Text(
                              'Ágora',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 48,
                                fontFamily: 'Georgia', // Elegant serif font matching the image
                                fontWeight: FontWeight.normal,
                                color: textColor,
                              ),
                            ),
                            
                            // Agora Subtitle
                            Text(
                              'Portal Institucional',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: mutedColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 48),

                            // Correo Label
                            Text(
                              'Correo Institucional',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Correo Input
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                hintText: 'ejemplo@upqroo.edu.mx',
                                prefixIcon: Icon(Icons.email_outlined, size: 20),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor ingresa tu correo';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(value.trim())) {
                                  return 'Ingresa un correo válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Contraseña Label
                            Text(
                              'Contraseña',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Contraseña Input
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                hintText: '• • • • • • • •',
                                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa tu contraseña';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Forgot Password Link
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Funcionalidad no implementada en este prototipo.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: Text(
                                  '¿Olvidaste tu contraseña?',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Login Button
                            ElevatedButton(
                              onPressed: _viewModel.isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: _viewModel.isLoading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Text('Iniciar Sesión'),
                                        SizedBox(width: 8),
                                        Text('→', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                            ),
                            const SizedBox(height: 48),

                            // Help/Contact footer
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  '¿Problemas de acceso? Contacta a ',
                                  style: TextStyle(fontSize: 12, color: mutedColor),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Soporte TI: soporte@upqroo.edu.mx'),
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Soporte TI.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Developer Key Button in top right corner (subtle and convenient)
              Positioned(
                top: 8,
                right: 8,
                child: SafeArea(
                  child: IconButton(
                    icon: Icon(
                      Icons.vpn_key_outlined,
                      color: mutedColor.withOpacity(0.5),
                      size: 20,
                    ),
                    tooltip: 'Accesos de prueba',
                    onPressed: _showQuickLoginMenu,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
