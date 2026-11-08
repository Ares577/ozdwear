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
import 'screens/favorites_screen.dart';
import 'widgets/bottom_nav.dart';
import 'core/push_service.dart';
import 'core/app_keys.dart';

void main() => runApp(ChangeNotifierProvider(create: (_) => AppState(), child: const OzdWearApp()));

class OzdWearApp extends StatefulWidget { const OzdWearApp({super.key}); @override State<OzdWearApp> createState() => _OzdWearAppState(); }
class _OzdWearAppState extends State<OzdWearApp> {
  int index = 0;
  @override void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) async { final state = context.read<AppState>(); await state.loadBootstrap(); await state.hydrateSession(); await PushService.initialize(state); }); }
  @override Widget build(BuildContext context) => Consumer<AppState>(builder: (context, state, _) => MaterialApp(scaffoldMessengerKey: appMessengerKey, title: '${state.bootstrap['app_name'] ?? 'OZD WEAR'}', theme: AppTheme.data((state.bootstrap['theme'] as Map?)?.cast<String, dynamic>()), routes: {'/product': (_) => const ProductScreen(), '/search': (_) => const SearchScreen()}, home: Scaffold(body: IndexedStack(index: index, children: const [HomeScreen(), CatalogScreen(), FavoritesScreen(), CartScreen(), AccountScreen()]), bottomNavigationBar: BottomNav(index: index, onChanged: (value) => setState(() => index = value)))));
}
