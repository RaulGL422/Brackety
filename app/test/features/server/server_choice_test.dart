import 'package:brackety/features/server/data/server_choice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseServerUrl', () {
    test(
      'keeps http and https URLs with a host, without the trailing slash',
      () {
        expect(
          parseServerUrl(' https://api.example.com/ '),
          'https://api.example.com',
        );
        expect(parseServerUrl('http://10.0.0.5:8080'), 'http://10.0.0.5:8080');
        expect(
          parseServerUrl('https://example.com/brackety//'),
          'https://example.com/brackety',
        );
      },
    );

    test('rejects other schemes, missing hosts and garbage', () {
      for (final input in [
        '',
        'api.example.com',
        'ftp://example.com',
        'http://',
        'https:///path',
        'http://exa mple.com',
        'https://example.com?x=1',
        'https://example.com#top',
      ]) {
        expect(parseServerUrl(input), isNull, reason: input);
      }
    });
  });

  test('the known URLs map to their option, anything else is other', () {
    expect(optionOf(hallServerUrl), ServerOption.hall);
    expect(optionOf(internetServerUrl), ServerOption.internet);
    expect(optionOf('http://localhost:8080'), ServerOption.other);
  });

  test('plain http is only allowed to the hall laptop', () {
    expect(isBlockedCleartext(hallServerUrl), isFalse);
    expect(isBlockedCleartext('http://192.168.137.1:9000'), isFalse);
    expect(isBlockedCleartext(internetServerUrl), isFalse);
    expect(isBlockedCleartext('http://192.168.1.50:8080'), isTrue);
    expect(isBlockedCleartext('not a url'), isFalse);
  });
}
