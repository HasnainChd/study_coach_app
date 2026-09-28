import 'package:flutter/material.dart';

enum RewardCategory {
  theme,
  badge,
  aiCredit,
}

class RewardItem {
  final String id;
  final String title;
  final String description;
  final int cost;
  final RewardCategory category;
  final String icon;
  final Color? color;
  final Map<String, dynamic>? extraData;

  const RewardItem({
    required this.id,
    required this.title,
    required this.description,
    required this.cost,
    required this.category,
    required this.icon,
    this.color,
    this.extraData,
  });

  static const List<RewardItem> catalog = [
    // App Accent Themes
    RewardItem(
      id: 'theme_midnight_neon',
      title: 'Midnight Neon Theme',
      description: 'Futuristic deep purple and neon cyan accents',
      cost: 50,
      category: RewardCategory.theme,
      icon: '🎨',
      color: Color(0xFF00E5FF),
      extraData: {'primaryColor': 0xFF00E5FF, 'name': 'Midnight Neon'},
    ),
    RewardItem(
      id: 'theme_emerald_synth',
      title: 'Emerald Synth Theme',
      description: 'Vibrant emerald green and dark teal aesthetic',
      cost: 75,
      category: RewardCategory.theme,
      icon: '❇️',
      color: Color(0xFF00D180),
      extraData: {'primaryColor': 0xFF00D180, 'name': 'Emerald Synth'},
    ),
    RewardItem(
      id: 'theme_sunset_amber',
      title: 'Sunset Amber Theme',
      description: 'Warm glowing amber and coral rose accents',
      cost: 100,
      category: RewardCategory.theme,
      icon: '🌅',
      color: Color(0xFFFF8C00),
      extraData: {'primaryColor': 0xFFFF8C00, 'name': 'Sunset Amber'},
    ),

    // Profile Badges
    RewardItem(
      id: 'badge_focus_wizard',
      title: 'Focus Wizard',
      description: 'Showcase your mastery of deep focus sessions',
      cost: 50,
      category: RewardCategory.badge,
      icon: '🧙‍♂️',
      color: Color(0xFFAC8EFF),
    ),
    RewardItem(
      id: 'badge_streak_master',
      title: 'Streak Master',
      description: 'Awarded to scholars with unbroken dedication',
      cost: 75,
      category: RewardCategory.badge,
      icon: '🔥',
      color: Color(0xFFFF5100),
    ),
    RewardItem(
      id: 'badge_night_owl',
      title: 'Night Owl',
      description: 'For those who conquer late night study sessions',
      cost: 80,
      category: RewardCategory.badge,
      icon: '🦉',
      color: Color(0xFF3B82F6),
    ),
    RewardItem(
      id: 'badge_master_scholar',
      title: 'Master Scholar',
      description: 'The ultimate symbol of academic excellence',
      cost: 150,
      category: RewardCategory.badge,
      icon: '🎓',
      color: Color(0xFFFFD700),
    ),

    // AI Boosts
    RewardItem(
      id: 'ai_plan_regen_boost',
      title: '+1 AI Plan Credit',
      description: 'Instantly get 1 extra AI Study Plan regeneration credit',
      cost: 60,
      category: RewardCategory.aiCredit,
      icon: '⚡',
      color: Color(0xFFFFD043),
    ),
  ];
}
