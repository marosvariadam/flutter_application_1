import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // TODO: replace with actual auth call via BLoC
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 100.0, left: 24.0, right: 24.0),
          child: Column(
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
              Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(DT.s5),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email cím',
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Kérjük add meg az email címed';
                          }
                          if (!value.contains('@')) {
                            return 'Érvénytelen email cím';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: DT.s2),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Jelszó',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Kérjük add meg a jelszavad';
                          }
                          if (value.length < 6) {
                            return 'A jelszónak legalább 6 karakter hosszúnak kell lennie';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: DT.s4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) => setState(
                                  () => _rememberMe = value ?? false,
                                ),
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
                            child: const Text('Elfelejtett jelszó?'),
                          ),
                        ],
                      ),
                      const SizedBox(height: DT.s6),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DT.metricBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(DT.rCardSmall),
                            ),
                          ),
                          child: Text(
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
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {}, // TODO: navigate to registration
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: DT.metricBlue),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(DT.rCardSmall),
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
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
