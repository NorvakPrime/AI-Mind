import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Акценты
  static const accent = Color(0xFF7C6CFF);
  static const accentLight = Color(0xFF9D8FFF);
  static const accentDim = Color(0xFF4A3FB0);

  // Фоны
  static const bg = Color(0xFF0C0B10);
  static const surface = Color(0xFF13121A);
  static const surfaceLight = Color(0xFF1A1924);
  static const surfaceBorder = Color(0xFF232230);

  // Текст
  static const textPrimary = Color(0xFFF0EFF4);
  static const textSecondary = Color(0xFF9895A8);
  static const textMuted = Color(0xFF6C6880);

  // Баблы
  static const userBubble = Color(0xFF2A2640);
  static const botBubble = Color(0xFF16151E);

  // Градиент
  static const gradient = LinearGradient(
    colors: [accent, Color(0xFF5B8DEF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
