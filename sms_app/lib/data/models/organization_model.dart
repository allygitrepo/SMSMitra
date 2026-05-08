class OrganizationModel {
  final int? id;
  final int userId;
  final String orgCode;
  final String orgName;
  final String? email;
  final String? address;
  final String? logo;

  OrganizationModel({
    this.id,
    required this.userId,
    required this.orgCode,
    required this.orgName,
    this.email,
    this.address,
    this.logo,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) => OrganizationModel(
    id: json['id'],
    userId: json['userId'],
    orgCode: json['orgCode'] ?? '',
    orgName: json['orgName'] ?? '',
    email: json['email'],
    address: json['address'],
    logo: json['logo'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'orgCode': orgCode,
    'orgName': orgName,
    'email': email,
    'address': address,
    'logo': logo,
  };
}
