import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account_screen.dart';
import 'exercise_library_screen.dart';
import 'lean_eat_theme.dart';
import 'progress_screen.dart';
import 'readiness_screen.dart';
import 'today_dashboard.dart';

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

  late final List<Widget> _pages = [
    LeanEatTodayDashboard(fallbackProgrammeHome: widget.programmeHome),
    ExerciseLibraryScreen(client: Supabase.instance.client),
    const ReadinessScreen(),
    const ProgressScreen(),
    const LeanEatAccountScreen(),
  ];

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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: _destinations,
      ),
    );
  }
}
