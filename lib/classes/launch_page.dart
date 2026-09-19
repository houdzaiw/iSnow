import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/travel_bootstrap/travel_bootstrap_exception.dart';
import '../core/travel_bootstrap/travel_session_manager.dart';
import '../manager/auth_session.dart';
import '../theme/app_theme.dart';

class LaunchPage extends StatefulWidget {
  const LaunchPage({super.key});

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> {
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeTravelSession();
  }

  Future<void> _initializeTravelSession() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }
    try {
      await TravelSessionManager.shared.start();
      if (!mounted) return;
      final isLoggedIn = await _isUserLoggedIn();
      if (!mounted) return;
      context.go(isLoggedIn ? '/home' : '/login');
    } on TravelBootstrapException catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = error.message;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage =
              'Unable to initialize the test service. Please try again.';
        });
      }
    }
  }

  Future<bool> _isUserLoggedIn() async {
    return AuthSession.instance.isLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      backgroundColor: AppColors.cardBackground,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.lanhuLoginBackground),
            fit: BoxFit.cover,
          ),
        ),
        child: _errorMessage == null
            ? (_loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const SizedBox.shrink())
            : Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 14),
                          FilledButton(
                            onPressed: _initializeTravelSession,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
