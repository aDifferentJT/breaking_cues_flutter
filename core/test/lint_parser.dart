import 'package:petitparser/reflection.dart';
import 'package:test/test.dart';

import 'package:core/music.dart';

void main() {
  test('LintParser', () {
    expect(linter(Stave.parser), isEmpty);
  });
}
