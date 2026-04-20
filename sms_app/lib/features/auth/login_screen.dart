import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_app/data/services/storage_service.dart';
import '../../core/helpers/validation_helper.dart';
import '../../core/helpers/snackbar_helper.dart';
import '../../core/routes/app_router.dart';
import '../../data/services/auth_service.dart';
import '../../data/providers/user_provider.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/gradient_button.dart';

/// Screen for registered users to login.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController(); // Email or Phone
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  final _authService = AuthService();

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final result = await _authService.login(
        _identityController.text.trim(),
        _passwordController.text,
      );

      if (mounted) setState(() => _isLoading = false);

      if (result['success'] && mounted) {
        ref.read(userProvider.notifier).refresh();
        MessageHelper.showSuccess(context, result['message']);

        // Navigate based on setup status
        if (StorageService.isSimConfigured()) {
          context.go(AppRouter.home);
        } else {
          context.go(AppRouter.settings);
        }
      } else if (mounted) {
        MessageHelper.showError(context, result['message']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/sms.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Login to continue sending messages.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 40),

                  CustomTextField(
                    label: 'Email or Phone',
                    hint: 'Enter registered email/phone',
                    icon: Icons.person_outline,
                    controller: _identityController,
                    validator: (val) =>
                        ValidationHelper.validateNotEmpty(val, 'Identity'),
                  ),

                  CustomTextField(
                    label: 'Password',
                    hint: 'Enter your password',
                    icon: Icons.lock_outline,
                    controller: _passwordController,
                    isPassword: true,
                    validator: ValidationHelper.validatePassword,
                  ),

                  const SizedBox(height: 20),
                  GradientButton(
                    text: 'Login',
                    onPressed: _handleLogin,
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      GestureDetector(
                        onTap: () => context.go(AppRouter.register),
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
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
    );
  }
}
