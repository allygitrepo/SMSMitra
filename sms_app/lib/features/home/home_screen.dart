import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                content,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmText.toLowerCase().contains('exit') || 
                                        confirmText.toLowerCase().contains('logout') 
                                        ? Colors.redAccent 
                                        : Colors.orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(confirmText),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 24),
            
            _buildSectionHeader('Overview'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard('Sent Today', '12', Icons.send, Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Daily Limit', '100', Icons.timer, Colors.blue)),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatCard('Active Gateway', 'SIM 1 (Airtel)', Icons.router, Colors.green, isFullWidth: true),
            
            const SizedBox(height: 32),
            _buildSectionHeader('Quick Send'),
            const SizedBox(height: 12),
            _buildQuickSendForm(),
            
            const SizedBox(height: 32),
            _buildTipsCard(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          _buildPulseIndicator(),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gateway Service Active',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
              Text(
                'Waiting for web requests...',
                style: TextStyle(fontSize: 12, color: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPulseIndicator() {
    return Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.green, blurRadius: 4, spreadRadius: 2),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {bool isFullWidth = false}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSendForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            CustomTextField(
              label: 'Receiver Number',
              hint: '+91...',
              icon: Icons.phone_android,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: ValidationHelper.validatePhone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              maxLines: 3,
              validator: (val) => ValidationHelper.validateNotEmpty(val, 'Message'),
              decoration: InputDecoration(
                hintText: 'Type message...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              text: 'Send Now',
              onPressed: _handleSend,
              isLoading: _isSending,
            ),
          ],
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
