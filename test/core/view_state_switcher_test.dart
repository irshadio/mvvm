import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/core/presentation/view_state_switcher.dart';
import 'package:mvvm/core/state/view_state.dart';

void main() {
  Widget host(ViewState<int> state) => MaterialApp(
    home: Scaffold(
      body: ViewStateSwitcher<int>(
        state: state,
        onData: (value) => Text('value $value'),
      ),
    ),
  );

  testWidgets('data renders onData', (tester) async {
    await tester.pumpWidget(host(const ViewState<int>.data(7)));
    expect(find.text('value 7'), findsOneWidget);
  });

  testWidgets('loading renders the default loading view', (tester) async {
    await tester.pumpWidget(host(const ViewState<int>.loading()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('error renders the failure message', (tester) async {
    await tester.pumpWidget(
      host(const ViewState<int>.error(Failure.unexpected(message: 'boom'))),
    );
    expect(find.text('boom'), findsOneWidget);
  });

  testWidgets('noInternet renders the offline view', (tester) async {
    await tester.pumpWidget(host(const ViewState<int>.noInternet()));
    expect(find.text('No internet connection'), findsOneWidget);
  });

  testWidgets('loading with previous keeps data visible (no spinner)', (
    tester,
  ) async {
    await tester.pumpWidget(host(const ViewState<int>.loading(previous: 7)));
    expect(find.text('value 7'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('error with previous keeps data visible (no error view)', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const ViewState<int>.error(
          Failure.unexpected(message: 'boom'),
          previous: 7,
        ),
      ),
    );
    expect(find.text('value 7'), findsOneWidget);
    expect(find.text('boom'), findsNothing);
  });
}
