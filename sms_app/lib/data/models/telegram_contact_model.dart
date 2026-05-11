// class TelegramContactModel {
//   final int id;
//   final int userId;
//   final String? orgCode;
//   final String name;
//   final String telegramChatId;
//   final String? telegramUsername;
// 
//   TelegramContactModel({
//     required this.id,
//     required this.userId,
//     this.orgCode,
//     required this.name,
//     required this.telegramChatId,
//     this.telegramUsername,
//   });
// 
//   factory TelegramContactModel.fromJson(Map<String, dynamic> json) {
//     return TelegramContactModel(
//       id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
//       userId: json['userId'] is int ? json['userId'] : int.tryParse(json['userId'].toString()) ?? 0,
//       orgCode: json['orgCode']?.toString(),
//       name: json['name']?.toString() ?? 'Unknown',
//       telegramChatId: json['telegramChatId']?.toString() ?? '',
//       telegramUsername: json['telegramUsername']?.toString(),
//     );
//   }
// 
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'userId': userId,
//       'orgCode': orgCode,
//       'name': name,
//       'telegramChatId': telegramChatId,
//       'telegramUsername': telegramUsername,
//     };
//   }
// }
// 