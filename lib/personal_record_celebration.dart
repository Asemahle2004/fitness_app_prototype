import 'package:flutter/material.dart';

import 'personal_record_engine.dart';

class PersonalRecordCelebration {
  static void showSnackBar(
    BuildContext context,
    List<PersonalRecordAchievement> achievements,
  ) {
    if (achievements.isEmpty) return;
    final subject = achievements.first.subject;
    final text = achievements.length == 1
        ? 'New PR • ${achievements.first.metric.label}: ${achievements.first.displayValue}'
        : '${achievements.length} new PRs • $subject';

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD54F)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> showDialogIfNeeded(
    BuildContext context,
    List<PersonalRecordAchievement> achievements,
  ) async {
    if (achievements.isEmpty) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4CC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFFB7791F),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                achievements.length == 1
                    ? 'New personal record!'
                    : '${achievements.length} personal records!',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              achievements.first.subject,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF102A43),
              ),
            ),
            const SizedBox(height: 12),
            ...achievements.take(4).map(
                  (record) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: Color(0xFFB7791F),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${record.metric.label} • ${record.displayValue}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF102A43),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                record.previousLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF627D98),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (achievements.length > 4)
              Text(
                '+${achievements.length - 4} more record${achievements.length - 4 == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF627D98),
                ),
              ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CONTINUE'),
          ),
        ],
      ),
    );
  }
}
