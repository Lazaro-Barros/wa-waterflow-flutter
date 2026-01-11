import 'package:flutter/material.dart';
import '../widgets/app_navigation_rail.dart';
import '../models/user_model.dart';
import 'home_screen.dart';
import 'water_sources/water_sources_list_screen.dart';

class MainScaffold extends StatefulWidget {
  final UserModel user;

  const MainScaffold({
    super.key,
    required this.user,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  AppPage _selectedPage = AppPage.dashboard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppNavigationRail(
            selectedPage: _selectedPage,
            onPageSelected: (page) {
              setState(() {
                _selectedPage = page;
              });
            },
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedPage) {
      case AppPage.dashboard:
        return HomeScreen(user: widget.user);
      case AppPage.waterSources:
        return const WaterSourcesListScreen();
    }
  }
}
