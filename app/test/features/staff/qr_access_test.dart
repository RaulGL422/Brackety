import 'package:brackety/features/staff/data/staff_repository.dart';
import 'package:brackety/features/staff/data/temporary_access.dart';
import 'package:brackety/features/staff/ui/qr_access.dart';
import 'package:brackety/features/staff/ui/qr_access_section.dart';
import 'package:brackety/l10n/gen/app_localizations.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// QR accesses without a server: [signedIn] is what the list answers after the code is created.
class _FakeAccesses extends Fake implements TemporaryAccessRepository {
  final created = <(String, StaffRole, int?)>[];
  var signedIn = false;

  TemporaryAccess _access(String name, {String? link, String? password}) =>
      TemporaryAccess(
        id: 'a1',
        accountId: 'acc1',
        name: name,
        role: StaffRole.referee,
        mat: 2,
        waiting: !signedIn,
        ended: false,
        signedInAt: signedIn ? DateTime.utc(2027, 5, 8, 9, 30) : null,
        link: link,
        signIn: 'qr-k3f9a2',
        password: password,
      );

  @override
  Future<TemporaryAccess> create(
    String eventId, {
    required String name,
    required StaffRole role,
    int? mat,
  }) async {
    created.add((name, role, mat));
    return _access(
      name,
      link: 'https://brackety.example/qr?code=abc',
      password: 'mn4pq7rs',
    );
  }

  @override
  Future<List<TemporaryAccess>> list(String eventId) async =>
      created.isEmpty ? [] : [_access(created.last.$1)];
}

void main() {
  const sizes = {
    'phone': Size(360, 800),
    'tablet': Size(800, 1280),
    'desktop': Size(1440, 900),
  };

  Future<_FakeAccesses> open(
    WidgetTester tester,
    Size size,
    Widget child,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final accesses = _FakeAccesses();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          temporaryAccessRepositoryProvider.overrideWithValue(accesses),
        ],
        child: MaterialApp(
          builder: (_, child) => ToastHost(child: child!),
          theme: lightTheme(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...coreLocalizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return accesses;
  }

  for (final MapEntry(key: device, value: size) in sizes.entries) {
    testWidgets(
      'the club shows the QR with sign-in and password and hears when they are in on $device',
      (tester) async {
        final accesses = await open(
          tester,
          size,
          const QrAccessButton(eventId: 'e1', role: StaffRole.referee, mat: 2),
        );

        await tester.tap(find.byIcon(Icons.qr_code_2));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField), ' Juan Pérez ');
        await tester.tap(find.text('Create QR'));
        // The waiting spinner never settles: pump the dialog in.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(accesses.created.single, ('Juan Pérez', StaffRole.referee, 2));
        expect(find.byType(QrImageView), findsOneWidget);
        expect(find.text('Waiting for them to sign in…'), findsOneWidget);
        expect(find.text('qr-k3f9a2'), findsOneWidget);
        expect(find.text('mn4pq7rs'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Scanned: the next check confirms it; the password stays to write it down.
        accesses.signedIn = true;
        await tester.pump(const Duration(seconds: 3));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Juan Pérez is in.'), findsOneWidget);
        expect(find.text('mn4pq7rs'), findsOneWidget);
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(find.byType(QrImageView), findsNothing);
      },
    );
  }

  testWidgets('a QR for a mat with a referee says who leaves it', (
    tester,
  ) async {
    final accesses = await open(
      tester,
      sizes['phone']!,
      const QrAccessButton(
        eventId: 'e1',
        role: StaffRole.referee,
        mat: 2,
        replaces: 'Ana (arbitro1)',
      ),
    );
    await tester.tap(find.byIcon(Icons.qr_code_2));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Mat 2 has Ana (arbitro1). With a new QR, Ana (arbitro1) leaves the mat.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing);
    expect(accesses.created, isEmpty);

    await tester.tap(find.byIcon(Icons.qr_code_2));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Create QR'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('a name is needed before the QR', (tester) async {
    final accesses = await open(
      tester,
      sizes['phone']!,
      const QrAccessButton(eventId: 'e1', role: StaffRole.grouper),
    );
    await tester.tap(find.byIcon(Icons.qr_code_2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create QR'));
    await tester.pumpAndSettle();

    expect(find.text('Required.'), findsOneWidget);
    expect(accesses.created, isEmpty);
  });

  testWidgets('the section warns of mats without referee and no helper', (
    tester,
  ) async {
    await open(
      tester,
      sizes['phone']!,
      const SingleChildScrollView(
        child: QrAccessSection(
          eventId: 'e1',
          matReferees: [null, 'r2', null],
          hasGrouper: false,
        ),
      ),
    );

    expect(
      find.text('Mats without a referee: 1, 3. Use the QR next to each mat.'),
      findsOneWidget,
    );
    expect(find.text('Nobody but the club can create groups.'), findsOneWidget);
    expect(find.text('Helper by QR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('a full link stays as the server gave it', () {
    expect(
      qrLink('https://b.example/qr?code=x'),
      'https://b.example/qr?code=x',
    );
    expect(qrLink('/qr?code=x'), endsWith('/qr?code=x'));
  });
}
