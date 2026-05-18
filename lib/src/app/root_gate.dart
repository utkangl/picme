import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:picme/src/core/analytics/app_analytics.dart';
import 'package:picme/src/core/ui/app_startup_loading_screen.dart';
import 'package:picme/src/features/home/presentation/home_screen.dart';
import 'package:picme/src/features/onboarding/presentation/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  static const String _welcomeDoneKey = 'picme_welcome_done';

  _GateState _state = _GateState.loading;
  PermissionState? _permissionState;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final welcomeDone = prefs.getBool(_welcomeDoneKey) ?? false;

    if (!welcomeDone) {
      if (!mounted) return;
      setState(() => _state = _GateState.welcome);
      return;
    }

    // Welcome was already shown — check current permission and go straight to home.
    final permState = await PhotoManager.requestPermissionExtend();
    if (!mounted) return;
    unawaited(AppAnalytics.instance.logPermissionResult(permState));
    setState(() {
      _permissionState = permState;
      _state = _GateState.home;
    });
  }

  Future<void> _onPermissionResult(PermissionState result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeDoneKey, true);
    if (!mounted) return;
    unawaited(AppAnalytics.instance.logPermissionResult(result));
    setState(() {
      _permissionState = result;
      _state = _GateState.home;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _GateState.loading:
        return const AppStartupLoadingScreen();
      case _GateState.welcome:
        return WelcomeScreen(onPermissionResult: _onPermissionResult);
      case _GateState.home:
        return HomeScreen(initialPermissionState: _permissionState);
    }
  }
}

enum _GateState { loading, welcome, home }
