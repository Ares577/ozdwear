import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _storeUrl = 'https://ozdwear.com/';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OzdWearWebApp());
}

class OzdWearWebApp extends StatelessWidget {
  const OzdWearWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OZD WEAR',
      theme: ThemeData(brightness: Brightness.light, scaffoldBackgroundColor: Colors.white, useMaterial3: true),
      home: const StoreWebViewScreen(),
    );
  }
}

class StoreWebViewScreen extends StatefulWidget {
  const StoreWebViewScreen({super.key});

  @override
  State<StoreWebViewScreen> createState() => _StoreWebViewScreenState();
}

class _StoreWebViewScreenState extends State<StoreWebViewScreen> {
  WebViewController? _controller;
  Timer? _splashTimer;
  bool _showSplash = true;
  bool _loaded = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _splashTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _showSplash = false);
    });
    _createWebView();
  }

  void _createWebView() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _errorMessage = null;
              _loaded = false;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _loaded = true;
              _errorMessage = null;
            });
          },
          onWebResourceError: (error) {
            if (!mounted || _loaded) return;
            setState(() {
              _errorMessage = _messageForWebError(error);
              _showSplash = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(_storeUrl));
    _controller = controller;
  }

  String _messageForWebError(WebResourceError error) {
    final type = error.errorType;
    if (type == WebResourceErrorType.hostLookup || type == WebResourceErrorType.connect || type == WebResourceErrorType.timeout) {
      return 'Ağ bağlantısı yok. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.';
    }
    return 'Sunucu ile ilgili bir sorun var. Lütfen daha sonra tekrar deneyin.';
  }

  Future<bool> _handleBack() async {
    final controller = _controller;
    if (controller != null && await controller.canGoBack()) {
      await controller.goBack();
      return false;
    }
    return true;
  }

  void _retry() {
    setState(() {
      _errorMessage = null;
      _loaded = false;
      _showSplash = true;
    });
    _splashTimer?.cancel();
    _splashTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _showSplash = false);
    });
    _controller?.loadRequest(Uri.parse(_storeUrl));
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = _errorMessage;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _handleBack() && mounted) Navigator.of(context).maybePop();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_controller != null && errorMessage == null) WebViewWidget(controller: _controller!),
            if (errorMessage != null) _ErrorView(message: errorMessage, onRetry: _retry),
            if (_showSplash) const _SplashView(),
          ],
        ),
      ),
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image(image: AssetImage('assets/branding/ozdwear-logo.png'), width: 150),
            SizedBox(height: 24),
            SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black)),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 42, color: Colors.black54),
              const SizedBox(height: 18),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.4, color: Colors.black87)),
              const SizedBox(height: 22),
              OutlinedButton(onPressed: onRetry, child: const Text('Tekrar dene')),
            ],
          ),
        ),
      ),
    );
  }
}
