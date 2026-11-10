import 'package:exe_matching/models/application.dart';
import 'package:exe_matching/models/room.dart';
import 'package:flutter/material.dart';

/// Token mau. Man hinh chi lay mau tu day hoac tu Theme.of(context).colorScheme.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFF26522); // cam FPT
  static const Color onPrimary = Colors.white;
  static const Color primaryContainer = Color(0xFFFFE0CC);
  static const Color secondary = Color(0xFF1E293B);

  static const Color success = Color(0xFF047857);
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFB45309);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFB91C1C);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF1D4ED8);
  static const Color infoContainer = Color(0xFFDBEAFE);
  static const Color neutral = Color(0xFF475569);
  static const Color neutralContainer = Color(0xFFF1F5F9);

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color outline = Color(0xFFE2E8F0);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);

  /// Cap mau (chu, nen) cho trang thai Room.
  static (Color, Color) roomStatus(RoomStatus status) => switch (status) {
    RoomStatus.empty => (neutral, neutralContainer),
    RoomStatus.open => (success, successContainer),
    RoomStatus.group => (info, infoContainer),
    RoomStatus.closed => (warning, warningContainer),
    RoomStatus.finalized => (secondary, outline),
  };

  static (Color, Color) applicationStatus(ApplicationStatus status) => switch (status) {
    ApplicationStatus.pending => (info, infoContainer),
    ApplicationStatus.accepted => (success, successContainer),
    ApplicationStatus.rejected => (error, errorContainer),
    ApplicationStatus.cancelled => (neutral, neutralContainer),
    ApplicationStatus.withdrawn => (neutral, neutralContainer),
  };
}
