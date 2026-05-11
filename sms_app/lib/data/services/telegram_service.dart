// import 'dart:convert';
// import '../models/telegram_contact_model.dart';
// import 'api_service.dart';
// 
// class TelegramService {
//   final ApiService _apiService = ApiService();
// 
//   Future<List<TelegramContactModel>> getContacts({String? orgCode}) async {
//     final endpoint = orgCode != null && orgCode.isNotEmpty
//         ? '/telegram/contacts/$orgCode'
//         : '/telegram/contacts';
// 
//     final response = await _apiService.get(endpoint);
// 
//     if (response.statusCode == 200) {
//       dynamic jsonResponse = response.data;
//       if (jsonResponse is String) {
//         jsonResponse = jsonDecode(jsonResponse as String);
//       }
//       if (jsonResponse is Map<String, dynamic> && jsonResponse['success'] == true) {
//         final List<dynamic> data = jsonResponse['data'];
//         return data.map((e) => TelegramContactModel.fromJson(e)).toList();
//       }
//     }
//     throw Exception('Failed to load telegram contacts');
//   }
// 
//   Future<void> bulkSend({
//     required String message,
//     required List<TelegramContactModel> contacts,
//     String? orgCode,
//   }) async {
//     final endpoint = '/telegram/bulk-send';
//     
//     final data = {
//       'org_code': orgCode,
//       'message': message,
//       'contacts': contacts.map((c) => {
//         'name': c.name,
//         'telegram_chat_id': c.telegramChatId,
//       }).toList(),
//     };
// 
//     final response = await _apiService.post(
//       endpoint,
//       data: data,
//     );
// 
//     if (response.statusCode != 200) {
//       throw Exception('Failed to send telegram bulk messages');
//     }
//   }
// }
// 