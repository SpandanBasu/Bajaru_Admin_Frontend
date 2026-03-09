import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class Rider {
  final String id;
  final String? userId;
  final String name;
  final bool isOnline;
  final int deliveredToday;
  final int totalAssigned;

  const Rider({
    required this.id,
    this.userId,
    required this.name,
    this.isOnline = false,
    this.deliveredToday = 0,
    this.totalAssigned = 0,
  });

  /// Two-letter initials derived from name (e.g. "Ramesh Kumar" → "RK").
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  factory Rider.fromJson(Map<String, dynamic> json) => Rider(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String?,
        name: json['name'] as String? ?? '',
        isOnline: json['isOnline'] as bool? ?? false,
        deliveredToday: (json['deliveredToday'] as num?)?.toInt() ?? 0,
        totalAssigned: (json['totalAssigned'] as num?)?.toInt() ?? 0,
      );

  Rider copyWith({bool? isOnline}) => Rider(
        id: id, userId: userId, name: name,
        isOnline: isOnline ?? this.isOnline,
        deliveredToday: deliveredToday,
        totalAssigned: totalAssigned,
      );

  /// Deterministic avatar colour from rider id hash.
  Color get avatarColor {
    final palette = AppColors.avatarColors;
    return palette[id.hashCode.abs() % palette.length];
  }
}
