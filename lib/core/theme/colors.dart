import 'package:flutter/material.dart';

abstract class AppColors {
  // Background Colors
  static const backgroundBlackColor = Color(0xFF121214);
  static const backgroundDarkGrey = Color(0xFF1E1E22);
  static const backgroundLightGrey = Color(0xFF2A2A2E);

  // Primary Colors
  static const primaryColor = Color(0xFF8068FF); // 메인 포인트 컬러
  static const primaryLightColor = Color(0xFF9F8FFF); // 더 밝은 보라색
  static const primaryDarkColor = Color(0xFF6344FF); // 더 진한 보라색
  static const primaryBackground = Color(0xFF2A2440); // 보라빛 배경색

  // Secondary Colors
  static const secondaryColor = Color(0xFF68FFED); // 민트색 포인트
  static const secondaryLightColor = Color(0xFF8FFFED); // 밝은 민트
  static const secondaryDarkColor = Color(0xFF44E6D4); // 진한 민트
  static const secondaryDeepDarkColor = Color.fromARGB(255, 19, 223, 199); // 더 진한 민트

  // Text Colors
  static const textWhite = Color(0xFFFFFFFF);
  static const textGrey = Color(0xFFB4B4BB);
  static const textLightGrey = Color(0xFFCCCCD3);
  static const textDarkGrey = Color(0xFF8E8E99);

  // Icon Colors
  static const iconWhite = Color(0xFFFFFFFF);
  static const iconGrey = Color(0xFFB4B4BB);
  static const iconLightGrey = Color(0xFFCCCCD3);
  static const iconPurple = Color(0xFF9F8FFF); // 보라색 아이콘용

  // Action Colors
  static const likeRed = Color(0xFFFF4D6A); // 분홍빛 레드
  static const followBlue = Color(0xFF68B6FF); // 하늘빛 블루
  static const successGreen = Color(0xFF4CECA4); // 민트빛 그린
  static const warningYellow = Color(0xFFFFD668); // 파스텔 옐로우
  static const errorRed = Color(0xFFFF4D4D); // 순수 레드

  // Gradient Colors
  static const gradientPurpleStart = Color(0xFF8068FF);
  static const gradientPurpleEnd = Color(0xFF6344FF);

  static const gradientBackgroundStart = Color(0xFF1E1E22);
  static const gradientBackgroundEnd = Color(0xFF121214);

  // Overlay Colors
  static const overlayDark = Color(0x99121214);
  static const overlayLight = Color(0x1AFFFFFF);
}
