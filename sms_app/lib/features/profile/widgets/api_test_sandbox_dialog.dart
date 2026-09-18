import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/helpers/snackbar_helper.dart';

class ApiTestSandboxDialog extends StatefulWidget {
  final String deviceCode;

  const ApiTestSandboxDialog({
    super.key,
    required this.deviceCode,
  });

  static void show(BuildContext context, {required String deviceCode}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ApiTestSandboxDialog(deviceCode: deviceCode),
    );
  }

  @override
  State<ApiTestSandboxDialog> createState() => _ApiTestSandboxDialogState();
}

class _ApiTestSandboxDialogState extends State<ApiTestSandboxDialog> {
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController(
    text: 'Test message from SMSMitra API Sandbox.',
  );

  bool _isLoading = false;
  Map<String, dynamic>? _lastResponse;
  int? _statusCode;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _executeTestTrigger() async {
    final phone = _phoneController.text.trim();
    final message = _messageController.text.trim();

    if (phone.isEmpty) {
      MessageHelper.showError(context, 'Please enter a test phone number');
      return;
    }
    if (message.isEmpty) {
      MessageHelper.showError(context, 'Please enter a test message');
      return;
    }

    setState(() {
      _isLoading = true;
      _lastResponse = null;
      _errorMessage = null;
      _statusCode = null;
    });

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    try {
      final response = await dio.post<dynamic>(
        '${ApiConstants.baseUrl}/sms/trigger',
        data: {
          'deviceCode': widget.deviceCode,
          'phoneNumber': phone,
          'message': message,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': widget.deviceCode,
          },
        ),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusCode = response.statusCode;
          _lastResponse = response.data is Map<String, dynamic>
              ? response.data as Map<String, dynamic>
              : {'response': response.data.toString()};
        });
        MessageHelper.showSuccess(context, 'SMS Trigger dispatched to device!');
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusCode = e.response?.statusCode ?? 500;
          _errorMessage = e.response?.data is Map
              ? (e.response?.data['message']?.toString() ?? e.message)
              : (e.message ?? 'Unknown error');
          _lastResponse = e.response?.data is Map<String, dynamic>
              ? e.response?.data as Map<String, dynamic>
              : {'error': _errorMessage};
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusCode = 500;
          _errorMessage = e.toString();
          _lastResponse = {'error': e.toString()};
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final requestPayload = jsonEncode({
      'deviceCode': widget.deviceCode,
      'phoneNumber': _phoneController.text.trim().isEmpty
          ? '+919876543210'
          : _phoneController.text.trim(),
      'message': _messageController.text.trim(),
    });

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle and title
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
              ),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.science_rounded,
                        color: Colors.amber,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'API Test Sandbox',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Simulate an external API trigger request',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // API Endpoint Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'POST',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            '${ApiConstants.baseUrl}/sms/trigger',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Phone Input
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Recipient Phone Number',
                      hintText: '+919876543210',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Message Input
                  TextField(
                    controller: _messageController,
                    maxLines: 2,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'SMS Message Content',
                      hintText: 'Enter test message',
                      prefixIcon: const Icon(Icons.message_outlined),
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Execute Button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _executeTestTrigger,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _isLoading ? 'Dispatching Request...' : 'Send Test Request',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Live Request JSON Preview
                  Text(
                    'Request JSON Body',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF282C34),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SelectableText(
                      const JsonEncoder.withIndent('  ').convert(
                        jsonDecode(requestPayload),
                      ),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Color(0xFF98C379),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Live Response JSON Preview
                  if (_lastResponse != null || _errorMessage != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Response Data',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (_statusCode != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _statusCode! >= 200 && _statusCode! < 300
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'HTTP $_statusCode',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _statusCode! >= 200 && _statusCode! < 300
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF282C34),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SelectableText(
                        const JsonEncoder.withIndent('  ').convert(
                          _lastResponse ?? {'error': _errorMessage},
                        ),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: _statusCode != null && _statusCode! >= 200 && _statusCode! < 300
                              ? const Color(0xFF61AFEF)
                              : const Color(0xFFE06C75),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
