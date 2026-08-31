import 'workout_engine.dart';

class SupersetEngine {
  static bool hasValidPair(List<ExercisePrescription> exercises, int index) {
    return membersFor(exercises, index).length == 2;
  }

  static List<int> membersFor(
    List<ExercisePrescription> exercises,
    int index,
  ) {
    if (index < 0 || index >= exercises.length) return const [];
    final id = exercises[index].supersetId;
    if (id == null || id.trim().isEmpty) return const [];

    final members = <int>[];
    for (var i = 0; i < exercises.length; i += 1) {
      if (exercises[i].supersetId == id) members.add(i);
    }
    if (members.length != 2 || members[1] != members[0] + 1) {
      return const [];
    }
    return members;
  }

  static String? positionLabel(
    List<ExercisePrescription> exercises,
    int index,
  ) {
    final members = membersFor(exercises, index);
    if (members.length != 2) return null;
    return index == members.first ? 'A' : 'B';
  }

  static String? partnerName(
    List<ExercisePrescription> exercises,
    int index,
  ) {
    final members = membersFor(exercises, index);
    if (members.length != 2) return null;
    final partner = members.first == index ? members.last : members.first;
    return exercises[partner].name;
  }

  static List<ExercisePrescription> pairWithNext(
    List<ExercisePrescription> exercises,
    int firstIndex, {
    String? groupId,
  }) {
    final result = normalize(exercises);
    if (firstIndex < 0 || firstIndex >= result.length - 1) return result;
    if (result[firstIndex].supersetId != null ||
        result[firstIndex + 1].supersetId != null) {
      return result;
    }

    final id = groupId ??
        'ss_${DateTime.now().microsecondsSinceEpoch}_$firstIndex';
    result[firstIndex] = result[firstIndex].copyWith(supersetId: id);
    result[firstIndex + 1] = result[firstIndex + 1].copyWith(supersetId: id);
    return result;
  }

  static List<ExercisePrescription> unpairAt(
    List<ExercisePrescription> exercises,
    int index,
  ) {
    final result = List<ExercisePrescription>.from(exercises);
    if (index < 0 || index >= result.length) return result;
    final id = result[index].supersetId;
    if (id == null) return result;
    for (var i = 0; i < result.length; i += 1) {
      if (result[i].supersetId == id) {
        result[i] = result[i].copyWith(clearSuperset: true);
      }
    }
    return result;
  }

  static List<ExercisePrescription> normalize(
    List<ExercisePrescription> exercises,
  ) {
    final result = List<ExercisePrescription>.from(exercises);
    final indexesById = <String, List<int>>{};
    for (var i = 0; i < result.length; i += 1) {
      final id = result[i].supersetId;
      if (id == null || id.trim().isEmpty) continue;
      indexesById.putIfAbsent(id, () => <int>[]).add(i);
    }

    for (final entry in indexesById.entries) {
      final members = entry.value;
      final valid = members.length == 2 && members[1] == members[0] + 1;
      if (valid) continue;
      for (final index in members) {
        result[index] = result[index].copyWith(clearSuperset: true);
      }
    }
    return result;
  }

  static int? immediateNextAfterSet({
    required List<ExercisePrescription> exercises,
    required List<int> completedSets,
    required int currentIndex,
  }) {
    final members = membersFor(exercises, currentIndex);
    if (members.length != 2 || currentIndex != members.first) return null;
    final partner = members.last;
    return completedSets[partner] < exercises[partner].sets ? partner : null;
  }

  static int? nextRoundMember({
    required List<ExercisePrescription> exercises,
    required List<int> completedSets,
    required int currentIndex,
  }) {
    final members = membersFor(exercises, currentIndex);
    if (members.length != 2) return null;
    for (final member in members) {
      if (completedSets[member] < exercises[member].sets) return member;
    }
    return null;
  }

  static int? indexAfterPair(
    List<ExercisePrescription> exercises,
    int currentIndex,
  ) {
    final members = membersFor(exercises, currentIndex);
    if (members.length != 2) return null;
    final next = members.last + 1;
    return next < exercises.length ? next : null;
  }
}
