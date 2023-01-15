import 'dart:convert';
import 'dart:io';

import 'package:core/deck.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';

import 'button.dart';

@immutable
class OpenButton extends StatelessWidget {
  final void Function(Programme) onOpen;

  const OpenButton({super.key, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Button(
      onTap: () async {
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
            onOpen(Programme.fromJson(json));
          }
        }
      },
      child: const Icon(
        CupertinoIcons.folder_open,
        color: CupertinoColors.activeBlue,
      ),
    );
  }
}

@immutable
class SaveButton extends StatelessWidget {
  final Programme programme;

  const SaveButton({super.key, required this.programme});

  @override
  Widget build(BuildContext context) {
    return Button(
      onTap: () async {
        final path = await FilePicker.platform.saveFile(
          fileName: "programme.bcp",
          type: FileType.custom,
          allowedExtensions: ["bcp"],
        );
        if (path != null) {
          await File(path).writeAsString(jsonEncode(programme.toJson()));
        }
      },
      child: const Icon(
        CupertinoIcons.floppy_disk,
        color: CupertinoColors.activeBlue,
      ),
    );
  }
}
