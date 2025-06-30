import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "../widgets/health_dashboard.dart";
import "map_page.dart";
import "my_profile_page.dart";
import "help_page.dart";
import "search_page.dart";
import "settings_page.dart";
import "goals_settings_page.dart";

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;

  final List<Widget> _pages = [
    const MainContentPage(),
    const SearchPage(),
    const MapPage(title: "Map"),
    const MyProfilePage(),
    const HelpPage(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                ),
                child: child,
              ),
            ),
          );
        },
        child: Container(
          key: ValueKey<int>(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index != _currentIndex) {
              // Add haptic feedback
              HapticFeedback.lightImpact();

              // Reset and start animation
              _animationController.reset();
              setState(() {
                _currentIndex = index;
              });
              _animationController.forward();
            }
          },
          backgroundColor: Colors.white,
          elevation: 8,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 11,
          ),
          items: [
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(_currentIndex == 0 ? 8 : 4),
                decoration: BoxDecoration(
                  color: _currentIndex == 0
                      // ignore: deprecated_member_use
                      ? Colors.deepPurple.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.home),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(_currentIndex == 1 ? 8 : 4),
                decoration: BoxDecoration(
                  color: _currentIndex == 1
                      // ignore: deprecated_member_use
                      ? Colors.deepPurple.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.search),
              ),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(_currentIndex == 2 ? 8 : 4),
                decoration: BoxDecoration(
                  color: _currentIndex == 2
                      // ignore: deprecated_member_use
                      ? Colors.deepPurple.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.map),
              ),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(_currentIndex == 3 ? 8 : 4),
                decoration: BoxDecoration(
                  color: _currentIndex == 3
                      // ignore: deprecated_member_use
                      ? Colors.deepPurple.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person),
              ),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(_currentIndex == 4 ? 8 : 4),
                decoration: BoxDecoration(
                  color: _currentIndex == 4
                      // ignore: deprecated_member_use
                      ? Colors.deepPurple.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.help),
              ),
              label: 'Help',
            ),
          ],
        ),
      ),
    );
  }
}

class MainContentPage extends StatelessWidget {
  const MainContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Tracker'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 4,
        shadowColor: Colors.deepPurple.withOpacity(0.3),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GoalsSettingsPage(),
                ),
              );
            },
            tooltip: 'Goals',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: const HealthDashboard(),
    );
  }
}

// Custom Animated Bottom Navigation Item Widget
class AnimatedBottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const AnimatedBottomNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              padding: EdgeInsets.all(isSelected ? 8 : 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.deepPurple.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: isSelected ? 1.1 : 1.0,
                child: Icon(
                  icon,
                  color: isSelected ? Colors.deepPurple : Colors.grey,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: isSelected ? Colors.deepPurple : Colors.grey,
                fontSize: isSelected ? 12 : 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
