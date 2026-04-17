import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/helpers/validation_helper.dart';
import '../../core/helpers/snackbar_helper.dart';
import '../../core/routes/app_router.dart';
import '../../data/services/sms_service.dart';
import '../../data/services/auth_service.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/gradient_button.dart';

/// The main operational screen of the app where users send SMS.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  final _smsService = SmsService();
  bool _isSending = false;

  Future<void> _handleSend() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSending = true);
      
      try {
        final permission = await _smsService.requestPermissions();
        if (!permission) {
          if (mounted) {
            MessageHelper.showError(context, 'SMS Permission denied. Please enable in settings.');
          }
          return;
        }

        await _smsService.sendSms(
          number: _phoneController.text.trim(),
          message: _messageController.text.trim(),
        );

        if (mounted) {
          MessageHelper.showSuccess(context, 'SMS sent successfully!');
          _messageController.clear(); // Clear message after success
        }
      } catch (e) {
        if (mounted) {
          MessageHelper.showError(context, 'Failed to send SMS: $e');
        }
      } finally {
        if (mounted) {
          setState(() => _isSending = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Message'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRouter.settings),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await AuthService().logout();
              if (mounted) context.go(AppRouter.login);
            },
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              CustomTextField(
                label: 'Receiver Number',
                hint: 'e.g. +91 9876543210',
                icon: Icons.contact_phone_outlined,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: ValidationHelper.validatePhone,
              ),
              
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Message',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                maxLength: 160,
                validator: (val) => ValidationHelper.validateNotEmpty(val, 'Message'),
                decoration: InputDecoration(
                  hintText: 'Type your message here...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              GradientButton(
                text: 'Send Message',
                onPressed: _handleSend,
                isLoading: _isSending,
              ),
              
              const SizedBox(height: 40),
              _buildTipsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.1)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                'Helpful Tips',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '• Ensure your selected SIM has an active SMS plan.\n'
            '• Keep messages short to avoid carrier splits.\n'
            '• Double-check the receiver\'s country code.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
