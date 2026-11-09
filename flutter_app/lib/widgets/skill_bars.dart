import 'package:exe_matching/models/app_user.dart';
import 'package:exe_matching/theme/app_colors.dart';
import 'package:exe_matching/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Hien 5 ky nang dang thanh ngang chi doc (BR-05).
class SkillBars extends StatelessWidget {
  final SkillScores skills;
  const SkillBars({super.key, required this.skills});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: SkillScores.labels.entries.map((e) {
        final value = skills.valueOf(e.key);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
          child: Row(
            children: [
              SizedBox(width: 112, child: Text(e.value, style: text.bodySmall)),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: value / 100,
                    minHeight: 6,
                    backgroundColor: AppColors.outline,
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: Text('$value', style: text.bodySmall, textAlign: TextAlign.end),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
