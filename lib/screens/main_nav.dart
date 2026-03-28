// lib/screens/main_nav.dart
import 'package:flutter/material.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'schedule_screen.dart';
import 'grades_screen.dart';
import 'calendar_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

/// Global accessor so any child screen can switch tabs via MainNav.of(context).goTo(index)
class MainNav extends StatefulWidget {
  const MainNav({super.key});

  static MainNavState of(BuildContext context) =>
      context.findAncestorStateOfType<MainNavState>()!;

  @override
  State<MainNav> createState() => MainNavState();
}

class MainNavState extends State<MainNav> {
  int _currentIndex = 0;

  void goTo(int index) => setState(() => _currentIndex = index);

  final List<Widget> _screens = const [
    HomeScreen(),
    ScheduleScreen(),
    GradesScreen(),
    CalendarScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.border(context))),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _navItem(0, Icons.home_outlined, Icons.home, 'Home'),
                _navItem(1, Icons.calendar_today_outlined, Icons.calendar_today, 'Schedule'),
                _navItem(2, Icons.bar_chart_outlined, Icons.bar_chart, 'Grades'),
                _navItem(3, Icons.event_outlined, Icons.event, 'Calendar'),
                _navItem(4, Icons.notifications_outlined, Icons.notifications, 'Alerts'),
                _navItem(5, Icons.person_outline, Icons.person, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final bool active = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => goTo(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? activeIcon : icon,
                color: active ? AppTheme.primary : AppTheme.textMuted(context), size: 22),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? AppTheme.primary : AppTheme.textMuted(context),
                )),
          ],
        ),
      ),
    );
  }
}
