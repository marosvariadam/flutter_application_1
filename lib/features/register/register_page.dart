import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _trainerNameController = TextEditingController();

  // 0 = Trainer (Edző), 1 = Athlete (Sportoló)
  int _selectedRole = 1;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  bool get _isAthlete => _selectedRole == 1;

  Future<void> _handleRegister() async {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minden mező kitöltése kötelező!')),
      );
      return;
    }

    if (_isAthlete && _trainerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kérjük, add meg az edződ nevét!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _authService.register(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: _selectedRole,
      );

      if (!mounted) return;

      if (success) {
        if (_isAthlete) {
          // Athletes go through the onboarding survey before logging in
          context.push('/athlete-survey');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sikeres regisztráció! Jelentkezz be.')),
          );
          context.pop();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hiba történt a regisztráció során.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hiba: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: DT.of(context).textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Fiók létrehozása',
                style: TextStyle(
                  color: DT.of(context).textPrimary,
                  fontSize: DT.s8,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: DT.s2),
              Text(
                'Töltsd ki az adataidat a regisztrációhoz',
                style: TextStyle(
                  color: DT.of(context).textSecondary,
                  fontSize: DT.s4,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: DT.s5),

              // Name fields
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Vezetéknév',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                  ),
                  const SizedBox(width: DT.s2),
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'Keresztnév',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DT.s2),

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
                  suffixIcon: Icon(Icons.visibility),
                ),
              ),
              const SizedBox(height: DT.s4),

              // Role Selector
              Text(
                'Válassz szerepkört:',
                style: TextStyle(
                    color: DT.of(context).textSecondary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: DT.s2),
              Row(
                children: [
                  Expanded(
                    child: _buildRoleCard('Sportoló', 1, Icons.directions_run),
                  ),
                  const SizedBox(width: DT.s2),
                  Expanded(
                    child: _buildRoleCard('Edző', 0, Icons.fitness_center),
                  ),
                ],
              ),

              // Trainer name field - only shown for athletes
              if (_isAthlete) ...[
                const SizedBox(height: DT.s4),
                Text(
                  'Edző neve',
                  style: TextStyle(
                      color: DT.of(context).textSecondary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: DT.s2),
                TextFormField(
                  controller: _trainerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Az edződ neve',
                    hintText: 'Pl. Kovács László',
                    prefixIcon: Icon(Icons.person_search),
                  ),
                ),
                const SizedBox(height: DT.s2),
                Text(
                  'Add meg annak az edzőnek a nevét, akihez csatlakozni szeretnél.',
                  style: TextStyle(
                    color: DT.of(context).textSecondary,
                    fontSize: DT.s3,
                  ),
                ),
              ],

              const SizedBox(height: DT.s6),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DT.metricBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DT.rCardSmall),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Regisztráció',
                          style: TextStyle(
                            color: DT.textWhite,
                            fontSize: DT.s4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String title, int value, IconData icon) {
    final isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = value),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? DT.metricBlue.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? DT.metricBlue : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(DT.rCardSmall),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? DT.metricBlue : Colors.grey),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? DT.metricBlue : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
