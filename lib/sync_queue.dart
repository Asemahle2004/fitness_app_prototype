import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncOperation {
  final String id;
  final String table;
  final String action;
  final Map<String, dynamic> data;
  final String? matchColumn;
  final dynamic matchValue;
  final DateTime createdAt;
  final int attempts;

  const SyncOperation({
    required this.id,
    required this.table,
    required this.action,
    required this.data,
    required this.matchColumn,
    required this.matchValue,
    required this.createdAt,
    this.attempts = 0,
  });

  SyncOperation copyWith({int? attempts}) => SyncOperation(
        id: id,
        table: table,
        action: action,
        data: data,
        matchColumn: matchColumn,
        matchValue: matchValue,
        createdAt: createdAt,
        attempts: attempts ?? this.attempts,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'table': table,
        'action': action,
        'data': data,
        'match_column': matchColumn,
        'match_value': matchValue,
        'created_at': createdAt.toIso8601String(),
        'attempts': attempts,
      };

  factory SyncOperation.fromJson(Map<String, dynamic> json) => SyncOperation(
        id: json['id']?.toString() ??
            'sync_${DateTime.now().microsecondsSinceEpoch}',
        table: json['table']?.toString() ?? '',
        action: json['action']?.toString() ?? 'insert',
        data: json['data'] is Map
            ? Map<String, dynamic>.from(json['data'] as Map)
            : const <String, dynamic>{},
        matchColumn: json['match_column']?.toString(),
        matchValue: json['match_value'],
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      );
}

class SyncQueueStore {
  static const _prefix = 'leanit_sync_queue_v1';
  static const _maxOperations = 500;
  final String userScope;

  const SyncQueueStore({required this.userScope});

  String get _key => '${_prefix}_${_safeScope(userScope)}';

  Future<List<SyncOperation>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const <String>[];
    final result = <SyncOperation>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map) {
          result.add(SyncOperation.fromJson(Map<String, dynamic>.from(decoded)));
        }
      } catch (_) {}
    }
    result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return result;
  }

  Future<void> enqueue({
    required String table,
    required String action,
    required Map<String, dynamic> data,
    String? matchColumn,
    dynamic matchValue,
  }) async {
    if (!SyncSecurityPolicy.allowedTable(table)) return;
    final sanitized = SyncSecurityPolicy.sanitize(data);
    if (sanitized.isEmpty) return;
    final current = await load();

    // Deduplicate the same failed write before it reaches the queue. This is
    // especially useful when the app retries the same completed workout after
    // more than one temporary connectivity failure.
    final duplicate = current.any((item) =>
        item.table == table &&
        item.action == action &&
        item.matchColumn == matchColumn &&
        item.matchValue?.toString() == matchValue?.toString());
    if (duplicate && matchColumn != null) return;

    final operation = SyncOperation(
      id: 'sync_${DateTime.now().microsecondsSinceEpoch}',
      table: table,
      action: action,
      data: sanitized,
      matchColumn: matchColumn,
      matchValue: matchValue,
      createdAt: DateTime.now(),
    );
    await _save([...current, operation].take(_maxOperations).toList());
  }

  Future<void> replace(List<SyncOperation> operations) =>
      _save(operations.take(_maxOperations).toList(growable: false));

  Future<void> _save(List<SyncOperation> operations) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      operations.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  static String _safeScope(String value) => value.trim().isEmpty
      ? 'guest'
      : value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
}

class SyncFlushResult {
  final int attempted;
  final int completed;
  final int remaining;

  const SyncFlushResult({
    required this.attempted,
    required this.completed,
    required this.remaining,
  });
}

class SyncCoordinator {
  final SupabaseClient client;
  final String userScope;

  const SyncCoordinator({required this.client, required this.userScope});

  Future<SyncFlushResult> flush() async {
    final user = client.auth.currentUser;
    if (user == null) {
      final pending = await SyncQueueStore(userScope: userScope).load();
      return SyncFlushResult(
        attempted: 0,
        completed: 0,
        remaining: pending.length,
      );
    }

    final store = SyncQueueStore(userScope: userScope);
    final pending = await store.load();
    if (pending.isEmpty) {
      return const SyncFlushResult(attempted: 0, completed: 0, remaining: 0);
    }

    final remaining = <SyncOperation>[];
    var completed = 0;
    for (final operation in pending) {
      try {
        await _apply(operation);
        completed += 1;
      } catch (_) {
        if (operation.attempts < 8) {
          remaining.add(operation.copyWith(attempts: operation.attempts + 1));
        }
      }
    }
    await store.replace(remaining);
    return SyncFlushResult(
      attempted: pending.length,
      completed: completed,
      remaining: remaining.length,
    );
  }

  Future<void> _apply(SyncOperation operation) async {
    if (!SyncSecurityPolicy.allowedTable(operation.table)) {
      throw StateError('Blocked sync table.');
    }
    final table = client.from(operation.table);
    switch (operation.action) {
      case 'insert':
        await table.insert(operation.data);
        return;
      case 'insert_if_absent':
        final column = operation.matchColumn;
        if (column == null || operation.matchValue == null) {
          throw StateError('Idempotent insert requires a match.');
        }
        final existing = await table
            .select(column)
            .eq(column, operation.matchValue)
            .limit(1);
        if (existing is List && existing.isNotEmpty) return;
        await table.insert(operation.data);
        return;
      case 'upsert':
        await table.upsert(operation.data);
        return;
      case 'update':
        final column = operation.matchColumn;
        if (column == null || operation.matchValue == null) {
          throw StateError('Update sync operation requires a match.');
        }
        await table.update(operation.data).eq(column, operation.matchValue);
        return;
      default:
        throw StateError('Unsupported sync action.');
    }
  }
}

class SyncSecurityPolicy {
  const SyncSecurityPolicy._();

  static const _allowedTables = <String>{
    'workout_logs',
    'readiness_logs',
    'exercise_set_logs',
    'current_programmes',
  };

  static bool allowedTable(String table) => _allowedTables.contains(table);

  static Map<String, dynamic> sanitize(Map<String, dynamic> input) {
    final result = <String, dynamic>{};
    for (final entry in input.entries) {
      final key = entry.key.toLowerCase();
      if (key.contains('password') ||
          key.contains('secret') ||
          key.contains('token') ||
          key.contains('authorization')) {
        continue;
      }
      result[entry.key] = entry.value;
    }
    return result;
  }
}
