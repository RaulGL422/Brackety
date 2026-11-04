import 'package:brackety_core/brackety_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final page = Uri.parse('http://192.168.137.1:8080/club/events?tab=2');

  test('same-origin on web is the origin of the page', () {
    expect(
      resolveApiBaseUrl(sameOriginApiBaseUrl, isWeb: true, pageUrl: page),
      'http://192.168.137.1:8080',
    );
  });

  test('same-origin outside the web is not configured', () {
    expect(
      resolveApiBaseUrl(sameOriginApiBaseUrl, isWeb: false, pageUrl: page),
      isEmpty,
    );
  });

  test('a real url is kept as it is', () {
    expect(
      resolveApiBaseUrl('https://api.example.test', isWeb: true, pageUrl: page),
      'https://api.example.test',
    );
  });
}
