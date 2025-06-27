import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scoreboard/widgets/appbar_icon.dart';
import '../providers/auth_provider.dart';
import '../routes/routes.dart';
import '../constants/ui_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        await Provider.of<AuthProvider>(context, listen: false)
            .signIn(_emailController.text.trim(), _passwordController.text);
        
        if (!mounted) return;
        
        // Navigate to the appropriate screen after login
        Navigator.of(context).pushReplacementNamed(AppRoutes.groups);
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _navigateToRegister() {
    Navigator.of(context).pushNamed(AppRoutes.register);
  }

  void _navigateToLeaderboard() {
    Navigator.of(context).pushNamed(AppRoutes.leaderboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        title: const Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppBarIcon(),
            Spacer(),
            Center(
              child: Text('Scoreboard App'),
            ),
            Spacer(),
            SizedBox(height: 150,
            width: 150,)

          ],
        ),
        // title: const Text('Scoreboard App by Rahman'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: AppPadding.screenPaddingResponsive,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.scoreboard,
                size: 80,
                color: Colors.blue,
              ),
              SizedBox(height: AppPadding.mediumSpacing),
              const Text(
                'Welcome to Scoreboard',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: AppPadding.largeSpacing),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppPadding.smallSpacing * 2),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    if (_errorMessage.isNotEmpty) ...[  
                      SizedBox(height: AppPadding.smallSpacing * 2),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    SizedBox(height: AppPadding.mediumSpacing),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      // Using theme-based button style, no need to specify padding here
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Sign In', style: TextStyle(fontSize: 16)),
                    ),
                    SizedBox(height: AppPadding.smallSpacing * 2),
                    // TextButton(
                    //   onPressed: _navigateToRegister,
                    //   child: const Text('Don\'t have an account? Register'),
                    // ),
                    SizedBox(height: AppPadding.mediumSpacing),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}