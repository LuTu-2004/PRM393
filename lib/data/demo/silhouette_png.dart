import 'dart:io' show ZLibCodec;
import 'dart:typed_data';

/// Generates a fake ID photo (a neutral silhouette on a pastel background)
/// as PNG bytes. Used for tests and sample data only, so no real
/// faces ever enter the repository.
Uint8List silhouettePng(int seed, {int width = 240, int height = 320}) {
  const backgrounds = [
    [0xDD, 0xE6, 0xF7],
    [0xE3, 0xEE, 0xE4],
    [0xF3, 0xE6, 0xDA],
    [0xE8, 0xE2, 0xF4],
    [0xF1, 0xE3, 0xE8],
    [0xE0, 0xEC, 0xEF],
  ];
  const shirts = [
    [0x3B, 0x4A, 0x6B],
    [0xF4, 0xF5, 0xF8],
    [0x2F, 0x5D, 0x8A],
    [0x55, 0x55, 0x60],
  ];
  const skins = [
    [0xE9, 0xC4, 0xA6],
    [0xD9, 0xAE, 0x8C],
    [0xF1, 0xD0, 0xB5],
    [0xC9, 0x9A, 0x77],
  ];
  const hairs = [
    [0x1C, 0x19, 0x18],
    [0x2E, 0x22, 0x1C],
    [0x3A, 0x2A, 0x20],
  ];

  final bg = backgrounds[seed % backgrounds.length];
  final shirt = shirts[(seed ~/ 2) % shirts.length];
  final skin = skins[(seed ~/ 3) % skins.length];
  final hair = hairs[(seed ~/ 5) % hairs.length];
  final longHair = seed % 3 == 0;

  final cx = width / 2;
  final headCy = height * 0.40;
  final headRx = width * 0.19;
  final headRy = height * 0.155;

  final raw = BytesBuilder();
  for (var y = 0; y < height; y++) {
    raw.addByte(0); // PNG filter type: none
    for (var x = 0; x < width; x++) {
      var color = bg;
      // Shoulders: a wide ellipse at the bottom.
      final sx = (x - cx) / (width * 0.46);
      final sy = (y - height * 1.02) / (height * 0.36);
      final inShoulders = sx * sx + sy * sy <= 1;
      // Neck.
      final inNeck =
          (x - cx).abs() < width * 0.075 &&
          y > headCy + headRy * 0.6 &&
          y < height * 0.72;
      // Head.
      final hx = (x - cx) / headRx;
      final hy = (y - headCy) / headRy;
      final inHead = hx * hx + hy * hy <= 1;
      // Hair: slightly larger ellipse, only above the forehead (or long).
      final gx = (x - cx) / (headRx * 1.12);
      final gy = (y - (headCy - headRy * 0.12)) / (headRy * 1.08);
      final inHairShape = gx * gx + gy * gy <= 1;
      final hairLimit = longHair
          ? headCy + headRy * 1.1
          : headCy - headRy * 0.25;
      final inHair =
          inHairShape &&
          (y < hairLimit) &&
          !(inHead && y > headCy - headRy * 0.25);

      if (inShoulders) color = shirt;
      if (inNeck) color = skin;
      if (inHair && !inHead) color = hair;
      if (inHead) color = skin;
      if (inHair && y < headCy - headRy * 0.25) color = hair;
      raw.add(color);
    }
  }

  final png = BytesBuilder()
    ..add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  final ihdr = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, 2) // color type: RGB
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  _chunk(png, 'IHDR', ihdr.buffer.asUint8List());
  _chunk(png, 'IDAT', Uint8List.fromList(ZLibCodec().encode(raw.takeBytes())));
  _chunk(png, 'IEND', Uint8List(0));
  return png.takeBytes();
}

void _chunk(BytesBuilder out, String type, Uint8List data) {
  final typeBytes = type.codeUnits;
  final len = ByteData(4)..setUint32(0, data.length);
  out.add(len.buffer.asUint8List());
  out.add(typeBytes);
  out.add(data);
  final crc = ByteData(4)..setUint32(0, _crc32([...typeBytes, ...data]));
  out.add(crc.buffer.asUint8List());
}

final List<int> _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}
