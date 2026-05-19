import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/user_session.dart';
import 'package:go_router/go_router.dart';

class BottomNavScaffold extends StatelessWidget {
  final StatefulNavigationShell shell;
  const BottomNavScaffold({super.key, required this.shell});

  void _onTap(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final isCoach = UserSession.instance.isCoach;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final dt = DT.of(context);
    return Scaffold(
      body: shell,
      bottomNavigationBar: Container(
        color: dt.bg,
        padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : DT.s2),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: dt.bottomNavBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: dt.shadowMedium,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          margin: const EdgeInsets.only(
            bottom: DT.s2,
            top: DT.s2,
            left: DT.s6,
            right: DT.s6,
          ),
          padding: const EdgeInsets.symmetric(horizontal: DT.s4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: isCoach ? 'Áttekintés' : 'Kezdőlap',
                isSelected: shell.currentIndex == 0,
                onTap: () => _onTap(0),
              ),
              _NavItem(
                icon: isCoach ? Icons.people_outline : Icons.fitness_center_outlined,
                label: isCoach ? 'Atlétáim' : 'Edzés',
                isSelected: shell.currentIndex == 1,
                onTap: () => _onTap(1),
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline,
                label: 'Üzenetek',
                isSelected: shell.currentIndex == 2,
                onTap: () => _onTap(2),
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Profil',
                isSelected: shell.currentIndex == 3,
                onTap: () => _onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dt = DT.of(context);
    final iconColor =
        isSelected ? dt.bottomNavSelectedIcon : dt.bottomNavUnselected;
    final labelColor =
        isSelected ? dt.bottomNavSelectedLabel : dt.bottomNavUnselected;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DT.rCard),
      splashColor: dt.textOnAccent.withValues(alpha: 0.1),
      highlightColor: dt.textOnAccent.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DT.s4, vertical: DT.s1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color:
                    isSelected ? dt.bottomNavSelectedBg : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: DT.s5),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                color: labelColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
