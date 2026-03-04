import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/trainer/data/repositories/roster_repository.dart';

/// Used both to create a new athlete account and edit an existing one.
class CreateEditAthletePage extends StatefulWidget {
  /// null → create mode; non-null → edit mode
  final String? athleteId;
  final String? initialFirstName;
  final String? initialLastName;
  final String? initialEmail;

  const CreateEditAthletePage({
    super.key,
    this.athleteId,
    this.initialFirstName,
    this.initialLastName,
    this.initialEmail,
  });

  bool get isEdit => athleteId != null;

  @override
  State<CreateEditAthletePage> createState() => _CreateEditAthletePageState();
}

class _CreateEditAthletePageState extends State<CreateEditAthletePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  final TextEditingController _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _firstName =
        TextEditingController(text: widget.initialFirstName ?? '');
    _lastName =
        TextEditingController(text: widget.initialLastName ?? '');
    _email = TextEditingController(text: widget.initialEmail ?? '');
  }

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
      final repo = context.read<RosterRepository>();
      if (widget.isEdit) {
        await repo.updateAthlete(
          widget.athleteId!,
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          email: _email.text.trim(),
        );
      } else {
        await repo.createAthlete(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.isEdit
                  ? 'Sportoló frissítve!'
                  : 'Sportoló létrehozva!')),
        );
        context.pop();
      }
    } catch (_) {
      setState(() =>
          _error = 'A művelet nem sikerült. Ellenőrizd az adatokat.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.bg,
      appBar: AppBar(
        backgroundColor: DT.bg,
        elevation: 0,
        leading: BackButton(color: DT.textPrimary),
        title: Text(
            widget.isEdit ? 'Sportoló szerkesztése' : 'Új sportoló',
            style: const TextStyle(
                color: DT.textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DT.s5),
        child: Form(
          key: _formKey,
          child: Column(
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
                          labelText: 'Vezetéknév'),
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
              if (!widget.isEdit) ...[
                const SizedBox(height: DT.s3),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Kezdő jelszó',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Kötelező';
                    if (v.length < 6) return 'Legalább 6 karakter';
                    return null;
                  },
                ),
              ],
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
                  onPressed: _loading ? null : _submit,
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
                      : Text(widget.isEdit ? 'Mentés' : 'Létrehozás',
                          style: const TextStyle(
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
