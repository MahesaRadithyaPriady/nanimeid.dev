import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import '../home_screen.dart';
import '../anime_list_screen.dart';
import '../history_screen.dart';
import '../favorite_screen.dart';
import '../profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late PersistentTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
  }

  Future<bool> _onWillPop() async {
    // Dismiss keyboard if any field focused
    FocusScope.of(context).unfocus();

    // If not on Home tab, switch to Home and prevent exit
    if (_controller.index != 0) {
      _controller.jumpToTab(0);
      return false;
    }

    // Show exit confirmation dialog
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.pinkAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.exit_to_app, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Keluar Aplikasi?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari aplikasi?',
            style: TextStyle(color: Colors.white, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.pinkAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );

    return shouldExit ?? false;
  }

  List<Widget> _buildScreens() => const [
    HomeScreen(),
    AnimeListScreen(),
    HistoryScreen(),
    FavoriteScreen(),
    ProfileScreen(),
  ];

  List<PersistentBottomNavBarItem> _navBarsItems() => [
    PersistentBottomNavBarItem(
      icon: const Icon(Icons.home),
      title: "Beranda",
      activeColorPrimary: Colors.pinkAccent,
      inactiveColorPrimary: Colors.white54,
    ),
    PersistentBottomNavBarItem(
      icon: const Icon(Icons.list),
      title: "Anime List",
      activeColorPrimary: Colors.pinkAccent,
      inactiveColorPrimary: Colors.white54,
    ),
    PersistentBottomNavBarItem(
      icon: const Icon(Icons.history),
      title: "Riwayat",
      activeColorPrimary: Colors.pinkAccent,
      inactiveColorPrimary: Colors.white54,
    ),
    PersistentBottomNavBarItem(
      icon: const Icon(Icons.favorite),
      title: "Favorit",
      activeColorPrimary: Colors.pinkAccent,
      inactiveColorPrimary: Colors.white54,
    ),
    PersistentBottomNavBarItem(
      icon: const Icon(Icons.person),
      title: "Profil",
      activeColorPrimary: Colors.pinkAccent,
      inactiveColorPrimary: Colors.white54,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: PersistentTabView(
          context,
          controller: _controller,
          screens: _buildScreens(),
          items: _navBarsItems(),
          backgroundColor: Colors.black,
          resizeToAvoidBottomInset: false,
          stateManagement: true,
          hideNavigationBarWhenKeyboardAppears: true,
          handleAndroidBackButtonPress: true,
          navBarStyle: NavBarStyle.style1,
          decoration: const NavBarDecoration(colorBehindNavBar: Colors.black),
          onWillPop: (ctx) async {
            // Delegate to the same logic as _onWillPop
            return _onWillPop();
          },
        ),
      ),
    );
  }
}
