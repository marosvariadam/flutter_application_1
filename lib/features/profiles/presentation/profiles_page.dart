import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class ProfilesPage extends StatelessWidget {
  const ProfilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.bg,
      appBar: AppBar(
        backgroundColor: DT.bg,
        elevation: 0,
        title: const Text(
          'Profil',
          style: TextStyle(
            color: DT.textPrimary,
            fontSize: DT.s4,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () {}, 
          icon: const Icon(Icons.settings))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DT.s5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _UserProfileSelection(),
            const SizedBox(height: DT.s6),

            _MetricsCard(),
            const SizedBox(height: DT.s6),

            //_ActivityList(),
            const SizedBox(height: DT.s6),
          ],
        ),
      ),
    );
  }
}
class _UserProfileSelection extends StatelessWidget {
  const _UserProfileSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: DT.borderGrey, width: 2),
            boxShadow: [BoxShadow(
              color: DT.shadowLight,
              blurRadius: 10,
              offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.network(
          'https://example.com/user_profile.jpg',
          fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: DT.iconLightGrey.withOpacity(0.3),
                    child: const Icon(Icons.person, size: DT.s6, color: DT.iconLightGrey)
                  )
        ),
          ),
        ),
        const SizedBox(width: DT.s4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Jane Doe',
                style: TextStyle(
                  color: DT.textPrimary,
                  fontSize: DT.s5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: DT.s1),
              Text(
                'Budapest, Hungary',
                style: const TextStyle(
                  color: DT.textSecondary,
                  fontSize: DT.s3,
                ),
              ),
              const SizedBox(width: DT.s3),
              Row(
                children: [
                  Text(
                    'Edzések száma: 42',
                    style: const TextStyle(
                      color: DT.textSecondary,
                      fontSize: DT.s3,
                      fontWeight: FontWeight.w500
                    ),
                  ),
                  const SizedBox(width: DT.s3),
                  Text(
                    'Streak: 7 nap',
                    style: const TextStyle(
                      color: DT.textSecondary,
                      fontSize: DT.s3,
                      fontWeight: FontWeight.w500
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
        Column(
          children: [
            Container(
              width: DT.s9,
              height: DT.s9,
              decoration: BoxDecoration(
                color: DT.iconLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(DT.s2)
              ),
              child:
              const Icon(
                Icons.edit,
                color: DT.iconLightGrey,
                size: DT.s3,
              ),
            ),
            const SizedBox(height: DT.s2,),
            Container(
              width: DT.s9,
              height: DT.s9,
              decoration: BoxDecoration(
                color: DT.iconLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(DT.s2)
              ),
              child:
              const Icon(
                Icons.share,
                color: DT.iconLightGrey,
                size: DT.s3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            color: DT.metrictreen,
            title: 'Kezdő súly: ',
            value: '82.2 kg'
          )
        )
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _MetricCard({super.key, required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

