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
    return Scaffold(
      body: PersistentTabView(
        context,
        controller: _controller,
        screens: _buildScreens(),
        items: _navBarsItems(),
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        stateManagement: true,
        hideNavigationBarWhenKeyboardAppears: true,
        navBarStyle: NavBarStyle.style1,
        decoration: NavBarDecoration(colorBehindNavBar: Colors.black),
      ),
    );
  }
}
