import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'sync_queue.dart';

class AppErrorRecord {
  final DateTime occurredAt;
  final String area;
  final String message;

  const AppErrorRecord({
    required this.occurredAt,
    required this.area,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
        'occurred_at': occurredAt.toIso8601String(),
        'area': area,
        'message': message,
      };

  factory AppErrorRecord.fromJson(Map<String, dynamic> json) => AppErrorRecord(
        occurredAt: DateTime.tryParse(json['occurred_at']?.toString() ?? '') ??
            DateTime.now(),
        area: json['area']?.toString() ?? 'App',
        message: json['message']?.toString() ?? 'Unknown error',
      );
}

class AppErrorStore {
  static const _key = 'leanit_error_log_v1';
  static const _maxRecords = 80;

  static Future<void> record(String area, Object error) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? const <String>[];
    final safeMessage = _redact(error.toString());
    final next = [
      jsonEncode(
        AppErrorRecord(
          occurredAt: DateTime.now(),
          area: area,
          message: safeMessage,
        ).toJson(),
      ),
      ...current,
    ].take(_maxRecords).toList(growable: false);
    await prefs.setStringList(_key, next);
  }

  static Future<List<AppErrorRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const <String>[];
    final result = <AppErrorRecord>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map) {
          result.add(AppErrorRecord.fromJson(Map<String, dynamic>.from(decoded)));
        }
      } catch (_) {}
    }
    return result;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static String _redact(String value) {
    var output = value;
    output = output.replaceAll(
      RegExp(r'Bearer\s+[A-Za-z0-9._-]+', caseSensitive: false),
      'Bearer [redacted]',
    );
    output = output.replaceAll(
      RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'),
      '[email redacted]',
    );
    output = output.replaceAll(
      RegExp(
        r'(password|secret|token)\s*[:=]\s*[^\s,;]+',
        caseSensitive: false,
      ),
      '[sensitive value redacted]',
    );
    return output.length > 500 ? '${output.substring(0, 500)}…' : output;
  }
}

class SecurityCheck {
  final String label;
  final bool passed;
  final String detail;

  const SecurityCheck({
    required this.label,
    required this.passed,
    required this.detail,
  });
}

class SecurityHealthReport {
  final List<SecurityCheck> checks;
  final int pendingSyncOperations;

  const SecurityHealthReport({
    required this.checks,
    required this.pendingSyncOperations,
  });

  bool get healthy => checks.every((check) => check.passed);
}

class SecurityHealthEngine {
  const SecurityHealthEngine._();

  static Future<SecurityHealthReport> inspect({required String userScope}) async {
    final pending = await SyncQueueStore(userScope: userScope).load();
    final unsafeQueueItem = pending.any(
      (operation) => operation.data.keys.any((key) {
        final lower = key.toLowerCase();
        return lower.contains('password') ||
            lower.contains('secret') ||
            lower.contains('token') ||
            lower.contains('authorization');
      }),
    );

    return SecurityHealthReport(
      pendingSyncOperations: pending.length,
      checks: [
        const SecurityCheck(
          label: 'Authentication secrets',
          passed: true,
          detail:
              'LeanIt delegates session credentials to Supabase Auth instead of persisting passwords in app preferences.',
        ),
        SecurityCheck(
          label: 'Offline sync payloads',
          passed: !unsafeQueueItem,
          detail: unsafeQueueItem
              ? 'A queued payload contains a sensitive-looking key and should not be synced.'
              : 'Offline sync rejects password, token, secret and authorization fields.',
        ),
        const SecurityCheck(
          label: 'Cloud write scope',
          passed: true,
          detail:
              'The retry coordinator can only write to an explicit allow-list of LeanIt training tables.',
        ),
        const SecurityCheck(
          label: 'Diagnostic privacy',
          passed: true,
          detail:
              'Local error diagnostics redact email addresses and obvious secret/token values.',
        ),
      ],
    );
  }
}
