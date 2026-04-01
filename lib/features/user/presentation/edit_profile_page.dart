import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/auth/bloc/auth_bloc.dart';
import 'package:flutter_application_1/features/user/data/repositories/user_repository.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _weight;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>().state;
    final user = auth is AuthAuthenticated ? auth.user : null;
    _firstName = TextEditingController(text: user?.firstName ?? '');
    _lastName = TextEditingController(text: user?.lastName ?? '');
    _email = TextEditingController(text: user?.email ?? '');
    _weight = TextEditingController(
      text: user?.weightKg != null ? user!.weightKg!.toStringAsFixed(1) : '',
    );
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final weightText = _weight.text.trim();
      final weightKg = weightText.isNotEmpty ? double.tryParse(weightText) : null;

      final updated = await context.read<UserRepository>().updateUser(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            email: _email.text.trim(),
            weightKg: weightKg,
          );
      if (mounted) {
        context.read<AuthBloc>().add(AuthUserUpdated(updated));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil frissítve!')),
        );
        context.pop();
      }
    } catch (_) {
      setState(() => _error = 'Nem sikerült frissíteni a profilt.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final isAthlete = auth is AuthAuthenticated && auth.user.isAthlete;

    return Scaffold(
      backgroundColor: DT.of(context).bg,
      appBar: AppBar(
        backgroundColor: DT.of(context).bg,
        elevation: 0,
        leading: BackButton(color: DT.of(context).textPrimary),
        title: Text('Profil szerkesztése',
            style: TextStyle(
                color: DT.of(context).textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DT.s5),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: DT.s4),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstName,
                      decoration: const InputDecoration(
                        labelText: 'Keresztnév',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Kötelező' : null,
                    ),
                  ),
                  const SizedBox(width: DT.s3),
                  Expanded(
                    child: TextFormField(
                      controller: _lastName,
                      decoration: const InputDecoration(
                        labelText: 'Vezetéknév',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Kötelező' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DT.s3),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email cím',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Kötelező';
                  if (!v.contains('@')) return 'Érvénytelen email';
                  return null;
                },
              ),
              if (isAthlete) ...[
                const SizedBox(height: DT.s6),
                Text(
                  'Fizikai adatok',
                  style: TextStyle(
                    color: DT.of(context).textSecondary,
                    fontSize: DT.s3,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: DT.s3),
                TextFormField(
                  controller: _weight,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Testsúly (kg)',
                    prefixIcon: Icon(Icons.monitor_weight_outlined),
                    suffixText: 'kg',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null; // optional
                    final parsed = double.tryParse(v.trim());
                    if (parsed == null || parsed <= 0) return 'Érvénytelen érték';
                    return null;
                  },
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: DT.s3),
                Text(_error!,
                    style:
                        const TextStyle(color: DT.cardRed, fontSize: DT.s3)),
              ],
              const SizedBox(height: DT.s6),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DT.metricBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(DT.rCardSmall)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Mentés',
                          style: TextStyle(
                              color: DT.textWhite,
                              fontSize: DT.s4,
                              fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
