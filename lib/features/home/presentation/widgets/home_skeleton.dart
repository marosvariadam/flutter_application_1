import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/shared/widgets/skeleton.dart';

/// Loading placeholder shaped like the athlete home: week strip, today's
/// workout card and the two shortcut cards.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(DT.s5),
      child: SkeletonPulse(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 120, height: 18),
            const SizedBox(height: DT.s3),
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 7,
                separatorBuilder: (_, _) => const SizedBox(width: DT.s3),
                itemBuilder: (_, _) => const SkeletonBox(
                    width: 48, height: 76, radius: DT.rCardSmall),
              ),
            ),
            const SizedBox(height: DT.s5),
            const SkeletonBox(width: 140, height: 18),
            const SizedBox(height: DT.s3),
            const SkeletonBox(height: 160, radius: DT.rCardSmall),
            const SizedBox(height: DT.s5),
            const SkeletonBox(width: 110, height: 18),
            const SizedBox(height: DT.s3),
            const SkeletonBox(height: 84, radius: DT.rCardSmall),
            const SizedBox(height: DT.s3),
            const SkeletonBox(height: 84, radius: DT.rCardSmall),
          ],
        ),
      ),
    );
  }
}
