import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/design/dt_text.dart';

/// Shortcut card on the athlete home (stats, prediction): a light tint of
/// [color] with a left accent bar, an icon circle, title and subtitle.
class HomeEntryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const HomeEntryCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = DTText.of(context);
    final radius = BorderRadius.circular(DT.rCardSmall);
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DT.s5),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: DT.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.title),
                    const SizedBox(height: DT.s1),
                    Text(subtitle, style: t.caption),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: DT.of(context).textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
