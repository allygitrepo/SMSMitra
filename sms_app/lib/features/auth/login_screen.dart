import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_app/data/services/storage_service.dart';
import '../../core/helpers/validation_helper.dart';
import '../../core/helpers/snackbar_helper.dart';
import '../../core/routes/app_router.dart';
import '../../core/errors/app_exceptions.dart';
import '../../data/repositories/auth_repository.dart';
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

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final result = await ref.read(authRepositoryProvider).login(
          _identityController.text.trim(),
          _passwordController.text,
        );

        if (!mounted) return;
        setState(() => _isLoading = false);

        MessageHelper.showSuccess(context, result['message'] ?? 'Login successful');

        final hasSims = result['hasSimDetails'] ?? false;
        if (hasSims && StorageService.isSimConfigured()) {
          context.go(AppRouter.home);
        } else if (!hasSims) {
          context.go(AppRouter.setupSim);
        } else {
          context.go(AppRouter.settings);
        }
      } on AppException catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        MessageHelper.showError(context, e.message);
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        MessageHelper.showError(context, 'Login failed: ${e.toString()}');
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
                    label: 'Email',
                    hint: 'Enter registered email',
                    icon: Icons.email_outlined,
                    controller: _identityController,
                    keyboardType: TextInputType.emailAddress,
                    validator: ValidationHelper.validateEmail,
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
