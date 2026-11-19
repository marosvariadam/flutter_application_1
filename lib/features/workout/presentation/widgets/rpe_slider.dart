import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/design/dt_text.dart';

/// Optional 0-10 Rate of Perceived Exertion control. Renders below the set
/// rows of an exercise. Submitting without setting RPE works (the backend
/// accepts null); tapping the "RPE n" chip clears it.
class RpeSlider extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;

  const RpeSlider({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    final t = DTText.of(context);
    final v = value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(DT.s4, DT.s2, DT.s4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('RPE (optional)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.caption.copyWith(fontWeight: FontWeight.w600)),
              ),
              if (v != null)
                Tooltip(
                  message: 'RPE törlése',
                  child: Semantics(
                    button: true,
                    label: 'RPE $v, törlés',
                    onTap: () => onChanged(null),
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: () => onChanged(null),
                      borderRadius: BorderRadius.circular(DT.rChip),
                      child: Container(
                        constraints:
                            const BoxConstraints(minHeight: 32, minWidth: 44),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                            horizontal: DT.s2, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.accentPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(DT.rChip),
                        ),
                        child: Text(
                          'RPE $v',
                          style: t.caption.copyWith(
                              color: c.accentPrimary,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Text('—', style: t.caption),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: c.accentPrimary,
              inactiveTrackColor: c.accentPrimary.withValues(alpha: 0.15),
              thumbColor: c.accentPrimary,
              overlayColor: c.accentPrimary.withValues(alpha: 0.1),
            ),
            child: Slider(
              min: 0,
              max: 10,
              divisions: 10,
              value: (v ?? 0).toDouble(),
              label: '${v ?? 0}',
              semanticFormatterCallback: (raw) => 'RPE ${raw.round()}',
              onChanged: (raw) => onChanged(raw.round()),
            ),
          ),
        ],
      ),
    );
  }
}
