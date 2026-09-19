import 'package:flutter/material.dart';

/// Represents a contact item loaded from the device's address book
class ContactItem {
  final String name;
  final String number;

  const ContactItem({
    required this.name,
    required this.number,
  });

  /// Derives 1-2 letter uppercase initials for avatar badge
  String get initials {
    if (name.trim().isEmpty) return '#';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length.clamp(1, 2)).toUpperCase();
  }

  /// Normalized formatted international number
  String get formattedNumber {
    final cleaned = number.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.startsWith('+')) return cleaned;
    if (cleaned.length == 10) return '+91$cleaned';
    if (cleaned.length == 12 && cleaned.startsWith('91')) return '+$cleaned';
    return '+$cleaned';
  }

  /// Generates a consistent, aesthetic avatar color based on name hash
  Color get avatarColor {
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFEC4899), // Pink
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFF97316), // Orange
      const Color(0xFF14B8A6), // Teal
    ];
    final hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    return colors[hash % colors.length];
  }

  factory ContactItem.fromMap(Map<dynamic, dynamic> map) {
    return ContactItem(
      name: (map['name']?.toString() ?? '').trim(),
      number: (map['number']?.toString() ?? '').trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'number': number,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactItem &&
          runtimeType == other.runtimeType &&
          formattedNumber == other.formattedNumber;

  @override
  int get hashCode => formattedNumber.hashCode;
}
