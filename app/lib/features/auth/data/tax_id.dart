const _cifFirstLetters = 'ABCDEFGHJNPQRSUVW';
const _cifControlLetters = 'JABCDEFGHI';
const _cifLetterControl = 'PQRSNW';
const _cifDigitControl = 'ABEH';

/// Uppercase, without the spaces, hyphens and dots people type in a CIF.
String normalizeTaxId(String value) =>
    value.toUpperCase().replaceAll(RegExp(r'[\s.\-]'), '');

/// Spanish CIF check, the same algorithm as the server; [value] is normalized first.
bool isValidCif(String value) {
  final cif = normalizeTaxId(value);
  if (!RegExp(r'^[A-Z]\d{7}[0-9A-Z]$').hasMatch(cif)) return false;
  final first = cif[0];
  if (!_cifFirstLetters.contains(first)) return false;

  var sum = 0;
  for (var i = 0; i < 7; i++) {
    final digit = int.parse(cif[i + 1]);
    if (i.isOdd) {
      sum += digit;
    } else {
      final doubled = digit * 2;
      sum += doubled ~/ 10 + doubled % 10;
    }
  }
  final controlDigit = (10 - sum % 10) % 10;
  final controlLetter = _cifControlLetters[controlDigit];

  final control = cif[8];
  final matchesDigit = control == '$controlDigit';
  final matchesLetter = control == controlLetter;
  if (_cifLetterControl.contains(first)) return matchesLetter;
  if (_cifDigitControl.contains(first)) return matchesDigit;
  return matchesDigit || matchesLetter;
}
