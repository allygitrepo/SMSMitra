class DeviceContact {
  final String id;
  final String name;
  final String phone;

  const DeviceContact({
    required this.id,
    required this.name,
    required this.phone,
  });

  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  factory DeviceContact.fromMap(Map<dynamic, dynamic> map) {
    return DeviceContact(
      id: map['id']?.toString() ?? '',
      name: (map['name']?.toString() ?? '').trim().isNotEmpty
          ? map['name'].toString().trim()
          : 'Unknown Contact',
      phone: map['phone']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceContact &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          phone == other.phone;

  @override
  int get hashCode => id.hashCode ^ phone.hashCode;
}
