// Asset generator, run on demand (committed for reproducibility):
//
//   flutter test test/tools/generate_brand_assets_test.dart
//
// Renders the in-app KelasKu logo (green circle + menu_book icon, see
// lib/core/widgets/app_logo.dart) to high-res PNGs consumed by
// flutter_launcher_icons and flutter_native_splash:
//
//   assets/icon/app_icon.png            1024x1024 full logo (circle)
//   assets/icon/splash_logo.png         1024x1024 full logo (circle)
//   assets/icon/adaptive_foreground.png 1024x1024 white glyph only, sized
//     for the Android adaptive-icon safe zone (background color is set in
//     pubspec's adaptive_icon_background)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/core/constants/app_colors.dart';

const _canvasSize = 1024.0;

// Icon fonts are not loaded by default inside widget tests (glyphs render
// as boxes), so load MaterialIcons straight from the Flutter SDK cache.
Future<void> _loadMaterialIcons() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null || flutterRoot.isEmpty) {
    fail('FLUTTER_ROOT is not set; run via `flutter test`.');
  }
  final fontFile = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  final bytes = fontFile.readAsBytesSync();
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

Widget _logo1024() {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: Container(
        width: _canvasSize,
        height: _canvasSize,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.menu_book_rounded,
          size: _canvasSize * 0.5,
          color: Colors.white,
        ),
      ),
    ),
  );
}

// Glyph only, ~45% of the canvas: comfortably inside the 66% safe zone of
// Android adaptive icons (the launcher masks the outer area).
Widget _adaptiveForeground1024() {
  return const Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: Icon(
        Icons.menu_book_rounded,
        size: _canvasSize * 0.45,
        color: Colors.white,
      ),
    ),
  );
}

Future<void> _renderToFiles(
  WidgetTester tester,
  Widget widget,
  List<String> outputPaths,
) async {
  final key = GlobalKey();
  await tester.pumpWidget(RepaintBoundary(key: key, child: widget));
  await tester.pumpAndSettle();

  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  // Real async work (rasterization) must escape the fake-async test zone.
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    for (final path in outputPaths) {
      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(pngBytes);
    }

    expect(image.width, _canvasSize.toInt());
    expect(image.height, _canvasSize.toInt());
  });
}

void main() {
  testWidgets('generate launcher icon and splash logo PNGs', (tester) async {
    await _loadMaterialIcons();

    await tester.binding.setSurfaceSize(const Size(_canvasSize, _canvasSize));
    tester.view.physicalSize = const Size(_canvasSize, _canvasSize);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _renderToFiles(tester, _logo1024(), [
      'assets/icon/app_icon.png',
      'assets/icon/splash_logo.png',
    ]);
    await _renderToFiles(tester, _adaptiveForeground1024(), [
      'assets/icon/adaptive_foreground.png',
    ]);
  });
}
