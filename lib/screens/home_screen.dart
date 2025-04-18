import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'feed_screen.dart';
import 'search_screen.dart';
import 'add_post_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  static const Color _primaryColor = Color(0xFF6B7FCE);
  
  final List<Widget> _screens = const [
    FeedScreen(),
    SearchScreen(),
    AddPostScreen(),
    ChatScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: _primaryColor,
        color: const Color.fromARGB(255, 0, 0, 0),
        animationDuration: const Duration(milliseconds: 300),
        index: _selectedIndex,
        items: [
          Image.asset(
            'assets/icons/home.png',
            width: 24,
            height: 24,
            color: _selectedIndex == 0 ? _primaryColor : Colors.grey,
          ),
          Image.asset(
            'assets/icons/search.png',
            width: 24,
            height: 24,
            color: _selectedIndex == 1 ? _primaryColor : Colors.grey,
          ),
          Image.asset(
            'assets/icons/plus.png',
            width: 24,
            height: 24,
            color: _selectedIndex == 2 ? _primaryColor : Colors.grey,
          ),
          Image.asset(
            'assets/icons/chat.png',
            width: 24,
            height: 24,
            color: _selectedIndex == 3 ? _primaryColor : Colors.grey,
          ),
          Image.asset(
            'assets/icons/profile.png',
            width: 24,
            height: 24,
            color: _selectedIndex == 4 ? _primaryColor : Colors.grey,
          ),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}