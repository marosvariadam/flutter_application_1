import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/design/dt_text.dart';
import 'package:flutter_application_1/app/shared/widgets/user_avatar.dart';
import 'package:flutter_application_1/app/user_session.dart';
import 'package:flutter_application_1/app/shared/greeting.dart';

/// App-bar content of the athlete home: the user's avatar (opens the
/// profile) and a time-of-day greeting with today's date.
class HomeHeader extends StatelessWidget {
  /// Injectable clock for tests.
  final DateTime Function() now;

  const HomeHeader({super.key, this.now = DateTime.now});

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    final t = DTText.of(context);
    final session = UserSession.instance;
    final time = now();
    final firstName = session.firstName?.trim() ?? '';
    final name = session.displayName;
    return Row(
      children: [
        Tooltip(
          message: 'Profil',
          child: Semantics(
            button: true,
            label: 'Profil',
            onTap: () => context.go('/profile'),
            excludeSemantics: true,
            child: InkResponse(
              onTap: () => context.go('/profile'),
              radius: 28,
              child: Container(
                margin: const EdgeInsets.only(right: DT.s3),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.cardSurface,
                  boxShadow: DT.shadowCard(context),
                ),
                child: UserAvatar(name: name, size: 44),
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                firstName.isEmpty
                    ? '${timeOfDayGreeting(time)}!'
                    : '${timeOfDayGreeting(time)}, $firstName!',
                style: t.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                DateFormat('yyyy.MM.dd').format(time),
                style: t.caption,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
