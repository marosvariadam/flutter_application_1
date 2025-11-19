import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class SessionsPage extends StatelessWidget {
  const SessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.bg,
      appBar: AppBar(
        backgroundColor: DT.bg,
        elevation: 0,
        title: const Text(
          'Edezés',
          style: TextStyle(
            color: DT.textPrimary,
            fontSize: DT.s4,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DT.s5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Elérhető edzések',
              style: TextStyle(
                color: DT.textPrimary,
                fontSize: DT.s6,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: DT.s2),
            const Text(
              'Válassz az edzések közül:',
              style: TextStyle(
                color: DT.textPrimary,
                fontSize: DT.s4,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: DT.s6),
            _SessionCard(
              title: 'Teljes test edzés',
              trainer: 'John Doe',
              kcal: '300 kcal',
              description: 'Egy átfogó edzésprogram az egész test erősítésére.',
              duration: '45 perc',
              difficulty: 'Könnyű',
              color: DT.cardOrange,
              onTap: ()=>context.go('/session-detail')
            ),
            const SizedBox(height: DT.s6),
            _SessionCard(
              title: 'Felső test edzés',
              trainer: 'John Doe',
              kcal: '450 kcal',
              description: 'Edzés a felső test izmainak erősítésére.',
              duration: '45 perc',
              difficulty: 'Közepes',
              color: DT.cardYellow,
              onTap: ()=>context.go('/session-detail')
            ),
            const SizedBox(height: DT.s6),
            _SessionCard(
              title: 'Alsó test edzés',
              trainer: 'John Doe',
              kcal: '550 kcal',
              description: 'Edzés az alsó test izmainak erősítésére.',
              duration: '45 perc',
              difficulty: 'Nehéz',
              color: DT.cardBlue,
              onTap: ()=>context.go('/session-detail')
            ),
            const SizedBox(height: DT.s6),
            _SessionCard(
              title: 'Felső test edzés',
              trainer: 'John Doe',
              kcal: '450 kcal',
              description: 'Edzés a felső test izmainak erősítésére.',
              duration: '45 perc',
              difficulty: 'Közepes',
              color: DT.cardYellow,
              onTap: ()=>context.go('/session-detail')
            ),
            const SizedBox(height: DT.s6),
          ],
        ),
      )
    );
  }
}

class _SessionCard extends StatelessWidget {
  final String title;
  final String kcal;
  final String trainer;
  final String description;
  final String duration;
  final String difficulty;
  final Color color;
  final VoidCallback onTap;
  const _SessionCard({super.key, required this.title, required this.trainer, required this.description, required this.duration, required this.difficulty, required this.color, required this.onTap, required this.kcal});

  @override
  Widget build(BuildContext context) {
    final difficultyColor = {
      'könnyű': DT.difficultyLight,
      'közepes': DT.difficultyMedium,
      'nehéz': DT.difficultyHard,
    }[difficulty.toLowerCase()] ?? DT.difficultyMedium;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(DT.s5),
        decoration: BoxDecoration(
          color: DT.gbWhite,
          borderRadius: BorderRadius.circular(DT.s5),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 80,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(DT.s2),
              ),
            ),
            const SizedBox(width: DT.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                  
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: DT.textPrimary,
                        fontSize: DT.s4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: DT.s2, vertical: DT.s1),
                      decoration: BoxDecoration(
                        color: difficultyColor,
                        borderRadius: BorderRadius.circular(DT.s2),
                      ),
                      child: Text(
                        difficulty,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: DT.s3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                  const SizedBox(height: DT.s1),
                  Text(
                    'Edző: $trainer',
                    style: const TextStyle(
                      color: DT.textSecondary,
                      fontSize: DT.s3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: DT.s1),
                  Text(
                    'Leírás: $description',
                    style: const TextStyle(
                      color: DT.textSecondary,
                      fontSize: DT.s3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: DT.s1,),
                  Row(
                children: [
                    _InfoChip(
                      icon: Icons.access_time,
                      text: duration,
                    ),
                    const SizedBox(width: DT.s2),
                    _InfoChip(
                      icon: Icons.local_fire_department,
                      text: kcal,
                    )
                ],
                  ),
                  const SizedBox(height: DT.s2),
                ]
              ),
            ),
            Container(
              
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(DT.rChip),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: color,
                      size: 16,
                    ),
                  ),
          ],
        ),
      )
    );
  }
}



class _InfoChip extends StatelessWidget {
  const _InfoChip({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: DT.s4,
          color: DT.iconLight,
        ),
        const SizedBox(width: DT.s1),
        Text(
          text,
          style: const TextStyle(
            color: DT.textSecondary,
            fontSize: DT.s3,
            fontWeight: FontWeight.w500,
          ),
        ),
      ]
    );
  }
}