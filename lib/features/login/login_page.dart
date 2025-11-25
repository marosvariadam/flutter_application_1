import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 100.0, left: 24.0, right: 24.0),
          child: Column(
            children: [
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
              Form(child: Padding(
                padding: const EdgeInsets.all(DT.s5),
                child:
                Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Email cím',
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: DT.s2),
                    TextFormField(
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Jelszó',
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: Icon( Icons.visibility),
                      ),
                    ),
                    const SizedBox(height: DT.s4),

                    Row(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Checkbox(value: false, onChanged: (value) {}),
                            Text(
                              'Emlékezz rám',
                              style: TextStyle(
                                color: DT.textSecondary,
                                fontSize: DT.s3,
                              ),
                            ),
                          ],
                        ),
                        TextButton(onPressed: () {}, child: const Text('Elfelejtett jelszó?'))
                      ],
                    ),
                    const SizedBox(height: DT.s4),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {}, //validacio es beleptetes
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DT.metricBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DT.rCardSmall),
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

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {}, //regisztracio oldalra
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
                  )
                )
              )
            ],
          ) ,
        ),
      ),
    );
  }
}