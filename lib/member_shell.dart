import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account_screen.dart';
import 'adaptive_strength_engine.dart';
import 'custom_workouts_screen.dart';
import 'exercise_library_screen.dart';
import 'exercise_performance_store.dart';
import 'lean_eat_theme.dart';
import 'leanit_control_center_screen.dart';
import 'leanit_home_dashboard.dart';
import 'leanit_preferences.dart';
import 'leanit_training_lab_screen.dart';
import 'notification_service.dart';
import 'progress_screen.dart';
import 'readiness_screen.dart';
import 'strength_adaptation_cache.dart';
import 'sync_queue.dart';
import 'training_settings.dart';
import 'training_store.dart';
import 'unit_display.dart';

class LeanEatMemberShell extends StatefulWidget {
  final Widget programmeHome;

  const LeanEatMemberShell({
    super.key,
    required this.programmeHome,
  });

  @override
  State<LeanEatMemberShell> createState() => _LeanEatMemberShellState();
}

class _LeanEatMemberShellState extends State<LeanEatMemberShell>
    with WidgetsBindingObserver {
  int _index = 0;
  int _homeRevision = 0;
  int _adaptationRefreshToken = 0;
  late List<Widget> _pages;
  LeanItPreferences _preferences = const LeanItPreferences();

  String get _scope =>
      Supabase.instance.client.auth.currentUser?.id ?? 'guest';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pages = _buildPages();
    TrainingStore.revision.addListener(_onTrainingRevision);
    unawaited(_refreshRuntimePreferences());
    unawaited(_refreshStrengthAdaptation());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    TrainingStore.revision.removeListener(_onTrainingRevision);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshRuntimePreferences());
      unawaited(_refreshStrengthAdaptation());
      unawaited(_flushPendingSync());
    }
  }

  void _onTrainingRevision() {
    unawaited(_refreshStrengthAdaptation());
    if (_preferences.automaticSync) unawaited(_flushPendingSync());
  }

  Future<void> _refreshRuntimePreferences() async {
    try {
      final training = await TrainingSettingsStore(userScope: _scope).load();
      final preferences = await LeanItPreferencesStore(userScope: _scope).load();
      UnitDisplay.setSystem(training.unitSystem);
      LeanItPreferencesCache.set(preferences);
      unawaited(LeanItNotificationService.apply(preferences));
      if (!mounted) return;
      setState(() => _preferences = preferences);
      if (preferences.automaticSync) unawaited(_flushPendingSync());
    } catch (_) {
      // Defaults remain usable if preferences cannot be read.
    }
  }

  Future<void> _flushPendingSync() async {
    if (!_preferences.automaticSync) return;
    try {
      await SyncCoordinator(
        client: Supabase.instance.client,
        userScope: _scope,
      ).flush();
    } catch (_) {
      // Sync remains queued and will retry on the next foreground/session event.
    }
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
      // The workout flow remains usable when analytics cannot refresh.
    }
  }

  List<Widget> _buildPages() => [
        LeanItHomeDashboard(
          key: ValueKey('home-$_homeRevision'),
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
    unawaited(_refreshRuntimePreferences());
    setState(() {
      _index = value;
      if (value == 0) {
        _homeRevision += 1;
        _pages[0] = LeanItHomeDashboard(
          key: ValueKey('home-$_homeRevision'),
          fallbackProgrammeHome: widget.programmeHome,
        );
      }
    });
  }

  Future<void> _openControlCenter() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LeanItControlCenterScreen()),
    );
    if (!mounted) return;
    await _refreshRuntimePreferences();
    setState(() {
      _homeRevision += 1;
      _pages[0] = LeanItHomeDashboard(
        key: ValueKey('home-$_homeRevision'),
        fallbackProgrammeHome: widget.programmeHome,
      );
    });
  }

  Future<void> _openTrainingLab() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const LeanItTrainingLabScreen()),
    );
    if (!mounted) return;
    await _refreshStrengthAdaptation();
    setState(() {
      _homeRevision += 1;
      _pages[0] = LeanItHomeDashboard(
        key: ValueKey('home-$_homeRevision'),
        fallbackProgrammeHome: widget.programmeHome,
      );
    });
  }

  Future<void> _openToolsMenu() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.science_outlined),
                title: const Text('Training Lab'),
                subtitle: const Text(
                  '100 m→Marathon plans, muscle recovery, RPE/RIR, programme library, evidence, offline tools and integrations.',
                ),
                onTap: () => Navigator.pop(sheetContext, 'lab'),
              ),
              ListTile(
                leading: const Icon(Icons.tune_rounded),
                title: const Text('Settings & Tools'),
                subtitle: const Text(
                  'Units, reminders, accessibility, sync, diagnostics and app health.',
                ),
                onTap: () => Navigator.pop(sheetContext, 'settings'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (selected == 'lab') {
      await _openTrainingLab();
    } else if (selected == 'settings') {
      await _openControlCenter();
    }
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
    final media = MediaQuery.of(context);
    final scale = _preferences.largeText ? 1.15 : 1.0;

    final content = Scaffold(
      backgroundColor: _preferences.highContrast
          ? Colors.white
          : LeanEatColors.background,
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      floatingActionButton: _index == 5
          ? FloatingActionButton.extended(
              onPressed: _openToolsMenu,
              icon: const Icon(Icons.dashboard_customize_rounded),
              label: const Text('LEANIT TOOLS'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        height: _preferences.largerTapTargets ? 88 : 80,
        selectedIndex: _index,
        onDestinationSelected: _selectDestination,
        destinations: _destinations,
      ),
    );

    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(scale)),
      child: Theme(
        data: Theme.of(context).copyWith(
          visualDensity: _preferences.largerTapTargets
              ? VisualDensity.comfortable
              : VisualDensity.standard,
          materialTapTargetSize: MaterialTapTargetSize.padded,
          pageTransitionsTheme: _preferences.reducedMotion
              ? const PageTransitionsTheme(
                  builders: <TargetPlatform, PageTransitionsBuilder>{
                    TargetPlatform.android: _NoMotionTransitionsBuilder(),
                    TargetPlatform.iOS: _NoMotionTransitionsBuilder(),
                    TargetPlatform.linux: _NoMotionTransitionsBuilder(),
                    TargetPlatform.macOS: _NoMotionTransitionsBuilder(),
                    TargetPlatform.windows: _NoMotionTransitionsBuilder(),
                    TargetPlatform.fuchsia: _NoMotionTransitionsBuilder(),
                  },
                )
              : Theme.of(context).pageTransitionsTheme,
        ),
        child: content,
      ),
    );
  }
}

class _NoMotionTransitionsBuilder extends PageTransitionsBuilder {
  const _NoMotionTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
