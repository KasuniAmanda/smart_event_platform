import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLogin = true;
  bool _obscureText = true;
  bool _isLoading = false;
  String _selectedRole = 'attendee';

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final authService = ref.read(authServiceProvider);
    try {
      if (_isLogin) {
        await authService.login(
          _emailController.text.trim(), 
          _passwordController.text.trim()
        );
      } else {
        await authService.registerUser(
          _emailController.text.trim(), 
          _passwordController.text.trim(), 
          _selectedRole
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🏷️ Brand Header
                  const Icon(Icons.confirmation_number_rounded, size: 80, color: Colors.indigo),
                  const SizedBox(height: 16),
                  Text(
                    _isLogin ? "Welcome Back" : "Join Evently",
                    style: const TextStyle(
                      fontSize: 28, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.indigo
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin 
                        ? "Sign in to manage your events" 
                        : "Create an account to get started",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 40),

                  // 📧 Email Input
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email Address",
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val!.isEmpty ? "Please enter your email" : null,
                  ),
                  const SizedBox(height: 20),

                  // 🔑 Password Input
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureText = !_obscureText),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val!.length < 6 ? "Minimum 6 characters required" : null,
                  ),

                  // 👥 Role Selection (Only for Registration)
                  if (!_isLogin) ...[
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: InputDecoration(
                        labelText: "I want to...",
                        prefixIcon: const Icon(Icons.person_search_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'attendee', child: Text("Book Events (Attendee)")),
                        DropdownMenuItem(value: 'organizer', child: Text("Host Events (Organizer)")),
                      ],
                      onChanged: (val) => setState(() => _selectedRole = val!),
                    ),
                  ],

                  const SizedBox(height: 30),

                  // 🚀 Submit Button
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 55),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: _submit,
                          child: Text(
                            _isLogin ? "LOGIN" : "CREATE ACCOUNT",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),

                  const SizedBox(height: 16),

                  // 🔄 Toggle Login/Register
                  TextButton(
                    onPressed: () => setState(() {
                      _isLogin = !_isLogin;
                      _formKey.currentState?.reset();
                    }),
                    child: Text(
                      _isLogin 
                          ? "New to the platform? Register here" 
                          : "Already have an account? Login",
                      style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}