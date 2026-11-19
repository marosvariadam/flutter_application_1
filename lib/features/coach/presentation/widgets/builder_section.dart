import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';

class BuilderSectionLabel extends StatelessWidget {
  final String text;
  const BuilderSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: DT.s2),
        child: Text(text,
            style: TextStyle(
                fontSize: DT.s3,
                fontWeight: FontWeight.w600,
                color: DT.of(context).textSecondary)),
      );
}

class BuilderWhiteCard extends StatelessWidget {
  final Widget child;
  const BuilderWhiteCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: DT.of(context).cardSurface,
            borderRadius: BorderRadius.circular(DT.rCardSmall)),
        child: child,
      );
}
