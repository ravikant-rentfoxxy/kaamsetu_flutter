import 'package:flutter/material.dart';

import 'app_colors.dart';

// Every job type gets ONE consistent icon + color pair.
// Workers learn the shape + color, not the word.
class JobMeta {
  final IconData icon;
  final Color color; // icon / text color (dark, readable on `bg`)
  final Color bg; // light tile background
  final String labelHi;
  final String labelEn;

  const JobMeta(this.icon, this.color, this.bg, this.labelHi, this.labelEn);

  String label(String lang) => lang == 'en' ? labelEn : labelHi;
}

const Map<String, JobMeta> _jobMeta = {
  'driver': JobMeta(Icons.directions_car_filled, AppColors.primary, AppColors.primaryLight, 'ड्राइवर', 'Driver'),
  'security_guard': JobMeta(Icons.security, AppColors.warningDark, AppColors.warningLight, 'गार्ड', 'Security Guard'),
  'cook': JobMeta(Icons.soup_kitchen, AppColors.coral, AppColors.coralLight, 'रसोइया', 'Cook'),
  'housekeeper': JobMeta(Icons.home_work, AppColors.teal, AppColors.tealLight, 'हाउसकीपर', 'Housekeeper'),
  'delivery': JobMeta(Icons.inventory_2, AppColors.green, AppColors.greenLight, 'डिलीवरी', 'Delivery'),
  'electrician': JobMeta(Icons.bolt, AppColors.purple, AppColors.purpleLight, 'इलेक्ट्रिशियन', 'Electrician'),
  'plumber': JobMeta(Icons.plumbing, AppColors.pink, AppColors.pinkLight, 'प्लंबर', 'Plumber'),
  'peon': JobMeta(Icons.assignment_outlined, AppColors.gray, AppColors.grayLight, 'चपरासी', 'Peon'),
  'sweeper': JobMeta(Icons.cleaning_services, AppColors.teal, AppColors.tealLight, 'सफाईकर्मी', 'Sweeper'),
  'helper': JobMeta(Icons.volunteer_activism_outlined, AppColors.gray, AppColors.grayLight, 'हेल्पर', 'Helper'),
};

const _defaultMeta = JobMeta(Icons.work_outline, AppColors.primary, AppColors.primaryLight, 'काम', 'Job');

JobMeta getJobMeta(String? jobType) => _jobMeta[jobType] ?? _defaultMeta;

String jobLabel(String? jobType, [String lang = 'hi']) => getJobMeta(jobType).label(lang);

final List<String> jobTypes = _jobMeta.keys.toList();

class LabeledOption {
  final String value;
  final String labelEn;
  final String labelHi;
  const LabeledOption(this.value, this.labelEn, this.labelHi);
  String label(String lang) => lang == 'en' ? labelEn : labelHi;
}

// Employment type (how the worker wants to work) — distinct from is_live_in_ok.
const employmentTypes = [
  LabeledOption('FULL_TIME', 'Full-time', 'फुल टाइम'),
  LabeledOption('PART_TIME', 'Part-time', 'पार्ट टाइम'),
  LabeledOption('LIVE_IN', 'Live-in', 'लिव-इन'),
  LabeledOption('TEMPORARY', 'Temporary', 'अस्थायी'),
];

class SalaryBand {
  final int min;
  final int? max; // null = open-ended ("25k+")
  final String labelEn;
  final String labelHi;
  const SalaryBand(this.min, this.max, this.labelEn, this.labelHi);
  String label(String lang) => lang == 'en' ? labelEn : labelHi;
}

// Expected-salary bands (₹/month).
const salaryBands = [
  SalaryBand(8000, 12000, '₹8k – 12k', '₹8 हज़ार – 12 हज़ार'),
  SalaryBand(12000, 16000, '₹12k – 16k', '₹12 हज़ार – 16 हज़ार'),
  SalaryBand(16000, 20000, '₹16k – 20k', '₹16 हज़ार – 20 हज़ार'),
  SalaryBand(20000, 25000, '₹20k – 25k', '₹20 हज़ार – 25 हज़ार'),
  SalaryBand(25000, null, '₹25k+', '₹25 हज़ार+'),
];
