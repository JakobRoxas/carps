import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the real bundled fonts so widget tests measure text like the app
/// does (the default test font draws every glyph as a wide square, which
/// makes layout-overflow checks meaningless).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File('assets/fonts/$f').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  await load('Inter', [
    'Inter-Regular.ttf',
    'Inter-Medium.ttf',
    'Inter-SemiBold.ttf',
    'Inter-Bold.ttf',
  ]);
  await load('OtomanopeeOne', ['OtomanopeeOne-Regular.ttf']);
  // Material icons, so screenshots show real glyphs instead of boxes.
  final root = Platform.environment['FLUTTER_ROOT'];
  final icons = File(
      '${root ?? ''}/bin/cache/artifacts/material_fonts/materialicons-regular.otf');
  if (root != null && icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
  await testMain();
}
