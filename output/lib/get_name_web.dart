// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html';

String getName() => UrlSearchParams(window.location.search).get('name') ?? '';
String getHost() => window.location.host;
