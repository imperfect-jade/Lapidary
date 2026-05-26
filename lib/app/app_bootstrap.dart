import 'package:flutter/material.dart';
import 'package:todolist/app/app_initializer.dart';
import 'package:todolist/app/app_routes.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/page/splash/splash.dart';

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool _initialized = false;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Future.wait([
        initializeApp(),
        Future<void>.delayed(const Duration(milliseconds: 1200)),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _initialized = true;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized) {
      return getRouteWidget();
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: ThemeController.defaultBodyFontFamily),
      home: SplashPage(
        isLoading: _loading,
        errorMessage: _error?.toString(),
        onRetry: _initialize,
      ),
    );
  }
}
