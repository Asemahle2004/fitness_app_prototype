import 'package:shared_preferences/shared_preferences.dart';

class EquipmentAvailabilityStore {
  final String userScope;

  const EquipmentAvailabilityStore({required this.userScope});

  static const _permanentPrefix = 'leanit_missing_equipment_location_v1';
  static const _todayPrefix = 'leanit_missing_equipment_today_v1';

  String _scope(String environment) {
    final cleanUser = userScope.trim().isEmpty ? 'guest' : userScope.trim();
    final cleanEnvironment = environment.trim().isEmpty
        ? 'unknown'
        : environment.trim().toLowerCase();
    return '$cleanUser:$cleanEnvironment';
  }

  String _dayStamp(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  Future<Set<String>> permanentFor(String environment) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('$_permanentPrefix:${_scope(environment)}') ??
            const <String>[])
        .toSet();
  }

  Future<Set<String>> todayFor(
    String environment, {
    DateTime? now,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final date = now ?? DateTime.now();
    return (prefs.getStringList(
              '$_todayPrefix:${_scope(environment)}:${_dayStamp(date)}',
            ) ??
            const <String>[])
        .toSet();
  }

  Future<Set<String>> unavailableFor(
    String environment, {
    DateTime? now,
  }) async {
    return {
      ...await permanentFor(environment),
      ...await todayFor(environment, now: now),
    };
  }

  Future<void> markPermanent(
    String environment,
    Iterable<String> equipment,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_permanentPrefix:${_scope(environment)}';
    final values = {
      ...(prefs.getStringList(key) ?? const <String>[]),
      ...equipment.where((item) => item.trim().isNotEmpty),
    }.toList()
      ..sort();
    await prefs.setStringList(key, values);
  }

  Future<void> markToday(
    String environment,
    Iterable<String> equipment, {
    DateTime? now,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final date = now ?? DateTime.now();
    final key = '$_todayPrefix:${_scope(environment)}:${_dayStamp(date)}';
    final values = {
      ...(prefs.getStringList(key) ?? const <String>[]),
      ...equipment.where((item) => item.trim().isNotEmpty),
    }.toList()
      ..sort();
    await prefs.setStringList(key, values);
  }

  Future<void> restorePermanent(
    String environment,
    Iterable<String> equipment,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_permanentPrefix:${_scope(environment)}';
    final existing = (prefs.getStringList(key) ?? const <String>[]).toSet();
    existing.removeAll(equipment);
    final values = existing.toList()..sort();
    await prefs.setStringList(key, values);
  }

  Future<void> clearToday(String environment, {DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final date = now ?? DateTime.now();
    await prefs.remove(
      '$_todayPrefix:${_scope(environment)}:${_dayStamp(date)}',
    );
  }
}
