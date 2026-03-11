import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Utility functions for copying and exporting lyrics.
class ExportHelper {
  /// Copy text to the system clipboard.
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Share text content as a .txt file.
  static Future<void> shareAsFile(String content, String filename) async {
    final dir = await getTemporaryDirectory();
    // Add UTF-8 BOM for compatibility
    const bom = '\uFEFF';
    final file = File('${dir.path}/$filename');
    await file.writeAsString(
      bom + content,
      encoding: utf8,
    );
    await Share.shareXFiles([XFile(file.path)], text: 'Lyrics from LyricLearn');
  }

  /// Share plain text.
  static Future<void> shareText(String text) async {
    await Share.share(text);
  }
}
