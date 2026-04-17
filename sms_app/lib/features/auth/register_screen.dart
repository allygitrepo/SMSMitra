import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/helpers/validation_helper.dart';
import '../../core/helpers/snackbar_helper.dart';
import '../../core/routes/app_router.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/gradient_button.dart';

/// Screen for new users to register.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  
  bool _isLoading = false;
  final _authService = AuthService();

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final user = UserModel(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
      );

      final success = await _authService.register(user);
      
      setState(() => _isLoading = false);

      if (success && mounted) {
        MessageHelper.showSuccess(context, 'Registration successful! Please login.');
        context.go(AppRouter.login);
      } else if (mounted) {
        MessageHelper.showError(context, 'Registration failed. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join SMSMitra and start sending messages!',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                
                CustomTextField(
                  label: 'Full Name',
                  hint: 'Enter your name',
                  icon: Icons.person_outline,
                  controller: _nameController,
                  validator: ValidationHelper.validateName,
                ),
                
                CustomTextField(
                  label: 'Email Address',
                  hint: 'Enter your email',
                  icon: Icons.email_outlined,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: ValidationHelper.validateEmail,
                ),
                
                CustomTextField(
                  label: 'Phone Number',
                  hint: 'Enter your phone number',
                  icon: Icons.phone_android_outlined,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: ValidationHelper.validatePhone,
                ),
                
                CustomTextField(
                  label: 'Password',
                  hint: 'Enter password',
                  icon: Icons.lock_outline,
                  controller: _passwordController,
                  isPassword: true,
                  validator: ValidationHelper.validatePassword,
                ),
                
                CustomTextField(
                  label: 'Confirm Password',
                  hint: 'Confirm your password',
                  icon: Icons.lock_reset_outlined,
                  controller: _confirmController,
                  isPassword: true,
                  validator: (val) => ValidationHelper.validateConfirmPassword(
                    val, _passwordController.text,
                  ),
                ),
                
                const SizedBox(height: 12),
                GradientButton(
                  text: 'Register Now',
                  onPressed: _handleRegister,
                  isLoading: _isLoading,
                ),
                
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () => context.go(AppRouter.login),
                      child: const Text(
                        'Login',
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
    );
  }
}
