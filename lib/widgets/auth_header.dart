import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 42),
              ),
              const SizedBox(height: 18),
              const Text(
                'TaskMate',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppTheme.text),
              ),
              const Text(
                'Smart Task Manager',
                style: TextStyle(fontSize: 16, color: AppTheme.muted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 44),
        Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(fontSize: 15, color: AppTheme.muted)),
      ],
    );
  }
}
