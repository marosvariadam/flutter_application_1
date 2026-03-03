import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/auth/data/repositories/auth_repository.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.bg,
      appBar: AppBar(
        backgroundColor: DT.bg,
        elevation: 0,
        leading: BackButton(color: DT.textPrimary),
        title: const Text('Regisztráció',
            style: TextStyle(color: DT.textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: DT.metricBlue,
          labelColor: DT.metricBlue,
          unselectedLabelColor: DT.textSecondary,
          tabs: const [
            Tab(text: 'Edző'),
            Tab(text: 'Sportoló'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _TrainerRegisterForm(),
          _AthleteRegisterForm(),
        ],
      ),
    );
  }
}

// ── Trainer form ──────────────────────────────────────────────────────────────

class _TrainerRegisterForm extends StatefulWidget {
  const _TrainerRegisterForm();

  @override
  State<_TrainerRegisterForm> createState() => _TrainerRegisterFormState();
}

class _TrainerRegisterFormState extends State<_TrainerRegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthRepository>().registerTrainer(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Sikeres regisztráció! Jelentkezz be.')),
        );
        context.go('/login');
      }
    } catch (_) {
      setState(
          () => _error = 'Nem sikerült regisztrálni. Próbáld újra.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DT.s5),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: DT.s4),
            _NameRow(first: _firstName, last: _lastName),
            const SizedBox(height: DT.s3),
            _EmailField(controller: _email),
            const SizedBox(height: DT.s3),
            _PasswordField(
                controller: _password,
                obscure: _obscure,
                onToggle: () =>
                    setState(() => _obscure = !_obscure)),
            if (_error != null) ...[
              const SizedBox(height: DT.s3),
              Text(_error!,
                  style: const TextStyle(
                      color: DT.cardRed, fontSize: DT.s3)),
            ],
            const SizedBox(height: DT.s6),
            _SubmitButton(
                label: 'Regisztráció',
                loading: _loading,
                onTap: _submit),
          ],
        ),
      ),
    );
  }
}

// ── Athlete form ──────────────────────────────────────────────────────────────

class _AthleteRegisterForm extends StatefulWidget {
  const _AthleteRegisterForm();

  @override
  State<_AthleteRegisterForm> createState() => _AthleteRegisterFormState();
}

class _AthleteRegisterFormState extends State<_AthleteRegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _trainerEmail = TextEditingController();
  final _intro = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _trainerEmail.dispose();
    _intro.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthRepository>().registerAthlete(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            trainerEmail: _trainerEmail.text.trim().isEmpty
                ? null
                : _trainerEmail.text.trim(),
            introNote:
                _intro.text.trim().isEmpty ? null : _intro.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Sikeres regisztráció! Jelentkezz be.')),
        );
        context.go('/login');
      }
    } catch (_) {
      setState(
          () => _error = 'Nem sikerült regisztrálni. Próbáld újra.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DT.s5),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: DT.s4),
            _NameRow(first: _firstName, last: _lastName),
            const SizedBox(height: DT.s3),
            _EmailField(controller: _email),
            const SizedBox(height: DT.s3),
            _PasswordField(
                controller: _password,
                obscure: _obscure,
                onToggle: () =>
                    setState(() => _obscure = !_obscure)),
            const SizedBox(height: DT.s5),
            const Text('Edző csatlakozás (opcionális)',
                style: TextStyle(
                    color: DT.textSecondary,
                    fontSize: DT.s3,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: DT.s3),
            TextFormField(
              controller: _trainerEmail,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Edző email (opcionális)',
                prefixIcon: Icon(Icons.person_search),
              ),
            ),
            const SizedBox(height: DT.s3),
            TextFormField(
              controller: _intro,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Bemutatkozó üzenet (opcionális)',
                prefixIcon: Icon(Icons.message_outlined),
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: DT.s3),
              Text(_error!,
                  style: const TextStyle(
                      color: DT.cardRed, fontSize: DT.s3)),
            ],
            const SizedBox(height: DT.s6),
            _SubmitButton(
                label: 'Regisztráció',
                loading: _loading,
                onTap: _submit),
          ],
        ),
      ),
    );
  }
}

// ── Shared form widgets ───────────────────────────────────────────────────────

class _NameRow extends StatelessWidget {
  final TextEditingController first;
  final TextEditingController last;
  const _NameRow({required this.first, required this.last});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: first,
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
            controller: last,
            decoration: const InputDecoration(labelText: 'Vezetéknév'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Kötelező' : null,
          ),
        ),
      ],
    );
  }
}

class _EmailField extends StatelessWidget {
  final TextEditingController controller;
  const _EmailField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
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
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  const _PasswordField(
      {required this.controller,
      required this.obscure,
      required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: 'Jelszó',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon:
              Icon(obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggle,
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Kötelező';
        if (v.length < 6) return 'Legalább 6 karakter';
        return null;
      },
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _SubmitButton(
      {required this.label, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: DT.metricBlue,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DT.rCardSmall)),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(label,
                style: const TextStyle(
                    color: DT.textWhite,
                    fontSize: DT.s4,
                    fontWeight: FontWeight.w600)),
      ),
    );
  }
}
