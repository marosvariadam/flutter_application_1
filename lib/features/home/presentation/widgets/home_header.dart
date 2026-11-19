import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/design/dt_text.dart';
import 'package:flutter_application_1/app/user_session.dart';

/// App-bar content of the athlete home: profile avatar, greeting with
/// today's date, search button.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    final t = DTText.of(context);
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: Container(
            margin: const EdgeInsets.only(right: DT.s3),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c.bg, width: 2),
              boxShadow: DT.shadowCard(context),
            ),
            child: ClipOval(
              child: ColoredBox(
                color: c.accentPrimary.withValues(alpha: 0.15),
                child: Icon(Icons.person, color: c.accentPrimary),
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
                'Szia, ${UserSession.instance.firstName ?? ''}!',
                style: t.title,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                DateFormat('yyyy.MM.dd').format(DateTime.now()),
                style: t.caption,
              ),
            ],
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: c.cardSurface,
            borderRadius: BorderRadius.circular(DT.rCardSmall),
            boxShadow: DT.shadowCard(context),
          ),
          child: Icon(Icons.search, color: c.iconLight),
        ),
      ],
    );
  }
}
