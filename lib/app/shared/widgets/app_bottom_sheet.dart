import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/design/dt_text.dart';

/// The drag handle at the top of every bottom sheet.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: DT.s3),
          decoration: BoxDecoration(
            color: DT.of(context).borderGrey,
            borderRadius: BorderRadius.circular(DT.rPill),
          ),
        ),
      );
}

/// Standard bottom-sheet body: handle, optional h2 title, then [child].
/// Lifts above the keyboard. Open it with [AppBottomSheet.show].
class AppBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AppBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(DT.s5, DT.s3, DT.s5, DT.s5),
  });

  /// Shows [builder]'s content in an [AppBottomSheet] with the app's sheet
  /// surface and top corners.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    String? title,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: DT.of(context).cardSurfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DT.rCard)),
      ),
      builder: (sheetContext) =>
          AppBottomSheet(title: title, child: builder(sheetContext)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(DT.s5, DT.s4, DT.s5, 0),
                child: Text(title!, style: DTText.of(context).h2),
              ),
            Flexible(child: Padding(padding: padding, child: child)),
          ],
        ),
      ),
    );
  }
}
