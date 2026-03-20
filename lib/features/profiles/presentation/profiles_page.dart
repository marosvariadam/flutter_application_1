import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/app/bloc/theme_cubit.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/shared/widgets/notification_bell.dart';
import 'package:flutter_application_1/features/auth/bloc/auth_bloc.dart';
import 'package:flutter_application_1/features/user/data/models/user_model.dart';

class ProfilesPage extends StatelessWidget {
  const ProfilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthAuthenticated ? authState.user : null;
        return Scaffold(
          backgroundColor: DT.of(context).bg,
          appBar: AppBar(
            backgroundColor: DT.of(context).bg,
            elevation: 0,
            title: Text(
              'Profil',
              style: TextStyle(
                color: DT.of(context).textPrimary,
                fontSize: DT.s4,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            actions: const [NotificationBell()],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(DT.s5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _UserProfileSection(user: user),
                const SizedBox(height: DT.s6),
                if (user?.isAthlete == true) ...[
                  const _MetricsRow(),
                  const SizedBox(height: DT.s6),
                ],
                _MenuSection(user: user),
                const SizedBox(height: DT.s6),
                _LogoutButton(),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Profile header ─────────────────────────────────────────────────────────

class _UserProfileSection extends StatelessWidget {
  final UserModel? user;
  const _UserProfileSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user != null
        ? '${user!.firstName} ${user!.lastName}'.trim()
        : 'Betöltés...';
    final email = user?.email ?? '';
    final role = user?.isTrainer == true ? 'Edző' : 'Sportoló';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DT.metricBlue.withOpacity(0.15),
            border: Border.all(color: DT.of(context).borderGrey, width: 2),
          ),
          child: Center(
            child: Text(
              _initials(name),
              style: const TextStyle(
                  color: DT.metricBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: DT.s4),
            ),
          ),
        ),
        const SizedBox(width: DT.s4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: TextStyle(
                      color: DT.of(context).textPrimary,
                      fontSize: DT.s5,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(email,
                  style: TextStyle(
                      color: DT.of(context).textSecondary, fontSize: DT.s3)),
              const SizedBox(height: DT.s2),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: DT.s2, vertical: 2),
                decoration: BoxDecoration(
                  color: DT.metricBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(role,
                    style: const TextStyle(
                        color: DT.metricBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        _ProfileActionButton(
          icon: Icons.edit_outlined,
          onTap: () => context.push('/profile/edit'),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class _ProfileActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ProfileActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DT.of(context).iconLight.withOpacity(0.1),
      borderRadius: BorderRadius.circular(DT.s2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DT.s2),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(child: Icon(icon, color: DT.of(context).iconLight, size: DT.s4)),
        ),
      ),
    );
  }
}

// ── Metrics row (athlete only) ─────────────────────────────────────────────

class _MetricsRow extends StatelessWidget {
  const _MetricsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _MetricCard(
              color: DT.metricGreen, title: 'Kezdő súly', value: '— kg'),
        ),
        SizedBox(width: DT.s3),
        Expanded(
          child: _MetricCard(
              color: DT.metricBlue, title: 'Jelenlegi', value: '— kg'),
        ),
        SizedBox(width: DT.s3),
        Expanded(
          child: _MetricCard(
              color: DT.metricOrange, title: 'Magasság', value: '— cm'),
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
      constraints: const BoxConstraints(minHeight: 72),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: DT.s3, color: DT.of(context).textSecondary)),
          const SizedBox(height: DT.s1),
          Text(value,
              style: TextStyle(
                  fontSize: DT.s4,
                  fontWeight: FontWeight.w700,
                  color: DT.of(context).textPrimary)),
        ],
      ),
    );
  }
}

// ── Menu section ───────────────────────────────────────────────────────────

class _MenuSection extends StatelessWidget {
  final UserModel? user;
  const _MenuSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final isTrainer = user?.isTrainer == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader('Fiók'),
        _MenuItem(
          icon: Icons.person_outline,
          title: 'Profil szerkesztése',
          onTap: () => context.push('/profile/edit'),
        ),
        _MenuItem(
          icon: Icons.lock_outline,
          title: 'Jelszó megváltoztatása',
          onTap: () => context.push('/profile/change-password'),
        ),
        const SizedBox(height: DT.s4),
        _SectionHeader(isTrainer ? 'Edző eszközök' : 'Sportoló eszközök'),
        if (isTrainer) ...[
          _MenuItem(
            icon: Icons.group_outlined,
            title: 'Sportolóim',
            onTap: () => context.push('/roster'),
          ),
          _MenuItem(
            icon: Icons.inbox_outlined,
            title: 'Csatlakozási kérések',
            onTap: () => context.push('/trainer-requests'),
          ),
          _MenuItem(
            icon: Icons.assignment_outlined,
            title: 'Felmérő szerkesztő',
            onTap: () => context.push('/onboarding/form-builder'),
          ),
          _MenuItem(
            icon: Icons.bar_chart,
            title: 'Felmérő válaszok',
            onTap: () => context.push('/onboarding/responses'),
          ),
        ] else ...[
          _MenuItem(
            icon: Icons.send_outlined,
            title: 'Edzőhöz csatlakozás',
            onTap: () => context.push('/trainer-requests'),
          ),
          _MenuItem(
            icon: Icons.quiz_outlined,
            title: 'Edzői felmérő',
            onTap: () => context.push('/onboarding/survey'),
          ),
        ],
        const SizedBox(height: DT.s4),
        _SectionHeader('Egyéb'),
        _MenuItem(
          icon: Icons.notifications_outlined,
          title: 'Értesítések',
          onTap: () => context.push('/notifications'),
        ),
        _DarkModeToggle(),
        _MenuItem(
          icon: Icons.delete_outline,
          title: 'Fiók törlése',
          iconColor: DT.cardRed,
          textColor: DT.cardRed,
          onTap: () => _confirmDeleteAccount(context),
        ),
      ],
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DT.of(context).bg,
        title: Text('Fiók törlése',
            style: TextStyle(color: DT.of(context).textPrimary)),
        content: Text(
          'Biztosan törlöd a fiókodat? Ez a művelet nem vonható vissza.',
          style: TextStyle(color: DT.of(context).textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mégse'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: DT.cardRed),
            child: const Text('Törlés'),
          ),
        ],
      ),
    );
  }
}

// ── Dark mode toggle ────────────────────────────────────────────────────────

class _DarkModeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) {
        final isDark = mode == ThemeMode.dark;
        return InkWell(
          onTap: () => context.read<ThemeCubit>().toggle(),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: DT.s3),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: DT.of(context).borderLight, width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: DT.of(context).iconLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: DT.of(context).iconLight,
                    size: 18,
                  ),
                ),
                const SizedBox(width: DT.s3),
                Expanded(
                  child: Text(
                    isDark ? 'Sötét mód' : 'Világos mód',
                    style: TextStyle(
                      fontSize: DT.s3,
                      fontWeight: FontWeight.w500,
                      color: DT.of(context).textPrimary,
                    ),
                  ),
                ),
                Switch(
                  value: isDark,
                  onChanged: (_) => context.read<ThemeCubit>().toggle(),
                  activeColor: DT.metricBlue,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DT.s2),
      child: Text(
        label,
        style: TextStyle(
            color: DT.of(context).textSecondary,
            fontSize: DT.s3,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color iconColor;
  final Color textColor;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor = DT.iconLight,
    this.textColor = DT.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: DT.s3),
        decoration: BoxDecoration(
          border:
              Border(bottom: BorderSide(color: DT.of(context).borderLight, width: 1)),
        ),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: DT.s3),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: DT.s3,
                      fontWeight: FontWeight.w500,
                      color: textColor)),
            ),
            Icon(Icons.arrow_forward_ios,
                color: DT.of(context).textGrey, size: 14),
          ],
        ),
      ),
    );
  }
}

// ── Logout ─────────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirm(context),
        icon: const Icon(Icons.logout, color: DT.cardRed),
        label: const Text('Kijelentkezés',
            style: TextStyle(color: DT.cardRed)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: DT.cardRed),
          padding: const EdgeInsets.symmetric(vertical: DT.s3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DT.rCardSmall),
          ),
        ),
      ),
    );
  }

  void _confirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DT.of(context).bg,
        title: Text('Kijelentkezés',
            style: TextStyle(color: DT.of(context).textPrimary)),
        content: Text('Biztosan ki szeretnél jelentkezni?',
            style: TextStyle(color: DT.of(context).textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mégse'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            style: TextButton.styleFrom(foregroundColor: DT.cardRed),
            child: const Text('Kijelentkezés'),
          ),
        ],
      ),
    );
  }
}
