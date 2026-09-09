import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_storage.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? _email;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final token = await AuthStorage.getToken();

    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      final user = await ApiClient.getMe(token);
      if (!mounted) return;
      setState(() {
        _email = user.email;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await AuthStorage.clearToken();
        _redirectToLogin();
        return;
      }
      // Backend unreachable or some other error: show it instead of a blank screen.
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  void _redirectToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _logout() async {
    await AuthStorage.clearToken();
    _redirectToLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CyberSaathi'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _errorMessage != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            setState(() => _isLoading = true);
                            _loadCurrentUser();
                          },
                          child: const Text('Retry'),
                        ),
                        TextButton(
                          onPressed: _logout,
                          child: const Text('Log out'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Logged in as'),
                      const SizedBox(height: 8),
                      Text(
                        _email ?? '',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
      ),
    );
  }
}
