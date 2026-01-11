import 'package:flutter/material.dart';

enum AppPage {
  dashboard,
  waterSources,
}

class AppNavigationRail extends StatelessWidget {
  final AppPage selectedPage;
  final Function(AppPage) onPageSelected;

  const AppNavigationRail({
    super.key,
    required this.selectedPage,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedPage.index,
      onDestinationSelected: (index) {
        onPageSelected(AppPage.values[index]);
      },
      labelType: NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.waves_outlined),
          selectedIcon: Icon(Icons.waves),
          label: Text('Mananciais'),
        ),
      ],
    );
  }
}
