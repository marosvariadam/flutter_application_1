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

            _ActivityList(),
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
            color: DT.metricGreen,
            title: 'Kezdő súly: ',
            value: '82.2 kg'
          )
        ),
        const SizedBox(width: DT.s3,),
        Expanded(
          child: _MetricCard(
            color: DT.metricBlue,
            title: 'Jelenlegi súly: ',
            value: '76.6 kg'
          )
        ),
        const SizedBox(width: DT.s3,),
        Expanded(
          child: _MetricCard(
            color: DT.metricOrange,
            title: 'Magasság: ',
            value: '176 cm'
          )
        ),
        const SizedBox(width: DT.s3,),
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
    return Container(
      padding: const EdgeInsets.all(DT.s2),
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(DT.rCardSmall)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: DT.s3,
              color: DT.textSecondary
            ),
          ),
          const SizedBox(height: DT.s2,),
          Text(
            value,
            style: TextStyle(
              fontSize: DT.s4,
              color: DT.textPrimary
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActivityItem(icon: Icons.directions_run, title: 'Fizikai Edzés', subtitle: '3 napja',onTap: () {},),
        _ActivityItem(icon: Icons.assessment, title: 'Statisztika', subtitle: '163 edzés idén',onTap: () {},),
        _ActivityItem(icon: Icons.route, title: 'Fejlődés', subtitle: 'Eddigi fejlődés',onTap: () {},),
        _ActivityItem(icon: Icons.flash_on, title: 'Eszközök', subtitle: 'Eddig használt eszközök',onTap: () {},),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActivityItem({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: DT.s4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: DT.borderLight, width: 1)
          )
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: DT.iconLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)
              ),
              child: Icon(icon, color: DT.iconLightGrey, size: 20),
            ),
            const SizedBox(width:DT.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: DT.s4,
                      fontWeight: FontWeight.w500,
                      color: DT.textPrimary
                    ),
                  ),
                  const SizedBox(height: 2,),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: DT.s3,
                      fontWeight: FontWeight.w500,
                      color: DT.textSecondary
                    ),
                  ),
                ],
            )
            ),
            const Icon(Icons.arrow_forward_ios, color: DT.textfrey, size: 14)
          ],
        )

      ),
    );
  }
}

