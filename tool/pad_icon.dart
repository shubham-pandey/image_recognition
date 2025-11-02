import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Pads an input icon into a 1024x1024 canvas with transparent background,
/// scaling it to roughly 66% of the canvas to fit adaptive icon safe zone.
///
/// Usage: dart run tool/pad_icon.dart assets/icon.png assets/icon_foreground.png
Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln('Usage: dart run tool/pad_icon.dart <input> <output>');
    exit(64);
  }
  final inputPath = args[0];
  final outputPath = args[1];

  if (!File(inputPath).existsSync()) {
    stderr.writeln('Input file not found: $inputPath');
    exit(66);
  }

  final bytes = await File(inputPath).readAsBytes();
  final src = img.decodeImage(bytes);
  if (src == null) {
    stderr.writeln('Unsupported image format: $inputPath');
    exit(65);
  }

  const canvasSize = 1024;
  const scaleRatio = 0.66; // target inner size ~ 66%
  final targetSize = (canvasSize * scaleRatio).round();

  // Scale the longest side to targetSize, preserving aspect ratio
  img.Image resized;
  if (src.width >= src.height) {
    resized = img.copyResize(src, width: targetSize);
  } else {
    resized = img.copyResize(src, height: targetSize);
  }

  // Create transparent canvas and center the resized icon
  final canvas = img.Image(width: canvasSize, height: canvasSize);
  // PNGs support alpha; ensure canvas is transparent
  img.fill(canvas, color: img.ColorUint8.rgba(0, 0, 0, 0));

  final x = ((canvasSize - resized.width) / 2).round();
  final y = ((canvasSize - resized.height) / 2).round();
  img.compositeImage(canvas, resized, dstX: x, dstY: y);

  final outBytes = Uint8List.fromList(img.encodePng(canvas));
  await File(outputPath).create(recursive: true);
  await File(outputPath).writeAsBytes(outBytes);
  stdout.writeln('Wrote padded icon to: $outputPath');
}
