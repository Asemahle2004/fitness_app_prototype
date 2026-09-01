import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account_screen.dart';
import 'adaptive_strength_engine.dart';
import 'custom_workouts_screen.dart';
import 'exercise_library_screen.dart';
import 'exercise_performance_store.dart';
import 'lean_eat_theme.dart';
import 'progress_screen.dart';
import 'readiness_screen.dart';
import 'strength_adaptation_cache.dart';
import 'today_dashboard.dart';
import 'training_settings_screen.dart';
import 'training_store.dart';

class LeanEatMemberShell extends StatefulWidget {
  final Widget programmeHome;

  const LeanEatMemberShell({
    super.key,
    required this.programmeHome,
  });

  @override
  State<LeanEatMemberShell> createState() => _LeanEatMemberShellState();
}

class _LeanEatMemberShellState extends State<LeanEatMemberShell> {
  int _index = 0;
  int _homeRevision = 0;
  int _adaptationRefreshToken = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = _buildPages();
    TrainingStore.revision.addListener(_onTrainingRevision);
    unawaited(_refreshStrengthAdaptation());
  }

  @override
  void dispose() {
    TrainingStore.revision.removeListener(_onTrainingRevision);
    super.dispose();
  }

  void _onTrainingRevision() {
    unawaited(_refreshStrengthAdaptation());
  }

  Future<void> _refreshStrengthAdaptation() async {
    final token = ++_adaptationRefreshToken;
    try {
      final workoutsFuture = TrainingStore.loadWorkouts();
      final readinessFuture = TrainingStore.loadReadiness();
      final setsFuture = ExercisePerformanceStore(
        Supabase.instance.client,
      ).loadAll();

      final workouts = await workoutsFuture;
      final readiness = await readinessFuture;
      final sets = await setsFuture;
      if (!mounted || token != _adaptationRefreshToken) return;

      StrengthAdaptationCache.set(
        StrengthAdaptationEngine.analyse(
          workouts: workouts,
          sets: sets,
          readiness: readiness.isEmpty ? null : readiness.first,
        ),
      );
    } catch (_) {
      // The existing workout flow remains usable when analytics cannot refresh.
    }
  }

  List<Widget> _buildPages() => [
        LeanEatTodayDashboard(
          key: ValueKey('today-$_homeRevision'),
          fallbackProgrammeHome: widget.programmeHome,
        ),
        ExerciseLibraryScreen(client: Supabase.instance.client),
        CustomWorkoutsScreen(client: Supabase.instance.client),
        const ReadinessScreen(),
        const ProgressScreen(),
        const LeanEatAccountScreen(),
      ];

  void _selectDestination(int value) {
    unawaited(_refreshStrengthAdaptation());
    setState(() {
      _index = value;
      if (value == 0) {
        _homeRevision += 1;
        _pages[0] = LeanEatTodayDashboard(
          key: ValueKey('today-$_homeRevision'),
          fallbackProgrammeHome: widget.programmeHome,
        );
      }
    });
  }

  void _openTrainingSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingSettingsScreen()),
    );
  }

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.fitness_center_outlined),
      selectedIcon: Icon(Icons.fitness_center_rounded),
      label: 'Exercises',
    ),
    NavigationDestination(
      icon: Icon(Icons.view_list_outlined),
      selectedIcon: Icon(Icons.view_list_rounded),
      label: 'Workouts',
    ),
    NavigationDestination(
      icon: Icon(Icons.favorite_border_rounded),
      selectedIcon: Icon(Icons.favorite_rounded),
      label: 'Readiness',
    ),
    NavigationDestination(
      icon: Icon(Icons.insights_outlined),
      selectedIcon: Icon(Icons.insights_rounded),
      label: 'Progress',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Account',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LeanEatColors.background,
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      floatingActionButton: _index == 5
          ? FloatingActionButton.extended(
              onPressed: _openTrainingSettings,
              icon: const Icon(Icons.tune_rounded),
              label: const Text('SETTINGS & TOOLS'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _selectDestination,
        destinations: _destinations,
      ),
    );
  }
}
