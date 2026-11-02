import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('window size thresholds follow Material 3', () {
    expect(WindowSize.fromWidth(0), WindowSize.compact);
    expect(WindowSize.fromWidth(599), WindowSize.compact);
    expect(WindowSize.fromWidth(600), WindowSize.medium);
    expect(WindowSize.fromWidth(839), WindowSize.medium);
    expect(WindowSize.fromWidth(840), WindowSize.expanded);
  });

  Future<void> pumpAt(
    WidgetTester tester,
    Size size, {
    ValueChanged<int>? onSelected,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: AdaptiveScaffold(
          title: 'Brackety',
          destinations: const [
            AdaptiveDestination(icon: Icons.home, label: 'Home'),
            AdaptiveDestination(icon: Icons.dns, label: 'Server'),
          ],
          selectedIndex: 0,
          onSelected: onSelected ?? (_) {},
          body: const Text('body'),
        ),
      ),
    );
  }

  testWidgets('phone bar hides labels that would wrap', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: AdaptiveScaffold(
          title: 'Brackety',
          // The test font draws every glyph one font size wide: 13 × 12 px > 360 / 3.
          destinations: const [
            AdaptiveDestination(icon: Icons.home, label: 'Home'),
            AdaptiveDestination(icon: Icons.group, label: 'Organizadores'),
            AdaptiveDestination(icon: Icons.dns, label: 'Server'),
          ],
          selectedIndex: 0,
          onSelected: (_) {},
          body: const Text('body'),
        ),
      ),
    );

    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).labelBehavior,
      NavigationDestinationLabelBehavior.alwaysHide,
    );
    expect(find.byTooltip('Organizadores'), findsOneWidget);
  });

  testWidgets('phone uses a bottom navigation bar', (tester) async {
    await pumpAt(tester, const Size(360, 800));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).labelBehavior,
      NavigationDestinationLabelBehavior.alwaysShow,
    );
  });

  testWidgets('tablet uses a navigation rail with labels', (tester) async {
    await pumpAt(tester, const Size(800, 1280));

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
    expect(rail.labelType, NavigationRailLabelType.all);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('desktop uses an extended rail', (tester) async {
    await pumpAt(tester, const Size(1440, 900));

    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isTrue,
    );
  });

  testWidgets('desktop content never grows past the reading width', (
    tester,
  ) async {
    await pumpAt(tester, const Size(2560, 1440));

    expect(
      tester.getSize(find.text('body')).width,
      lessThanOrEqualTo(AdaptiveScaffold.maxContentWidth),
    );
  });

  testWidgets('selecting a destination reports its index', (tester) async {
    int? selected;
    await pumpAt(tester, const Size(360, 800), onSelected: (i) => selected = i);

    await tester.tap(find.text('Server'));

    expect(selected, 1);
  });

  testWidgets('shell router redirects to routes outside the shell', (
    tester,
  ) async {
    final signedIn = ValueNotifier(false);
    addTearDown(signedIn.dispose);
    final router = adaptiveShellRouter(
      title: (_) => 'Brackety',
      tabs: [
        AdaptiveTab(
          path: '/',
          icon: Icons.home,
          label: (_) => 'Home',
          builder: (_) => const Text('home body'),
        ),
      ],
      routes: [GoRoute(path: '/login', builder: (_, _) => const Text('login'))],
      refreshListenable: signedIn,
      redirect: (_, state) => signedIn.value
          ? (state.matchedLocation == '/login' ? '/' : null)
          : (state.matchedLocation == '/login' ? null : '/login'),
      actions: (_) => [const Icon(Icons.logout)],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    signedIn.value = true;
    await tester.pumpAndSettle();

    expect(find.text('home body'), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);
  });
}
