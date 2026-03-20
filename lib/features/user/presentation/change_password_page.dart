import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/user/data/repositories/user_repository.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _newPw = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _newPw.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<UserRepository>().changePassword(
            _current.text,
            _newPw.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jelszó sikeresen megváltoztatva!')),
        );
        context.pop();
      }
    } catch (_) {
      setState(
          () => _error = 'Nem sikerült megváltoztatni a jelszót. Ellenőrizd a jelenlegi jelszavad.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.of(context).bg,
      appBar: AppBar(
        backgroundColor: DT.of(context).bg,
        elevation: 0,
        leading: BackButton(color: DT.of(context).textPrimary),
        title: Text('Jelszó módosítása',
            style: TextStyle(
                color: DT.of(context).textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DT.s5),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: DT.s4),
              _PwField(
                controller: _current,
                label: 'Jelenlegi jelszó',
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Kötelező' : null,
              ),
              const SizedBox(height: DT.s3),
              _PwField(
                controller: _newPw,
                label: 'Új jelszó',
                obscure: _obscureNew,
                onToggle: () =>
                    setState(() => _obscureNew = !_obscureNew),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Kötelező';
                  if (v.length < 6) return 'Legalább 6 karakter';
                  return null;
                },
              ),
              const SizedBox(height: DT.s3),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Új jelszó megerősítése',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) => v != _newPw.text
                    ? 'A jelszavak nem egyeznek'
                    : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: DT.s3),
                Text(_error!,
                    style: const TextStyle(
                        color: DT.cardRed, fontSize: DT.s3)),
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

class _PwField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?) validator;

  const _PwField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }
}
