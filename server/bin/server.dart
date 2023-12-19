import 'dart:io';

import 'package:path/path.dart';
import 'package:shelf_static/shelf_static.dart';

import 'package:core/server.dart';

void main(List<String> args) {
  final outputHandler = createStaticHandler(
    join(dirname(Platform.resolvedExecutable), 'output'),
    defaultDocument: 'index.html',
  );
  runServer(outputHandler);
}
