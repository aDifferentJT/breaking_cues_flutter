import 'package:petitparser/petitparser.dart';

extension ResultOptional<R> on Result<R> {
  R valueOr(R Function() fallback) => this is Success ? value : fallback();
  R? get valueOrNull => this is Success ? value : null;
}
