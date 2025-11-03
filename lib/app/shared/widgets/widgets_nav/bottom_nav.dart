import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:go_router/go_router.dart';

class BottomNavScaffold extends StatelessWidget {
  final StatefulNavigationShell shell;
  const BottomNavScaffold({super.key, required this.shell});

  void _onTap(int index) => shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: Container(
        height: 90,
        decoration: BoxDecoration(
          color: DT.bg
        ),
        child: Container(
          decoration: BoxDecoration(
          color: DT.bottomNavBG,
          borderRadius: BorderRadius.circular(20)
        ),
        margin: EdgeInsets.only(bottom: DT.s8, top: DT.s2, left: DT.s6, right: DT.s6),
        padding: EdgeInsets.symmetric(vertical: DT.s2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _navItem(
              icon: Icons.home_outlined,
              isSelected: shell.currentIndex == 0,
              onTap: () => _onTap(0)
            ),
            _navItem(
              icon: Icons.fitness_center_outlined,
              isSelected: shell.currentIndex == 1,
              onTap: () => _onTap(1)
            ),
            _navItem(
              icon: Icons.person_outlined,
              isSelected: shell.currentIndex == 2,
              onTap: () => _onTap(2)  
            )
          ],
        ),
      )
      )
    );
  }
}


class _navItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _navItem({required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isSelected ? DT.bg : Colors.transparent,
            shape: BoxShape.circle
          ),
          child: Icon(
            icon, 
            color: isSelected ? DT.gbBlack : DT.bg,
            size: DT.s6,
        )
        ),
    );
  }
}