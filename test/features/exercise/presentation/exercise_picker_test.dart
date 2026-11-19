import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/exercise/data/models/exercise_model.dart';
import 'package:flutter_application_1/features/exercise/presentation/widgets/exercise_picker.dart';

import 'fake_exercise_repository.dart';

Future<void> _pumpPicker(
  WidgetTester tester,
  List<ExerciseModel> exercises, {
  ValueChanged<ExerciseModel>? onSelect,
}) async {
  final scroll = ScrollController();
  addTearDown(scroll.dispose);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: ExercisePicker(
        exerciseRepo: FakeExerciseRepository(exercises),
        athleteId: null,
        scrollController: scroll,
        onSelect: onSelect ?? (_) {},
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('equipment filter', () {
    testWidgets('stays hidden when exercises carry no typed equipment',
        (tester) async {
      await _pumpPicker(tester, legacyExercises);

      expect(find.text('Fekvenyomás'), findsOneWidget);
      expect(find.text('Saját gyakorlat'), findsOneWidget);
      expect(find.text('Kézisúlyok'), findsNothing);
      expect(find.text('Rúd + tárcsák'), findsNothing);
    });

    testWidgets('lists every exercise while no equipment is chosen',
        (tester) async {
      await _pumpPicker(tester, typedExercises);

      expect(find.text('Rúd + tárcsák'), findsOneWidget);
      expect(find.text('Kézisúlyok'), findsOneWidget);
      expect(find.byType(ExercisePickerTile), findsNWidgets(3));
    });

    testWidgets('tapping a chip filters the list and tapping again clears it',
        (tester) async {
      await _pumpPicker(tester, typedExercises);

      await tester.tap(find.text('Kézisúlyok'));
      await tester.pumpAndSettle();

      expect(find.byType(ExercisePickerTile), findsOneWidget);
      expect(find.text('Dumbbell Fly'), findsOneWidget);
      expect(find.text('Bench Press'), findsNothing);

      await tester.tap(find.text('Kézisúlyok'));
      await tester.pumpAndSettle();

      expect(find.byType(ExercisePickerTile), findsNWidgets(3));
    });

    testWidgets('keeps the chip row when the filter matches nothing',
        (tester) async {
      await _pumpPicker(tester, typedExercises);

      await tester.tap(find.text('Kábel'));
      await tester.pumpAndSettle();

      expect(find.text('Nem található.'), findsOneWidget);
      expect(find.text('Kábel'), findsOneWidget);

      await tester.tap(find.text('Kábel'));
      await tester.pumpAndSettle();

      expect(find.byType(ExercisePickerTile), findsNWidgets(3));
    });

    testWidgets('selecting from a filtered list returns that exercise',
        (tester) async {
      ExerciseModel? picked;
      await _pumpPicker(tester, typedExercises, onSelect: (e) => picked = e);

      await tester.tap(find.text('Saját testsúly'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Push-up'));

      expect(picked?.id, 'pushup');
    });
  });

  testWidgets('picker tiles show pattern and compound chips', (tester) async {
    await _pumpPicker(tester, typedExercises);

    Finder inTiles(String text) => find.descendant(
        of: find.byType(ExercisePickerTile), matching: find.text(text));

    expect(inTiles('Vízsz. tolás'), findsNWidgets(2));
    expect(inTiles('Izoláció'), findsOneWidget);
    expect(inTiles(ExerciseMetaChip.compoundLabel), findsNWidgets(2));
  });
}
