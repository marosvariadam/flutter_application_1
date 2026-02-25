import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart'; 
import 'package:flutter_application_1/services/auth_service.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 1. Controllers to capture text input
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // 2. State for loading spinner
  bool _isLoading = false;
  bool _rememberMe = false;
  final AuthService _authService = AuthService();

  // 3. Login Logic
  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kérlek tölts ki minden mezőt!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _authService.login(
        _emailController.text, 
        _passwordController.text
      );

      if (!mounted) return;

      if (success) {
        // Navigate to Home on success
        context.go('/home'); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hibás email vagy jelszó!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hiba történt: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 100.0, left: 24.0, right: 24.0),
          child: Column(
            children: [
              // --- Header Section ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Üdvözlünk vissza!',
                    style: TextStyle(
                      color: DT.textPrimary,
                      fontSize: DT.s8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: DT.s2),
                  Text(
                    'Jelentkezz be a folytatáshoz',
                    style: TextStyle(
                      color: DT.textSecondary,
                      fontSize: DT.s4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              
              // --- Form Section ---
              Padding(
                padding: const EdgeInsets.symmetric(vertical: DT.s5),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email cím',
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: DT.s2),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Jelszó',
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: Icon(Icons.visibility), // You can make this clickable later
                      ),
                    ),
                    const SizedBox(height: DT.s4),

                    // --- Remember Me & Forgot Password ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe, 
                              onChanged: (value) => setState(() => _rememberMe = value!)
                            ),
                            Text(
                              'Emlékezz rám',
                              style: TextStyle(
                                color: DT.textSecondary,
                                fontSize: DT.s3,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {}, 
                          child: const Text('Elfelejtett jelszó?')
                        )
                      ],
                    ),
                    const SizedBox(height: DT.s6),

                    // --- Login Button ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DT.metricBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DT.rCardSmall),
                          ),
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Bejelentkezés',
                              style: TextStyle(
                                color: DT.textWhite,
                                fontSize: DT.s4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(height: DT.s5),

                    // --- Register Button ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => context.push('/register'), // Use push to allow "Back"
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: DT.metricBlue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DT.rCardSmall),
                          ),
                        ),
                        child: Text(
                          'Regisztráció',
                          style: TextStyle(
                            color: DT.metricBlue,
                            fontSize: DT.s4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}