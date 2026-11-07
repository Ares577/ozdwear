import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class CartScreen extends StatelessWidget { const CartScreen({super.key}); @override Widget build(BuildContext context) { final state = context.watch<AppState>(); return SafeArea(child: FutureBuilder(future: state.api.get('cart'), builder: (context, snapshot) { if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator()); if (snapshot.hasError) return Center(child: Text('Sepeti görmek için giriş yapın.')); final data = snapshot.data as Map; return ListView(padding: const EdgeInsets.all(20), children: [const Text('Sepetim', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)), const SizedBox(height: 20), Text('${data['data'] ?? data}')]); })); } }
