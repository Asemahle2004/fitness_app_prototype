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
  int _homeRevision = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = _buildPages();
  }

  List<Widget> _buildPages() => [
        LeanEatTodayDashboard(
          key: ValueKey('today-$_homeRevision'),
          fallbackProgrammeHome: widget.programmeHome,
        ),
        ExerciseLibraryScreen(client: Supabase.instance.client),
        const ReadinessScreen(),
        const ProgressScreen(),
        const LeanEatAccountScreen(),
      ];

  void _selectDestination(int value) {
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
        onDestinationSelected: _selectDestination,
        destinations: _destinations,
      ),
    );
  }
}
