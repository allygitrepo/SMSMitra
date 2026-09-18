import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/helpers/snackbar_helper.dart';

class ApiCodeSnippetsModal extends StatefulWidget {
  final String deviceCode;

  const ApiCodeSnippetsModal({
    super.key,
    required this.deviceCode,
  });

  static void show(BuildContext context, {required String deviceCode}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ApiCodeSnippetsModal(deviceCode: deviceCode),
    );
  }

  @override
  State<ApiCodeSnippetsModal> createState() => _ApiCodeSnippetsModalState();
}

class _ApiCodeSnippetsModalState extends State<ApiCodeSnippetsModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  final List<String> _languages = [
    'cURL',
    'Node.js',
    'Python',
    'PHP',
    'Dart',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _languages.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getBaseUrl() {
    return ApiConstants.baseUrl;
  }

  String _getCodeSnippet(int index) {
    final baseUrl = _getBaseUrl();
    final code = widget.deviceCode;

    switch (index) {
      case 0: // cURL
        return '''# Single SMS Dispatch
curl -X POST "$baseUrl/sms/trigger" \\
  -H "Content-Type: application/json" \\
  -H "x-api-key: $code" \\
  -d '{
    "phoneNumber": "+919876543210",
    "message": "Hello! Your OTP is 849201."
  }'

# Or using query parameter:
curl -X POST "$baseUrl/sms/trigger?apiKey=$code" \\
  -H "Content-Type: application/json" \\
  -d '{"phoneNumber": "+919876543210", "message": "Test SMS"}'
''';

      case 1: // Node.js (Axios)
        return '''const axios = require('axios');

async function sendSms(phoneNumber, message) {
  try {
    const response = await axios.post('$baseUrl/sms/trigger', {
      deviceCode: '$code',
      phoneNumber: phoneNumber,
      message: message
    }, {
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': '$code'
      }
    });

    console.log('✅ SMS Dispatched:', response.data);
    return response.data;
  } catch (error) {
    console.error('❌ SMS Dispatch Error:', error.response?.data || error.message);
    throw error;
  }
}

// Example usage:
sendSms('+919876543210', 'Welcome to our service! Your account is active.');
''';

      case 2: // Python (Requests)
        return '''import requests

def send_sms(phone_number: str, message: str):
    url = "$baseUrl/sms/trigger"
    headers = {
        "x-api-key": "$code",
        "Content-Type": "application/json"
    }
    payload = {
        "deviceCode": "$code",
        "phoneNumber": phone_number,
        "message": message
    }

    try:
        response = requests.post(url, json=payload, headers=headers)
        response.raise_for_status()
        print("✅ Success:", response.json())
        return response.json()
    except requests.exceptions.RequestException as e:
        print("❌ Error:", e.response.text if e.response else e)
        return None

# Example usage:
send_sms("+919876543210", "Your order #1084 has been shipped.")
''';

      case 3: // PHP (cURL)
        return '''<?php
function sendSms(\$phoneNumber, \$message) {
    \$url = "$baseUrl/sms/trigger";
    
    \$data = [
        "deviceCode" => "$code",
        "phoneNumber" => \$phoneNumber,
        "message" => \$message
    ];

    \$ch = curl_init(\$url);
    curl_setopt(\$ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt(\$ch, CURLOPT_POST, true);
    curl_setopt(\$ch, CURLOPT_POSTFIELDS, json_encode(\$data));
    curl_setopt(\$ch, CURLOPT_HTTPHEADER, [
        "Content-Type: application/json",
        "x-api-key: $code"
    ]);

    \$response = curl_exec(\$ch);
    \$httpCode = curl_getinfo(\$ch, CURLINFO_HTTP_CODE);
    curl_close(\$ch);

    if (\$httpCode >= 200 && \$httpCode < 300) {
        echo "✅ SMS Dispatched: " . \$response;
    } else {
        echo "❌ Error: " . \$response;
    }
}

// Example usage:
sendSms("+919876543210", "Your invoice is ready to download.");
?>
''';

      case 4: // Dart (Dio)
        return '''import 'package:dio/dio.dart';

Future<void> sendSms(String phoneNumber, String message) async {
  final dio = Dio();
  
  try {
    final response = await dio.post(
      '$baseUrl/sms/trigger',
      data: {
        'deviceCode': '$code',
        'phoneNumber': phoneNumber,
        'message': message,
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': '$code',
        },
      ),
    );

    print('✅ SMS Dispatched: \${response.data}');
  } on DioException catch (e) {
    print('❌ Error: \${e.response?.data ?? e.message}');
  }
}

// Example usage:
// await sendSms('+919876543210', 'Alert: Server CPU at 85%');
''';

      default:
        return '';
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    MessageHelper.showSuccess(context, '$label copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Header Drag Handle & Title ───────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
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
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.code_rounded,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Developer API Hub',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Pre-configured code samples with your API key',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodySmall?.color ??
                                  colorScheme.onSurfaceVariant,
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

          // ── Language Tabs ─────────────────────────────────────────
          Container(
            color: theme.cardColor,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: colorScheme.primary,
              unselectedLabelColor: theme.textTheme.bodySmall?.color,
              indicatorColor: colorScheme.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: _languages.map((lang) => Tab(text: lang)).toList(),
            ),
          ),

          // ── Tab Content ───────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Code Snippet Card
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF282C34),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Code Header bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.amberAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.greenAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _languages[_selectedTab],
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: () => _copyToClipboard(
                                  _getCodeSnippet(_selectedTab),
                                  '${_languages[_selectedTab]} snippet',
                                ),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.copy_rounded, color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'Copy Code',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Code Block text
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: SelectableText(
                            _getCodeSnippet(_selectedTab),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12.5,
                              color: Color(0xFFABB2BF),
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ── REST API Endpoints Cheat Sheet ───────────────────────
                  Text(
                    'REST API Endpoints Reference',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildEndpointTile(
                    theme: theme,
                    method: 'POST',
                    methodColor: Colors.blue,
                    path: '/sms/trigger',
                    description: 'Dispatches SMS via physical SIM on this phone',
                  ),
                  const SizedBox(height: 8),
                  _buildEndpointTile(
                    theme: theme,
                    method: 'GET',
                    methodColor: Colors.green,
                    path: '/sms/reports/stats?userId=X',
                    description: 'Fetches today\'s sent and failed dispatch metrics',
                  ),
                  const SizedBox(height: 8),
                  _buildEndpointTile(
                    theme: theme,
                    method: 'GET',
                    methodColor: Colors.green,
                    path: '/sms/reports/detailed?userId=X',
                    description: 'Queries filtered logs with status and timestamps',
                  ),
                  const SizedBox(height: 8),
                  _buildEndpointTile(
                    theme: theme,
                    method: 'POST',
                    methodColor: Colors.blue,
                    path: '/schedules',
                    description: 'Schedules an outbound SMS for a future date/time',
                  ),

                  const SizedBox(height: 20),

                  // ── Authentication Headers Guide ─────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.vpn_key_rounded, size: 16, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Authentication Methods Supported',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '1. Header:  x-api-key: ${widget.deviceCode}\n'
                          '2. Query Param:  ?apiKey=${widget.deviceCode}\n'
                          '3. Body Field:  { "deviceCode": "${widget.deviceCode}" }',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            height: 1.4,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndpointTile({
    required ThemeData theme,
    required String method,
    required Color methodColor,
    required String path,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: methodColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  method,
                  style: TextStyle(
                    color: methodColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  path,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}
