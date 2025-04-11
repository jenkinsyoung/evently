import 'package:evently/app/features/home/HomePage.dart';
import 'package:evently/app/features/map/MapPage.dart';
import 'package:evently/app/features/my_event/MyEventsPage.dart';
import 'package:evently/app/features/participate/ParticipatePage.dart';
import 'package:evently/app/features/profile/ProfilePage.dart';
import 'package:flutter/material.dart';


class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    MapEventPage(),
    ParticipateEventPage(),
    MyEventsPage(),
    ProfilePage(),
  ];
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Color(0xFF872341),
            unselectedItemColor: Colors.black87,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.location_on), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.note_add), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
            ],
          ),
        ),
      ),
    );
  }
}