import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_application_1/features/auth/bloc/auth_bloc.dart';
import 'package:flutter_application_1/features/exercise/data/models/exercise_model.dart';
import 'package:flutter_application_1/features/exercise/data/repositories/exercise_repository.dart';
import 'package:flutter_application_1/features/exercise/presentation/exercise_catalogue_page.dart';
import 'package:flutter_application_1/features/exercise/presentation/widgets/exercise_picker.dart';

import 'fake_exercise_repository.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

Future<void> _pumpCatalogue(
    WidgetTester tester, List<ExerciseModel> exercises) async {
  final auth = _MockAuthBloc();
  when(() => auth.state).thenReturn(AuthUnauthenticated());

  await tester.pumpWidget(MaterialApp(
    home: RepositoryProvider<ExerciseRepository>.value(
      value: FakeExerciseRepository(exercises),
      child: BlocProvider<AuthBloc>.value(
        value: auth,
        child: const ExerciseCataloguePage(),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('catalogue tiles show pattern and compound chips',
      (tester) async {
    await _pumpCatalogue(tester, typedExercises);

    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Vízsz. tolás'), findsNWidgets(2));
    expect(find.text('Izoláció'), findsOneWidget);
    expect(find.text(ExerciseMetaChip.compoundLabel), findsNWidgets(2));
    expect(find.byType(ExerciseMetaChip), findsNWidgets(5));
  });

  testWidgets('custom badge and chips render side by side', (tester) async {
    await _pumpCatalogue(tester, const [
      ExerciseModel(
        id: 'c1',
        name: 'Egykezes evezés',
        muscleGroup: 'Hátizom',
        equipmentTypes: ['Dumbbell'],
        movementPattern: 'HorizontalPull',
        isCompound: true,
        createdByTrainerId: 't1',
      ),
    ]);

    expect(find.text('Egyéni'), findsOneWidget);
    expect(find.text('Vízsz. húzás'), findsOneWidget);
    expect(find.text(ExerciseMetaChip.compoundLabel), findsOneWidget);
  });

  testWidgets('legacy exercises render without chips', (tester) async {
    await _pumpCatalogue(tester, legacyExercises);

    expect(find.text('Fekvenyomás'), findsOneWidget);
    expect(find.text('Egyéni'), findsOneWidget);
    expect(find.byType(ExerciseMetaChip), findsNothing);
  });
}
