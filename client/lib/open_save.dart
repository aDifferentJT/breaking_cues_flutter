import 'dart:convert';
import 'dart:io';

import 'package:core/deck.dart';
import 'package:file_picker/file_picker.dart';

Future<Programme?> open() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ["bcp"],
    withReadStream: true,
  );
  if (result != null && result.count >= 1) {
    final file = result.files.first;
    if (file.readStream != null) {
      final json = jsonDecode(
        await utf8.decodeStream(file.readStream!),
      );
      return Programme.fromJson(json);
    }
  }
  return null;
}

Future<void> save(Programme programme) async {
  final path = await FilePicker.platform.saveFile(
    fileName: "programme.bcp",
    type: FileType.custom,
    allowedExtensions: ["bcp"],
  );
  if (path != null) {
    await File(path).writeAsString(jsonEncode(programme.toJson()));
  }
}
