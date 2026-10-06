import 'package:flutter/material.dart';

// Kaamdhaam design system — colors
// Three colors with a job: Blue = trust/brand, Amber = the action to take,
// Green = verified/available. Everything else is calm neutrals.
class AppColors {
  AppColors._();

  // ── Brand: Trust Blue ──
  static const primary = Color(0xFF1A56A0);
  static const primaryDark = Color(0xFF0C447C);
  static const primaryDarker = Color(0xFF042C53);
  static const primaryLight = Color(0xFFE6F1FB);
  static const primaryText = Color(0xFF0C447C);

  // ── Action: Amber (the ONE thing to tap) ──
  static const accent = Color(0xFFF4900C);
  static const accentDark = Color(0xFFB26A07);
  static const accentLight = Color(0xFFFDF1E0);
  static const accentText = Color(0xFF854F0B);

  // ── Verified / Available: Green ──
  static const success = Color(0xFF1D9E75);
  static const successDark = Color(0xFF0F6E56);
  static const successLight = Color(0xFFE1F5EE);
  static const successText = Color(0xFF0F6E56);

  // ── Danger ──
  static const danger = Color(0xFFD14343);
  static const dangerDark = Color(0xFFA32D2D);
  static const dangerLight = Color(0xFFFCEBEB);
  static const dangerText = Color(0xFFA32D2D);

  // ── Warning ──
  static const warning = Color(0xFFBA7517);
  static const warningDark = Color(0xFF854F0B);
  static const warningLight = Color(0xFFFAEEDA);
  static const warningText = Color(0xFF854F0B);

  // ── Neutrals ──
  static const background = Color(0xFFF4F6F9);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF1F5F9);
  static const border = Color(0xFFE6EAF0);
  static const borderStrong = Color(0xFFD4DAE3);
  static const textPrimary = Color(0xFF16202E);
  static const textSecondary = Color(0xFF5A6675);
  static const textTertiary = Color(0xFF8A95A3);
  static const white = Color(0xFFFFFFFF);

  // ── Accent ramps used for job-type color coding ──
  static const purple = Color(0xFF534AB7);
  static const purpleLight = Color(0xFFEEEDFE);
  static const teal = Color(0xFF0F6E56);
  static const tealLight = Color(0xFFE1F5EE);
  static const coral = Color(0xFF993C1D);
  static const coralLight = Color(0xFFFAECE7);
  static const pink = Color(0xFF993556);
  static const pinkLight = Color(0xFFFBEAF0);
  static const gray = Color(0xFF5F5E5A);
  static const grayLight = Color(0xFFF1EFE8);
  static const green = Color(0xFF3B6D11);
  static const greenLight = Color(0xFFEAF3DE);

  static const overlay = Color(0x8C0F172A);
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4, sm = 8, md = 12, lg = 16, xl = 20, xxl = 24, xxxl = 32, huge = 48;
}

class AppRadius {
  AppRadius._();
  static const double sm = 8, md = 12, lg = 16, xl = 20, pill = 999;
}

// Soft, subtle elevation. Clean — not heavy drop shadows.
class AppShadows {
  AppShadows._();
  static const sm = [BoxShadow(color: Color(0x0F0C2340), blurRadius: 6, offset: Offset(0, 2))];
  static const md = [BoxShadow(color: Color(0x140C2340), blurRadius: 12, offset: Offset(0, 4))];
  static const lg = [BoxShadow(color: Color(0x1A0C2340), blurRadius: 20, offset: Offset(0, 8))];
  static const accent = [BoxShadow(color: Color(0x52F4900C), blurRadius: 12, offset: Offset(0, 4))];
  static const primary = [BoxShadow(color: Color(0x471A56A0), blurRadius: 14, offset: Offset(0, 6))];
}
