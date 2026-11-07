import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/catalog_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/account_screen.dart';
import 'screens/product_screen.dart';
import 'screens/search_screen.dart';
import 'widgets/bottom_nav.dart';
import 'core/push_service.dart';

void main() => runApp(ChangeNotifierProvider(create: (_) => AppState(), child: const OzdWearApp()));

class OzdWearApp extends StatefulWidget { const OzdWearApp({super.key}); @override State<OzdWearApp> createState() => _OzdWearAppState(); }
class _OzdWearAppState extends State<OzdWearApp> {
  int index = 0;
  @override void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) async { final state = context.read<AppState>(); await state.hydrateSession(); await PushService.initialize(state); }); }
  @override Widget build(BuildContext context) => MaterialApp(title: 'OZD WEAR', theme: AppTheme.data(), routes: {'/product': (_) => const ProductScreen(), '/search': (_) => const SearchScreen()}, home: Scaffold(body: IndexedStack(index: index, children: const [HomeScreen(), CatalogScreen(), CartScreen(), AccountScreen()]), bottomNavigationBar: BottomNav(index: index, onChanged: (value) => setState(() => index = value))));
}
