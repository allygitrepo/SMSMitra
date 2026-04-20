import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/api_constants.dart';

class ApiIntegrationScreen extends StatelessWidget {
  const ApiIntegrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer API Guide'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildStep(
              '1',
              'Get Your Access Code',
              'Your unique 4-digit code is required for every request to identify your device gateway.',
            ),
            _buildStep(
              '2',
              'Endpoint URL',
              'Send a POST request to the following endpoint:',
              code: '${ApiConstants.baseUrl}${ApiConstants.triggerSms}',
            ),
            _buildStep(
              '3',
              'Request Payload',
              'Include the following JSON body in your request:',
              code: '''{
  "deviceCode": "YOUR_CODE",
  "phoneNumber": "+919876543210",
  "message": "Hello from API!"
}''',
            ),
            _buildStep(
              '4',
              'Authentication',
              'No API keys required. Your 4-digit Access Code handles the secure routing to your phone.',
            ),
            const SizedBox(height: 32),
            _buildTryItSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.code, color: Colors.orange, size: 40),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'API Integration',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Connect your web applications to this gateway.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String title, String desc, {String? code}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.orange,
                child: Text(
                  number,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Text(
              desc,
              style: const TextStyle(color: Colors.grey, height: 1.4),
            ),
          ),
          if (code != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        code,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18, color: Colors.white54),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTryItSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.flash_on, color: Colors.orange),
          const SizedBox(height: 12),
          const Text(
            'Ready to test?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Use our pre-built web tester to try your integration instantly.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
