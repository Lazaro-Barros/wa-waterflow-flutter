import 'package:flutter/material.dart';

enum AppPage {
  dashboard,
  waterSources,
  regions,
  trucks,
  drivers,
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
        NavigationRailDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map),
          label: Text('Regiões'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.local_shipping_outlined),
          selectedIcon: Icon(Icons.local_shipping),
          label: Text('Caminhões'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Motoristas'),
        ),
      ],
    );
  }
}
