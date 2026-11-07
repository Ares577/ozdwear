import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const BottomNav({super.key, required this.index, required this.onChanged});
  @override
  Widget build(BuildContext context) => NavigationBar(selectedIndex: index, onDestinationSelected: onChanged, destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Ana Sayfa'), NavigationDestination(icon: Icon(Icons.grid_view_outlined), label: 'Kategoriler'), NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), label: 'Sepet'), NavigationDestination(icon: Icon(Icons.person_outline), label: 'Hesabım')]);
}
