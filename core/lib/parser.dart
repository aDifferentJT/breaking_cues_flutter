import 'package:petitparser/petitparser.dart';

extension ResultOptional<R> on Result<R> {
  R valueOr(R Function() fallback) => isSuccess ? value : fallback();
  R? get valueOrNull => isSuccess ? value : null;
}
