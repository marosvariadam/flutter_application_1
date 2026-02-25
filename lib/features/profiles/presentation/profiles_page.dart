import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';

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
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DT.s5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _UserProfileSection(),
            const SizedBox(height: DT.s6),
            const _MetricsRow(),
            const SizedBox(height: DT.s6),
            const _ActivityList(),
            const SizedBox(height: DT.s6),
          ],
        ),
      ),
    );
  }
}

class _UserProfileSection extends StatelessWidget {
  const _UserProfileSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: DT.borderGrey, width: 2),
            boxShadow: const [
              BoxShadow(
                color: DT.shadowLight,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.network(
              'https://example.com/user_profile.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: DT.iconLightGrey.withOpacity(0.3),
                child:
                    const Icon(Icons.person, size: DT.s6, color: DT.iconLight),
              ),
            ),
          ),
        ),
        const SizedBox(width: DT.s4),
        // Name + stats
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
              const SizedBox(height: DT.s1),
              const Text(
                'Budapest, Hungary',
                style: TextStyle(
                  color: DT.textSecondary,
                  fontSize: DT.s3,
                ),
              ),
              const SizedBox(height: DT.s2),
              Row(
                children: const [
                  Text(
                    'Edzések: 42',
                    style: TextStyle(
                      color: DT.textSecondary,
                      fontSize: DT.s3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: DT.s3),
                  Text(
                    'Streak: 7 nap',
                    style: TextStyle(
                      color: DT.textSecondary,
                      fontSize: DT.s3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Action buttons — proper 48×48 touch targets
        Column(
          children: [
            _ProfileActionButton(
              icon: Icons.edit,
              onTap: () {},
            ),
            const SizedBox(height: DT.s2),
            _ProfileActionButton(
              icon: Icons.share,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ProfileActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DT.iconLight.withOpacity(0.1),
      borderRadius: BorderRadius.circular(DT.s2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DT.s2),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Icon(icon, color: DT.iconLight, size: DT.s5),
          ),
        ),
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            color: DT.metricGreen,
            title: 'Kezdő súly',
            value: '82.2 kg',
          ),
        ),
        const SizedBox(width: DT.s3),
        Expanded(
          child: _MetricCard(
            color: DT.metricBlue,
            title: 'Jelenlegi súly',
            value: '76.6 kg',
          ),
        ),
        const SizedBox(width: DT.s3),
        Expanded(
          child: _MetricCard(
            color: DT.metricOrange,
            title: 'Magasság',
            value: '176 cm',
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MetricCard(
      {required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DT.s3),
      constraints: const BoxConstraints(minHeight: 80),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: DT.s3,
              color: DT.textSecondary,
            ),
          ),
          const SizedBox(height: DT.s2),
          Text(
            value,
            style: const TextStyle(
              fontSize: DT.s4,
              fontWeight: FontWeight.w700,
              color: DT.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActivityItem(
          icon: Icons.directions_run,
          title: 'Fizikai Edzés',
          subtitle: '3 napja',
          onTap: () {},
        ),
        _ActivityItem(
          icon: Icons.assessment,
          title: 'Statisztika',
          subtitle: '163 edzés idén',
          onTap: () {},
        ),
        _ActivityItem(
          icon: Icons.route,
          title: 'Fejlődés',
          subtitle: 'Eddigi fejlődés',
          onTap: () {},
        ),
        _ActivityItem(
          icon: Icons.flash_on,
          title: 'Eszközök',
          subtitle: 'Eddig használt eszközök',
          onTap: () {},
        ),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: DT.s4),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: DT.borderLight, width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: DT.iconLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: DT.iconLight, size: 20),
            ),
            const SizedBox(width: DT.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: DT.s4,
                      fontWeight: FontWeight.w500,
                      color: DT.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: DT.s3,
                      color: DT.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: DT.textGrey, size: 14),
          ],
        ),
      ),
    );
  }
}
