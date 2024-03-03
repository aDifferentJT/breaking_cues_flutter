import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

enum MediaTag { image }

@immutable
abstract class Media {
  factory Media.fromBytes(Uint8List bytes) {
    switch (MediaTag.values[bytes[0]]) {
      case MediaTag.image:
        return ImageMedia.fromBytes(bytes.sublist(1));
    }
  }

  Uint8List toBytes();
}

@immutable
class ImageMedia implements Media {
  final String name;
  final Uint8List data;

  ImageMedia({
    required this.name,
    required this.data,
  });

  ImageMedia.fromBytes(Uint8List bytes)
      : this.fromBytesHelper(
          bytes.sublist(8),
          ByteData.view(bytes.buffer).getInt64(0),
        );

  ImageMedia.fromBytesHelper(Uint8List bytes, int nameLength)
      : name = utf8.decode(bytes.sublist(0, nameLength)),
        data = bytes.sublist(nameLength);

  Uint8List toBytes() {
    final builder = BytesBuilder(copy: false);
    final nameEncoded = utf8.encode(name);
    final lengthData = ByteData(8);
    lengthData.setInt64(0, nameEncoded.length);
    builder.addByte(MediaTag.image.index);
    builder.add(lengthData.buffer.asUint8List());
    builder.add(nameEncoded);
    builder.add(data);
    return builder.takeBytes();
  }
}

@immutable
class MediaLibrary {
  final Map<UuidValue, Media> library = Map();

  MediaLibrary();

  void insert(Media media, {UuidValue? uuid}) {
    if (uuid == null) {
      uuid = Uuid().v4obj();
    }
    library[uuid] = media;
  }

  Media? operator [](UuidValue id) => library[id];
}
